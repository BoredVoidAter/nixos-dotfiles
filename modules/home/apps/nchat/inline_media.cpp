#include "inline_media.h"

#include <algorithm>
#include <atomic>
#include <cerrno>
#include <chrono>
#include <cmath>
#include <condition_variable>
#include <csignal>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <deque>
#include <fcntl.h>
#include <mutex>
#include <sys/wait.h>
#include <thread>
#include <unistd.h>
#include <unordered_map>
#include <unordered_set>

#include "fileutil.h"
#include "strutil.h"
#include "uiconfig.h"

namespace
{
  struct RenderJob
  {
    std::string key;
    std::string filePath;
    int maxCols = 0;
    int maxRows = 0;
    bool useKitty = false;
  };

  struct CachedVoice
  {
    bool analyzed = false;
    double durationSec = 0.0;
    std::wstring waveform;
  };

  struct AudioPlaybackState
  {
    bool playing = false;
    std::string filePath;
    double elapsedSec = 0.0;
  };

  bool RunProcessCapture(const std::vector<std::string>& p_Args, std::string& p_Out)
  {
    p_Out.clear();
    if (p_Args.empty()) return false;
    int pipeFds[2];
    if (pipe(pipeFds) != 0) return false;

    std::vector<std::string> mutableArgs = p_Args;
    std::vector<char*> argv;
    argv.reserve(mutableArgs.size() + 1);
    for (size_t i = 0; i < mutableArgs.size(); ++i)
    {
      argv.push_back(&mutableArgs[i][0]);
    }
    argv.push_back(nullptr);

    pid_t pid = fork();
    if (pid == 0)
    {
      close(pipeFds[0]);
      dup2(pipeFds[1], STDOUT_FILENO);
      close(pipeFds[1]);
      int devNull = open("/dev/null", O_RDWR);
      if (devNull >= 0)
      {
        dup2(devNull, STDIN_FILENO);
        dup2(devNull, STDERR_FILENO);
        if (devNull > 2) close(devNull);
      }
      execvp(argv[0], argv.data());
      _exit(127);
    }

    close(pipeFds[1]);
    if (pid < 0)
    {
      close(pipeFds[0]);
      return false;
    }

    char buf[4096];
    while (true)
    {
      ssize_t n = read(pipeFds[0], buf, sizeof(buf));
      if (n > 0) p_Out.append(buf, static_cast<size_t>(n));
      else if (n == 0) break;
      else if (errno != EINTR) break;
    }
    close(pipeFds[0]);

    int status = 0;
    while (waitpid(pid, &status, 0) < 0)
    {
      if (errno != EINTR) return false;
    }
    return WIFEXITED(status) && (WEXITSTATUS(status) == 0);
  }

  class ImageManager
  {
  public:
    static ImageManager& Instance()
    {
      static ImageManager instance;
      return instance;
    }

    bool LookupOrQueue(const std::string& p_FilePath, int p_MaxCols, int p_MaxRows,
                       bool p_UseKitty, InlineMedia::CachedImage& p_Out)
    {
      const std::string key = p_FilePath + "|" + std::to_string(p_MaxCols) + "x" +
        std::to_string(p_MaxRows) + "|" + (p_UseKitty ? "k" : "s");

      std::unique_lock<std::mutex> lock(m_Mutex);
      auto it = m_Cache.find(key);
      if (it != m_Cache.end())
      {
        p_Out = it->second;
        return true;
      }

      if (m_Queued.count(key) == 0)
      {
        StartLocked();
        m_Queued.insert(key);
        m_Queue.push_back(RenderJob{ key, p_FilePath, p_MaxCols, p_MaxRows, p_UseKitty });
        m_CondVar.notify_one();
      }

      return false;
    }

    bool TakeReady()
    {
      return m_Ready.exchange(false);
    }

    void Shutdown()
    {
      {
        std::unique_lock<std::mutex> lock(m_Mutex);
        if (!m_Running) return;

        m_Running = false;
        m_Queue.clear();
        m_Queued.clear();
        m_CondVar.notify_all();
      }

      if (m_Thread.joinable())
      {
        m_Thread.join();
      }
    }

  private:
    ImageManager() = default;
    ~ImageManager() { Shutdown(); }

    void StartLocked()
    {
      if (!m_Running)
      {
        m_Running = true;
        m_Thread = std::thread(&ImageManager::WorkerLoop, this);
      }
    }

    void WorkerLoop()
    {
      while (true)
      {
        RenderJob job;
        {
          std::unique_lock<std::mutex> lock(m_Mutex);
          m_CondVar.wait(lock, [this]() { return !m_Running || !m_Queue.empty(); });
          if (!m_Running) break;

          job = std::move(m_Queue.front());
          m_Queue.pop_front();
        }

        InlineMedia::CachedImage rendered = RenderWithChafa(job);

        {
          std::unique_lock<std::mutex> lock(m_Mutex);
          if (m_Cache.size() >= 128) m_Cache.clear();
          m_Cache[job.key] = std::move(rendered);
          m_Queued.erase(job.key);
          m_Ready.store(true);
        }
      }
    }

    static InlineMedia::CachedImage RenderWithChafa(const RenderJob& p_Job)
    {
      InlineMedia::CachedImage result;
      std::string sizeArg = std::to_string(p_Job.maxCols) + "x" + std::to_string(p_Job.maxRows);
      std::vector<std::string> args = { "chafa", "-f", p_Job.useKitty ? "kitty" : "symbols" };
      if (!p_Job.useKitty)
      {
        args.push_back("-c");
        args.push_back("full");
        args.push_back("--color-space=rgb");
      }
      else
      {
        args.push_back("--passthrough=none");
      }
      args.push_back("--animate=off");
      args.push_back("-s");
      args.push_back(sizeArg);
      args.push_back("--");
      args.push_back(p_Job.filePath);

      std::string output;
      if (!RunProcessCapture(args, output) || output.empty()) return result;

      if (p_Job.useKitty)
      {
        const size_t start = output.find("\x1b_G");
        const size_t lastSt = output.rfind("\x1b\\");
        if ((start == std::string::npos) || (lastSt == std::string::npos) || (lastSt < start)) return result;
        const size_t firstSt = output.find("\x1b\\", start + 3);
        if ((firstSt == std::string::npos) || (firstSt > lastSt)) return result;
        const size_t semi = output.find(';', start + 3);
        const size_t headerEnd = ((semi != std::string::npos) && (semi < firstSt)) ? semi : firstSt;
        std::string header = output.substr(start + 3, headerEnd - (start + 3));
        int parsedRows = 0;
        int parsedCols = 0;
        std::vector<std::string> newTokens;
        std::vector<std::string> tokens = StrUtil::Split(header, ',');
        for (size_t i = 0; i < tokens.size(); ++i)
        {
          const std::string& tok = tokens[i];
          if (tok.empty()) continue;
          if (StrUtil::StartsWith(tok, "r=") && StrUtil::IsInteger(tok.substr(2)))
            parsedRows = static_cast<int>(StrUtil::ToInteger(tok.substr(2)));
          else if (StrUtil::StartsWith(tok, "c=") && StrUtil::IsInteger(tok.substr(2)))
            parsedCols = static_cast<int>(StrUtil::ToInteger(tok.substr(2)));
          if (!StrUtil::StartsWith(tok, "q=") && !StrUtil::StartsWith(tok, "C="))
            newTokens.push_back(tok);
        }
        if (parsedRows <= 0)
        {
          int nlCount = 0;
          for (size_t i = lastSt + 2; i < output.size(); ++i) if (output[i] == '\n') ++nlCount;
          parsedRows = (nlCount > 0) ? nlCount : 1;
        }
        newTokens.push_back("q=2");
        newTokens.push_back("C=1");
        std::string payload = "\x1b_G" + StrUtil::Join(newTokens, ",") +
          output.substr(headerEnd, (lastSt + 2) - headerEnd);
        result.valid = true;
        result.isKitty = true;
        result.rows = std::min(parsedRows, p_Job.maxRows);
        result.cols = (parsedCols > 0) ? parsedCols : p_Job.maxCols;
        result.payload = std::move(payload);
      }
      else
      {
        std::vector<std::string> lines = StrUtil::Split(output, '\n');
        while (!lines.empty() && lines.back().empty()) lines.pop_back();
        if (lines.empty()) return result;
        if (static_cast<int>(lines.size()) > p_Job.maxRows) lines.resize(static_cast<size_t>(p_Job.maxRows));
        result.valid = true;
        result.isKitty = false;
        result.rows = static_cast<int>(lines.size());
        result.cols = p_Job.maxCols;
        result.lines = std::move(lines);
      }
      return result;
    }

    std::mutex m_Mutex;
    std::condition_variable m_CondVar;
    std::deque<RenderJob> m_Queue;
    std::unordered_set<std::string> m_Queued;
    std::unordered_map<std::string, InlineMedia::CachedImage> m_Cache;
    std::atomic<bool> m_Ready{ false };
    std::thread m_Thread;
    bool m_Running = false;
  };

  class VoiceManager
  {
  public:
    static VoiceManager& Instance()
    {
      static VoiceManager instance;
      return instance;
    }

    bool LookupOrQueue(const std::string& p_FilePath, CachedVoice& p_Out)
    {
      std::unique_lock<std::mutex> lock(m_Mutex);
      auto it = m_Cache.find(p_FilePath);
      if (it != m_Cache.end())
      {
        p_Out = it->second;
        return true;
      }
      if (m_Queued.count(p_FilePath) == 0)
      {
        StartLocked();
        m_Queued.insert(p_FilePath);
        m_Queue.push_back(p_FilePath);
        m_CondVar.notify_one();
      }
      return false;
    }

    bool TakeReady()
    {
      return m_Ready.exchange(false);
    }

    void Shutdown()
    {
      {
        std::unique_lock<std::mutex> lock(m_Mutex);
        if (!m_Running) return;

        m_Running = false;
        m_Queue.clear();
        m_Queued.clear();
        m_CondVar.notify_all();
      }

      if (m_Thread.joinable())
      {
        m_Thread.join();
      }
    }

  private:
    VoiceManager() = default;
    ~VoiceManager() { Shutdown(); }

    void StartLocked()
    {
      if (!m_Running)
      {
        m_Running = true;
        m_Thread = std::thread(&VoiceManager::WorkerLoop, this);
      }
    }

    void WorkerLoop()
    {
      while (true)
      {
        std::string filePath;
        {
          std::unique_lock<std::mutex> lock(m_Mutex);
          m_CondVar.wait(lock, [this]() { return !m_Running || !m_Queue.empty(); });
          if (!m_Running) break;
          filePath = std::move(m_Queue.front());
          m_Queue.pop_front();
        }

        CachedVoice info = AnalyzeAudio(filePath);
        {
          std::unique_lock<std::mutex> lock(m_Mutex);
          if (m_Cache.size() >= 128) m_Cache.clear();
          m_Cache[filePath] = std::move(info);
          m_Queued.erase(filePath);
          m_Ready.store(true);
        }
      }
    }

    static CachedVoice AnalyzeAudio(const std::string& p_FilePath)
    {
      CachedVoice info;
      std::string durOut;
      if (RunProcessCapture({ "ffprobe", "-v", "error", "-show_entries", "format=duration",
                              "-of", "default=noprint_wrappers=1:nokey=1", "--", p_FilePath }, durOut))
      {
        try { info.durationSec = std::max(0.0, std::stod(durOut)); } catch (...) { info.durationSec = 0.0; }
      }

      std::string pcm;
      if (RunProcessCapture({ "ffmpeg", "-v", "error", "-i", p_FilePath, "-ac", "1", "-ar", "200", "-f", "s16le", "-" }, pcm) &&
          (pcm.size() >= 2))
      {
        const size_t sampleCount = pcm.size() / 2;
        if (info.durationSec <= 0.0) info.durationSec = static_cast<double>(sampleCount) / 200.0;
        const size_t numBars = 16;
        std::vector<int> peaks(numBars, 0);
        int maxPeak = 1;
        for (size_t b = 0; b < numBars; ++b)
        {
          const size_t s0 = (b * sampleCount) / numBars;
          const size_t s1 = std::max(s0 + 1, ((b + 1) * sampleCount) / numBars);
          int peak = 0;
          for (size_t i = s0; (i < s1) && (i < sampleCount); ++i)
          {
            const unsigned char lo = static_cast<unsigned char>(pcm[2 * i]);
            const unsigned char hi = static_cast<unsigned char>(pcm[2 * i + 1]);
            const int16_t val = static_cast<int16_t>(static_cast<uint16_t>(lo) | (static_cast<uint16_t>(hi) << 8));
            const int a = (val == -32768) ? 32768 : std::abs(static_cast<int>(val));
            if (a > peak) peak = a;
          }
          peaks[b] = peak;
          if (peak > maxPeak) maxPeak = peak;
        }
        static const wchar_t bars[] = L"\u2581\u2582\u2583\u2584\u2585\u2586\u2587\u2588";
        for (size_t b = 0; b < numBars; ++b)
        {
          int idx = (peaks[b] * 7) / maxPeak;
          idx = std::max(0, std::min(7, idx));
          info.waveform.push_back(bars[idx]);
        }
      }
      if (info.waveform.empty()) info.waveform = L"\u2582\u2584\u2586\u2584\u2587\u2583\u2585\u2582\u2584\u2586\u2585\u2583\u2584\u2586\u2583\u2582";
      info.analyzed = true;
      return info;
    }

    std::mutex m_Mutex;
    std::condition_variable m_CondVar;
    std::deque<std::string> m_Queue;
    std::unordered_set<std::string> m_Queued;
    std::unordered_map<std::string, CachedVoice> m_Cache;
    std::atomic<bool> m_Ready{ false };
    std::thread m_Thread;
    bool m_Running = false;
  };

  class AudioPlayer
  {
  public:
    static AudioPlayer& Instance()
    {
      static AudioPlayer instance;
      return instance;
    }

    bool Toggle(const std::string& p_FilePath)
    {
      std::unique_lock<std::mutex> lock(m_Mutex);
      ReapLocked();
      const bool wasSame = (m_Pid > 0) && (m_FilePath == p_FilePath);
      StopLocked();
      if (wasSame) return true;

      pid_t pid = fork();
      if (pid == 0)
      {
        int devNull = open("/dev/null", O_RDWR);
        if (devNull >= 0)
        {
          dup2(devNull, STDIN_FILENO);
          dup2(devNull, STDOUT_FILENO);
          dup2(devNull, STDERR_FILENO);
          if (devNull > 2) close(devNull);
        }
        execlp("mpv", "mpv", "--no-video", "--no-terminal", "--really-quiet", "--",
               p_FilePath.c_str(), static_cast<char*>(nullptr));
        _exit(127);
      }
      if (pid > 0)
      {
        m_Pid = pid;
        m_FilePath = p_FilePath;
        m_StartTime = std::chrono::steady_clock::now();
        m_LastTick = m_StartTime;
        return true;
      }
      return false;
    }

    void Stop()
    {
      std::unique_lock<std::mutex> lock(m_Mutex);
      StopLocked();
    }

    AudioPlaybackState GetState()
    {
      std::unique_lock<std::mutex> lock(m_Mutex);
      ReapLocked();
      AudioPlaybackState st;
      if (m_Pid > 0)
      {
        st.playing = true;
        st.filePath = m_FilePath;
        st.elapsedSec = std::chrono::duration<double>(std::chrono::steady_clock::now() - m_StartTime).count();
      }
      return st;
    }

    bool TakeTick()
    {
      std::unique_lock<std::mutex> lock(m_Mutex);
      if (m_Pid <= 0) return false;
      if (ReapLocked()) return true;
      auto now = std::chrono::steady_clock::now();
      if (std::chrono::duration_cast<std::chrono::milliseconds>(now - m_LastTick).count() >= 250)
      {
        m_LastTick = now;
        return true;
      }
      return false;
    }

  private:
    AudioPlayer() = default;
    ~AudioPlayer() { Stop(); }

    bool ReapLocked()
    {
      if (m_Pid <= 0) return false;
      int status = 0;
      pid_t r = waitpid(m_Pid, &status, WNOHANG);
      if ((r == m_Pid) || ((r < 0) && (errno != EINTR)))
      {
        m_Pid = -1;
        m_FilePath.clear();
        return true;
      }
      return false;
    }

    void StopLocked()
    {
      if (m_Pid > 0)
      {
        kill(m_Pid, SIGTERM);
        int status = 0;
        while (waitpid(m_Pid, &status, 0) < 0) { if (errno != EINTR) break; }
        m_Pid = -1;
        m_FilePath.clear();
      }
    }

    std::mutex m_Mutex;
    pid_t m_Pid = -1;
    std::string m_FilePath;
    std::chrono::steady_clock::time_point m_StartTime;
    std::chrono::steady_clock::time_point m_LastTick;
  };

  bool s_HasDisplayedKittyImages = false;

  bool HasImageExtension(const std::string& p_Path)
  {
    const std::string ext = StrUtil::ToLower(FileUtil::GetFileExt(p_Path));
    return (ext == ".jpg") || (ext == ".jpeg") || (ext == ".png") ||
           (ext == ".gif") || (ext == ".webp") || (ext == ".bmp") ||
           (ext == ".tif") || (ext == ".tiff") || (ext == ".ico") ||
           (ext == ".avif") || (ext == ".heic");
  }

  bool HasAudioExtension(const std::string& p_Path)
  {
    const std::string ext = StrUtil::ToLower(FileUtil::GetFileExt(p_Path));
    return (ext == ".ogg") || (ext == ".opus") || (ext == ".oga") ||
           (ext == ".m4a") || (ext == ".mp3") || (ext == ".wav") ||
           (ext == ".flac") || (ext == ".aac") || (ext == ".amr") || (ext == ".wma");
  }

  std::string FormatDuration(double p_Sec)
  {
    int total = std::max(0, static_cast<int>(std::llround(p_Sec)));
    int mins = total / 60;
    int secs = total % 60;
    return std::to_string(mins) + ":" + (secs < 10 ? "0" : "") + std::to_string(secs);
  }
}

namespace InlineMedia
{
  bool LookupImageOrQueue(const std::string& p_FilePath, int p_MaxCols, int p_MaxRows,
                          bool p_UseKitty, CachedImage& p_Out)
  {
    return ImageManager::Instance().LookupOrQueue(p_FilePath, p_MaxCols, p_MaxRows, p_UseKitty, p_Out);
  }

  bool TakeImageReady()
  {
    return ImageManager::Instance().TakeReady();
  }

  bool TakeVoiceReady()
  {
    return VoiceManager::Instance().TakeReady();
  }

  std::wstring FormatVoiceBar(const std::string& p_FilePath)
  {
    CachedVoice voiceData;
    const bool analyzed = VoiceManager::Instance().LookupOrQueue(p_FilePath, voiceData) && voiceData.analyzed;
    const AudioPlaybackState audioState = AudioPlayer::Instance().GetState();
    const bool isPlaying = audioState.playing && (audioState.filePath == p_FilePath);
    if (!analyzed)
    {
      return L"\u25a0 ...  (^V play)";
    }

    const std::wstring icon = isPlaying ? L"\u25b6 " : L"\u25a0 ";
    const std::wstring timeStr = isPlaying
      ? StrUtil::ToWString(FormatDuration(audioState.elapsedSec) + "/" + FormatDuration(voiceData.durationSec))
      : StrUtil::ToWString(FormatDuration(voiceData.durationSec));
    std::wstring wf = voiceData.waveform;
    if (isPlaying && (voiceData.durationSec > 0.0) && !wf.empty())
    {
      size_t pos = static_cast<size_t>(std::max(0.0, std::min(1.0, audioState.elapsedSec / voiceData.durationSec)) *
                                       static_cast<double>(wf.size()));
      if (pos > wf.size()) pos = wf.size();
      wf.insert(pos, 1, L'\u258e');
    }
    return icon + timeStr + L"  " + wf + (isPlaying ? L"  (^V stop)" : L"  (^V play)");
  }

  bool ToggleAudioPlayback(const std::string& p_FilePath)
  {
    return AudioPlayer::Instance().Toggle(p_FilePath);
  }

  void StopAudioPlayback()
  {
    AudioPlayer::Instance().Stop();
  }

  bool TakeAudioTick()
  {
    return AudioPlayer::Instance().TakeTick();
  }

  bool IsImageFile(const std::string& p_Path)
  {
    if (HasImageExtension(p_Path)) return true;

    const std::string ext = StrUtil::ToLower(FileUtil::GetFileExt(p_Path));
    if ((ext == ".tgs") || (ext == ".mp4") || (ext == ".webm") || (ext == ".mov") ||
        (ext == ".mkv") || (ext == ".avi") || (ext == ".ogg") || (ext == ".opus") ||
        (ext == ".mp3") || (ext == ".m4a") || (ext == ".wav") || (ext == ".flac") ||
        (ext == ".pdf") || (ext == ".txt") || (ext == ".zip"))
    {
      return false;
    }

    static std::mutex s_MimeMutex;
    static std::unordered_map<std::string, bool> s_MimeCache;
    std::unique_lock<std::mutex> lock(s_MimeMutex);
    auto it = s_MimeCache.find(p_Path);
    if (it != s_MimeCache.end()) return it->second;

    const std::string mime = FileUtil::GetMimeType(p_Path);
    const bool isImg = StrUtil::StartsWith(mime, "image/");
    if (s_MimeCache.size() >= 256) s_MimeCache.clear();
    s_MimeCache[p_Path] = isImg;
    return isImg;
  }

  bool IsAudioFile(const std::string& p_Path)
  {
    if (HasAudioExtension(p_Path)) return true;
    if (HasImageExtension(p_Path)) return false;

    const std::string ext = StrUtil::ToLower(FileUtil::GetFileExt(p_Path));
    if ((ext == ".tgs") || (ext == ".mp4") || (ext == ".webm") || (ext == ".mov") ||
        (ext == ".mkv") || (ext == ".avi") || (ext == ".pdf") || (ext == ".txt") || (ext == ".zip"))
    {
      return false;
    }

    static std::mutex s_AudioMimeMutex;
    static std::unordered_map<std::string, bool> s_AudioMimeCache;
    std::unique_lock<std::mutex> lock(s_AudioMimeMutex);
    auto it = s_AudioMimeCache.find(p_Path);
    if (it != s_AudioMimeCache.end()) return it->second;

    const std::string mime = FileUtil::GetMimeType(p_Path);
    const bool isAud = StrUtil::StartsWith(mime, "audio/") || (mime == "application/ogg");
    if (s_AudioMimeCache.size() >= 256) s_AudioMimeCache.clear();
    s_AudioMimeCache[p_Path] = isAud;
    return isAud;
  }

  bool IsLikelyImageAttachment(const std::string& p_FilePath)
  {
    return (p_FilePath == "[Photo]") ||
           (p_FilePath == "[Sticker]") ||
           HasImageExtension(p_FilePath);
  }

  bool IsLikelyAudioAttachment(const std::string& p_FilePath)
  {
    return (p_FilePath == "[VoiceNote]") ||
           (p_FilePath == "[Voice]") ||
           (p_FilePath == "[Audio]") ||
           HasAudioExtension(p_FilePath);
  }

  bool ResolveUseKitty()
  {
    const std::string proto = StrUtil::ToLower(UiConfig::GetStr("inline_images_protocol"));
    if (proto == "kitty") return true;
    if (proto == "symbols") return false;

    const char* tmux = getenv("TMUX");
    if ((tmux != nullptr) && (tmux[0] != '\0')) return false;

    const char* kittyWin = getenv("KITTY_WINDOW_ID");
    if ((kittyWin != nullptr) && (kittyWin[0] != '\0')) return true;

    const char* ghostty = getenv("GHOSTTY_RESOURCES_DIR");
    if ((ghostty != nullptr) && (ghostty[0] != '\0')) return true;

    const char* term = getenv("TERM");
    if ((term != nullptr) && (std::string(term).find("kitty") != std::string::npos)) return true;

    return false;
  }

  void DrawImages(bool p_Enabled, bool& p_Updated, std::vector<PendingImage>& p_Pending)
  {
    if (!p_Enabled || !p_Updated) return;
    p_Updated = false;

    if (!s_HasDisplayedKittyImages && p_Pending.empty()) return;

    std::string out = "\x1b" "7";
    if (s_HasDisplayedKittyImages)
    {
      out += "\x1b_Ga=d,d=A,q=2\x1b\\";
      s_HasDisplayedKittyImages = false;
    }

    for (size_t i = 0; i < p_Pending.size(); ++i)
    {
      const PendingImage& img = p_Pending[i];
      if (img.isKitty)
      {
        out += "\x1b[" + std::to_string(img.termRow) + ";" + std::to_string(img.termCol) + "H";
        out += img.payload;
        s_HasDisplayedKittyImages = true;
      }
      else
      {
        for (size_t r = 0; r < img.lines.size(); ++r)
        {
          out += "\x1b[" + std::to_string(img.termRow + static_cast<int>(r)) + ";" +
            std::to_string(img.termCol) + "H";
          out += img.lines[r];
          out += "\x1b[0m";
        }
      }
    }

    out += "\x1b" "8";
    size_t written = fwrite(out.data(), 1, out.size(), stdout);
    (void)written;
    fflush(stdout);
  }

  void ClearImages(std::vector<PendingImage>& p_Pending, bool& p_Updated)
  {
    if (s_HasDisplayedKittyImages)
    {
      static const char clearSeq[] = "\x1b" "7\x1b_Ga=d,d=A,q=2\x1b\\\x1b" "8";
      size_t written = fwrite(clearSeq, 1, sizeof(clearSeq) - 1, stdout);
      (void)written;
      fflush(stdout);
      s_HasDisplayedKittyImages = false;
    }

    p_Pending.clear();
    p_Updated = false;
  }

  void Cleanup()
  {
    AudioPlayer::Instance().Stop();
    VoiceManager::Instance().Shutdown();
    ImageManager::Instance().Shutdown();
  }
}
