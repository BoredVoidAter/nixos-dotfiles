#pragma once

#include <string>
#include <vector>

namespace InlineMedia
{
  struct CachedImage
  {
    bool valid = false;
    bool isKitty = false;
    int rows = 0;
    int cols = 0;
    std::string payload;
    std::vector<std::string> lines;
  };

  struct PendingImage
  {
    int termRow = 0;
    int termCol = 0;
    bool isKitty = false;
    std::string payload;
    std::vector<std::string> lines;
  };

  bool LookupImageOrQueue(const std::string& p_FilePath, int p_MaxCols, int p_MaxRows,
                          bool p_UseKitty, CachedImage& p_Out);
  bool TakeImageReady();

  bool TakeVoiceReady();
  std::wstring FormatVoiceBar(const std::string& p_FilePath);

  bool ToggleAudioPlayback(const std::string& p_FilePath);
  void StopAudioPlayback();
  bool TakeAudioTick();

  bool IsImageFile(const std::string& p_Path);
  bool IsAudioFile(const std::string& p_Path);
  bool IsLikelyImageAttachment(const std::string& p_FilePath);
  bool IsLikelyAudioAttachment(const std::string& p_FilePath);
  bool ResolveUseKitty();

  void DrawImages(bool p_Enabled, bool& p_Updated, std::vector<PendingImage>& p_Pending);
  void ClearImages(std::vector<PendingImage>& p_Pending, bool& p_Updated);
  void Cleanup();
}
