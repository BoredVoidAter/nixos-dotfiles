import re


def edit(path, fn):
    with open(path, "r", encoding="utf-8") as f:
        src = f.read()
    dst = fn(src)
    with open(path, "w", encoding="utf-8") as f:
        f.write(dst)


def insert_after(src, anchor, insertion, label):
    count = src.count(anchor)
    assert count == 1, f"Expected 1 match for anchor ({label}), got {count}: {anchor!r}"
    return src.replace(anchor, anchor + insertion, 1)


def insert_before(src, anchor, insertion, label):
    count = src.count(anchor)
    assert count == 1, f"Expected 1 match for anchor ({label}), got {count}: {anchor!r}"
    return src.replace(anchor, insertion + anchor, 1)


def replace_exact(src, old, new, label):
    count = src.count(old)
    assert count == 1, f"Expected 1 match for block ({label}), got {count}: {old!r}"
    return src.replace(old, new, 1)


edit(
    "CMakeLists.txt",
    lambda s: insert_after(
        s, "  src/uihistoryview.cpp\n", "  src/inline_media.cpp\n", "CMakeLists.txt"
    ),
)


def patch_ui_cpp(s):
    s = insert_after(s, '#include "uiconfig.h"\n', '#include "inline_media.h"\n', "ui.cpp include")
    s = insert_after(s, "  m_Model->Cleanup();\n", "  InlineMedia::Cleanup();\n", "ui.cpp cleanup")
    s = insert_before(s, "  wclear(stdscr);\n", "  m_Model->ClearInlineImages();\n", "ui.cpp clear")
    return s


edit("src/ui.cpp", patch_ui_cpp)

edit(
    "src/uiconfig.cpp",
    lambda s: insert_after(
        s,
        '    { "home_fetch_all", "0" },\n',
        '    { "inline_images", "1" },\n'
        '    { "inline_images_auto_download", "1" },\n'
        '    { "inline_images_max_height", "14" },\n'
        '    { "inline_images_max_width", "50" },\n'
        '    { "inline_images_protocol", "auto" },\n'
        '    { "inline_voice", "1" },\n'
        '    { "inline_voice_auto_download", "1" },\n',
        "uiconfig.cpp",
    ),
)

edit(
    "src/uidialog.cpp",
    lambda s: insert_before(
        s, "  Init();\n  curs_set(0);\n", "  m_Model->ClearInlineImages();\n", "uidialog.cpp"
    ),
)

edit(
    "src/uihelpview.cpp",
    lambda s: insert_after(
        s,
        '    AppendHelpItem("transfer", "SendFile", helpItems);\n',
        '    AppendHelpItem("record_voice", "Voice", helpItems);\n',
        "uihelpview.cpp",
    ),
)

edit(
    "src/uikeyconfig.cpp",
    lambda s: insert_after(
        s,
        '    { "transfer", "KEY_CTRLT" },\n',
        r'    { "record_voice", "\\33\\155" }, // alt/opt-m' + "\n",
        "uikeyconfig.cpp",
    ),
)


def patch_history_h(s):
    s = insert_after(
        s,
        '#include "uiviewbase.h"\n',
        '#include <vector>\n#include "inline_media.h"\n',
        "uihistoryview.h include",
    )
    s = insert_after(
        s,
        "  int GetHistoryShowCount();\n",
        "  bool CheckPendingInlineImages();\n  void DrawInlineImages();\n  void ClearInlineImages();\n",
        "uihistoryview.h methods",
    )
    s = insert_after(
        s,
        "  WINDOW* m_PaddedWin = nullptr;\n",
        "  int m_PaddedX = 0;\n  int m_PaddedY = 0;\n",
        "uihistoryview.h coords",
    )
    s = insert_after(
        s,
        "  int m_HistoryShowCount = 0;\n",
        "  bool m_InlineImagesUpdated = false;\n  std::vector<InlineMedia::PendingImage> m_PendingInlineImages;\n",
        "uihistoryview.h state",
    )
    return s


edit("src/uihistoryview.h", patch_history_h)


def patch_history_cpp(s):
    s = insert_after(s, '#include "uimodel.h"\n', '#include "inline_media.h"\n', "uihistoryview.cpp include")
    s = replace_exact(
        s,
        "    int paddedY = m_Y + vpad;\n"
        "    int paddedX = m_X + hpad;\n"
        "    m_PaddedH = m_H - (vpad * 2);\n"
        "    m_PaddedW = m_W - (hpad * 2);\n"
        "    m_PaddedWin = newwin(m_PaddedH, m_PaddedW, paddedY, paddedX);\n",
        "    m_PaddedY = m_Y + vpad;\n"
        "    m_PaddedX = m_X + hpad;\n"
        "    m_PaddedH = m_H - (vpad * 2);\n"
        "    m_PaddedW = m_W - (hpad * 2);\n"
        "    m_PaddedWin = newwin(m_PaddedH, m_PaddedW, m_PaddedY, m_PaddedX);\n",
        "uihistoryview.cpp ctor",
    )
    s = insert_after(
        s,
        "  m_HistoryShowCount = 0;\n",
        "  m_PendingInlineImages.clear();\n"
        "  m_InlineImagesUpdated = true;\n\n"
        '  static const bool inlineImagesEnabled = UiConfig::GetBool("inline_images");\n'
        '  static const bool inlineImagesAutoDownload = UiConfig::GetBool("inline_images_auto_download");\n'
        '  static const int inlineImagesMaxHeight = std::max(1, UiConfig::GetNum("inline_images_max_height"));\n'
        '  static const int inlineImagesMaxWidth = std::max(4, UiConfig::GetNum("inline_images_max_width"));\n'
        "  static const bool inlineUseKitty = InlineMedia::ResolveUseKitty();\n"
        '  static const bool inlineVoiceEnabled = UiConfig::GetBool("inline_voice");\n'
        '  static const bool inlineVoiceAutoDownload = UiConfig::GetBool("inline_voice_auto_download");\n'
        "  const bool isModalDialogActive = m_Model->GetListDialogActiveLocked() ||\n"
        "    m_Model->GetFileListDialogActiveLocked() || m_Model->GetMessageDialogActiveLocked();\n",
        "uihistoryview.cpp draw init",
    )
    s = insert_before(
        s,
        "    if (!msg.fileInfo.empty())\n",
        "    int inlineImgRows = 0;\n"
        "    int inlineVoiceRows = 0;\n"
        "    InlineMedia::CachedImage inlineImgData;\n",
        "uihistoryview.cpp file vars",
    )
    s = replace_exact(
        s,
        "      if (isAttachmentPrefetchAll || (isSelectedMessage && isAttachmentPrefetchSelected))\n",
        "      if (isAttachmentPrefetchAll || (isSelectedMessage && isAttachmentPrefetchSelected) ||\n"
        "          (inlineImagesEnabled && inlineImagesAutoDownload && InlineMedia::IsLikelyImageAttachment(fileInfo.filePath)) ||\n"
        "          (inlineVoiceEnabled && inlineVoiceAutoDownload && InlineMedia::IsLikelyAudioAttachment(fileInfo.filePath)))\n",
        "uihistoryview.cpp auto download",
    )
    s = insert_after(
        s,
        "      wlines.insert(wlines.begin(), fileStr);\n",
        "      if (inlineImagesEnabled && (m_PaddedH >= 5) && (m_PaddedW >= 4) &&\n"
        "          (fileInfo.fileStatus == FileStatusDownloaded) && UiModel::IsAttachmentDownloaded(fileInfo) &&\n"
        "          InlineMedia::IsImageFile(fileInfo.filePath))\n"
        "      {\n"
        "        const int maxCols = std::min(m_PaddedW, inlineImagesMaxWidth);\n"
        "        const int maxRows = std::min(inlineImagesMaxHeight, std::max(1, m_PaddedH - 4));\n"
        "        if (InlineMedia::LookupImageOrQueue(fileInfo.filePath, maxCols, maxRows,\n"
        "                                            inlineUseKitty, inlineImgData) &&\n"
        "            inlineImgData.valid && (inlineImgData.rows > 0) && (inlineImgData.rows <= maxRows))\n"
        "        {\n"
        "          inlineImgRows = inlineImgData.rows;\n"
        '          wlines.insert(wlines.begin() + 1, static_cast<size_t>(inlineImgRows), L"");\n'
        "        }\n"
        "      }\n"
        "      else if (inlineVoiceEnabled && (m_PaddedH >= 4) && (m_PaddedW >= 12) &&\n"
        "               (fileInfo.fileStatus == FileStatusDownloaded) && UiModel::IsAttachmentDownloaded(fileInfo) &&\n"
        "               InlineMedia::IsAudioFile(fileInfo.filePath))\n"
        "      {\n"
        "        wlines.insert(wlines.begin() + 1, InlineMedia::FormatVoiceBar(fileInfo.filePath));\n"
        "        inlineVoiceRows = 1;\n"
        "      }\n",
        "uihistoryview.cpp placeholder",
    )
    old_loop = (
        "    for (auto wline = wlines.rbegin(); wline != wlines.rend(); ++wline)\n"
        "    {\n"
        "      bool isAttachment = (wline->rfind(attachmentIndicator, 0) == 0);\n"
        "      bool isQuote = (wline->rfind(quoteIndicator, 0) == 0);\n"
        "      bool isReaction = (reactionLines == 1) && (std::distance(wline, wlines.rbegin()) == 0);\n\n"
        "      if (isAttachment)\n"
        "      {\n"
        "        wattron(m_PaddedWin, attributeText | colorPairTextAttachment);\n"
        "      }\n"
        "      else if (isQuote)\n"
        "      {\n"
        "        wattron(m_PaddedWin, attributeText | colorPairTextQuoted);\n"
        "      }\n"
        "      else if (isReaction)\n"
        "      {\n"
        "        wattron(m_PaddedWin, attributeTextNormal | colorPairTextReaction);\n"
        "      }\n"
        "      else\n"
        "      {\n"
        "        wattron(m_PaddedWin, attributeText | colorPairText);\n"
        "      }\n\n"
        "      const std::wstring wdisp = isReaction ? *wline : StrUtil::TrimPadWString(*wline, m_PaddedW);\n"
        "      mvwaddnwstr(m_PaddedWin, y, 0, wdisp.c_str(), std::min((int)wdisp.size(), m_PaddedW));\n\n"
        "      if (isAttachment)\n"
        "      {\n"
        "        wattroff(m_PaddedWin, attributeText | colorPairTextAttachment);\n"
        "      }\n"
        "      else if (isQuote)\n"
        "      {\n"
        "        wattroff(m_PaddedWin, attributeText | colorPairTextQuoted);\n"
        "      }\n"
        "      else if (isReaction)\n"
        "      {\n"
        "        wattroff(m_PaddedWin, attributeTextNormal | colorPairTextReaction);\n"
        "      }\n"
        "      else\n"
        "      {\n"
        "        wattroff(m_PaddedWin, attributeText | colorPairText);\n"
        "      }\n\n"
        "      if (--y < 0) break;\n"
        "    }\n"
    )
    new_loop = (
        "    int drawnImgRows = 0;\n"
        "    int firstImgY = -1;\n"
        "    int lastImgY = -1;\n"
        "    for (auto wline = wlines.rbegin(); wline != wlines.rend(); ++wline)\n"
        "    {\n"
        "      const int idx = static_cast<int>(wlines.size()) - 1 -\n"
        "        static_cast<int>(std::distance(wlines.rbegin(), wline));\n"
        "      const bool isImageRow = (inlineImgRows > 0) && (idx >= 1) && (idx <= inlineImgRows);\n"
        "      if (isImageRow)\n"
        "      {\n"
        "        wattron(m_PaddedWin, attributeTextNormal | colorPairTextRecv);\n"
        '        const std::wstring wdisp = StrUtil::TrimPadWString(L"", m_PaddedW);\n'
        "        mvwaddnwstr(m_PaddedWin, y, 0, wdisp.c_str(), std::min((int)wdisp.size(), m_PaddedW));\n"
        "        wattroff(m_PaddedWin, attributeTextNormal | colorPairTextRecv);\n"
        "        if (lastImgY < 0) lastImgY = y;\n"
        "        firstImgY = y;\n"
        "        ++drawnImgRows;\n"
        "      }\n"
        "      else\n"
        "      {\n"
        "        bool isAttachment = (wline->rfind(attachmentIndicator, 0) == 0);\n"
        "        bool isQuote = (wline->rfind(quoteIndicator, 0) == 0);\n"
        "        bool isReaction = (reactionLines == 1) && (std::distance(wline, wlines.rbegin()) == 0);\n"
        "        const bool isVoiceBar = (inlineImgRows == 0) && (inlineVoiceRows > 0) && (idx == 1);\n\n"
        "        if (isAttachment || isVoiceBar)\n"
        "          wattron(m_PaddedWin, attributeText | colorPairTextAttachment);\n"
        "        else if (isQuote)\n"
        "          wattron(m_PaddedWin, attributeText | colorPairTextQuoted);\n"
        "        else if (isReaction)\n"
        "          wattron(m_PaddedWin, attributeTextNormal | colorPairTextReaction);\n"
        "        else\n"
        "          wattron(m_PaddedWin, attributeText | colorPairText);\n\n"
        "        const std::wstring wdisp = isReaction ? *wline : StrUtil::TrimPadWString(*wline, m_PaddedW);\n"
        "        mvwaddnwstr(m_PaddedWin, y, 0, wdisp.c_str(), std::min((int)wdisp.size(), m_PaddedW));\n\n"
        "        if (isAttachment || isVoiceBar)\n"
        "          wattroff(m_PaddedWin, attributeText | colorPairTextAttachment);\n"
        "        else if (isQuote)\n"
        "          wattroff(m_PaddedWin, attributeText | colorPairTextQuoted);\n"
        "        else if (isReaction)\n"
        "          wattroff(m_PaddedWin, attributeTextNormal | colorPairTextReaction);\n"
        "        else\n"
        "          wattroff(m_PaddedWin, attributeText | colorPairText);\n"
        "      }\n\n"
        "      if (--y < 0) break;\n"
        "    }\n\n"
        "    if ((inlineImgRows > 0) && (drawnImgRows == inlineImgRows) &&\n"
        "        (firstImgY >= 0) && (lastImgY < m_PaddedH) && !isModalDialogActive)\n"
        "    {\n"
        "      InlineMedia::PendingImage pending;\n"
        "      pending.termRow = m_PaddedY + firstImgY + 1;\n"
        "      pending.termCol = m_PaddedX + 1;\n"
        "      pending.isKitty = inlineImgData.isKitty;\n"
        "      pending.payload = inlineImgData.payload;\n"
        "      pending.lines = inlineImgData.lines;\n"
        "      m_PendingInlineImages.push_back(std::move(pending));\n"
        "    }\n"
    )
    s = replace_exact(s, old_loop, new_loop, "uihistoryview.cpp draw loop")
    s = s + (
        "\nbool UiHistoryView::CheckPendingInlineImages()\n"
        "{\n"
        "  return InlineMedia::TakeImageReady() || InlineMedia::TakeVoiceReady() || InlineMedia::TakeAudioTick();\n"
        "}\n\n"
        "void UiHistoryView::DrawInlineImages()\n"
        "{\n"
        "  InlineMedia::DrawImages(m_Enabled, m_InlineImagesUpdated, m_PendingInlineImages);\n"
        "}\n\n"
        "void UiHistoryView::ClearInlineImages()\n"
        "{\n"
        "  InlineMedia::ClearImages(m_PendingInlineImages, m_InlineImagesUpdated);\n"
        "}\n"
    )
    return s


edit("src/uihistoryview.cpp", patch_history_cpp)

edit("src/uiview.h", lambda s: insert_before(s, "  void TerminalBell();\n", "  void ClearInlineImages();\n", "uiview.h"))


def patch_uiview_cpp(s):
    s = insert_after(
        s,
        "void UiView::Init()\n{\n",
        "  if (m_UiHistoryView)\n  {\n    m_UiHistoryView->ClearInlineImages();\n  }\n\n",
        "uiview.cpp Init",
    )
    s = insert_after(
        s,
        "void UiView::Draw()\n{\n",
        "  if (m_UiHistoryView->CheckPendingInlineImages())\n"
        "  {\n    m_UiHistoryView->SetDirty(true);\n    m_UiEntryView->SetDirty(true);\n  }\n\n",
        "uiview.cpp Draw",
    )
    s = replace_exact(
        s,
        "  m_UiEntryView->Draw();\n  curs_set(1);\n}\n",
        "  m_UiEntryView->Draw();\n  curs_set(1);\n  m_UiHistoryView->DrawInlineImages();\n}\n\n"
        "void UiView::ClearInlineImages()\n{\n  if (m_UiHistoryView)\n  {\n"
        "    m_UiHistoryView->ClearInlineImages();\n  }\n}\n",
        "uiview.cpp DrawInlineImages",
    )
    return s


edit("src/uiview.cpp", patch_uiview_cpp)


def patch_uimodel_h(s):
    s = insert_after(
        s,
        "    void Draw();\n    void ReinitView();\n",
        "    void ClearInlineImages();\n"
        "    std::string PreRecordVoice();\n"
        "    void PostRecordVoice(const std::string& p_FilePath, bool p_Success);\n",
        "uimodel.h Impl",
    )
    s = insert_after(
        s,
        "  void Cleanup();\n  void ReinitView();\n",
        "  void ClearInlineImages();\n",
        "uimodel.h public",
    )
    s = insert_after(s, "  void OnKeyTransfer();\n", "  void OnKeyRecordVoice();\n", "uimodel.h private")
    return s


edit("src/uimodel.h", patch_uimodel_h)


def patch_uimodel_cpp(s):
    s = insert_after(s, '#include "uiconfig.h"\n', '#include "inline_media.h"\n', "uimodel.cpp include")
    s = insert_after(s, "void UiModel::Impl::TerminalControlPause()\n{\n", "  ClearInlineImages();\n", "uimodel.cpp pause")
    s = insert_after(
        s,
        "void UiModel::Impl::OpenAttachment(const std::string& p_Path)\n{\n",
        '  if (UiConfig::GetBool("inline_voice") && InlineMedia::IsAudioFile(p_Path))\n'
        "  {\n"
        "    InlineMedia::ToggleAudioPlayback(p_Path);\n"
        "    UpdateHistory();\n"
        "    return;\n"
        "  }\n\n",
        "uimodel.cpp OpenAttachment",
    )
    s = replace_exact(
        s,
        "      FileInfo fileInfo;\n"
        "      fileInfo.filePath = filePath;\n"
        "      fileInfo.fileType = FileUtil::GetMimeType(filePath);",
        "      FileInfo fileInfo;\n"
        "      fileInfo.filePath = filePath;\n"
        "      fileInfo.fileType = FileUtil::GetMimeType(filePath);\n"
        "      const std::string ext = StrUtil::ToLower(FileUtil::GetFileExt(filePath));\n"
        '      if ((fileInfo.fileType == "application/ogg") ||\n'
        '          ((fileInfo.fileType.empty() || (fileInfo.fileType == "application/octet-stream")) &&\n'
        '           ((ext == ".ogg") || (ext == ".opus") || (ext == ".oga"))))\n'
        "      {\n"
        '        fileInfo.fileType = "audio/ogg";\n'
        "      }",
        "uimodel.cpp TransferFile",
    )
    s = insert_after(
        s,
        "void UiModel::Impl::ReinitView()\n{\n  m_View->Init();\n}\n",
        "\nvoid UiModel::Impl::ClearInlineImages()\n{\n  m_View->ClearInlineImages();\n}\n\n"
        "std::string UiModel::Impl::PreRecordVoice()\n{\n"
        "  AnyUserKeyInput();\n"
        '  if (GetEditMessageActive() || !IsCurrentChatSet()) return "";\n\n'
        "  InlineMedia::StopAudioPlayback();\n"
        "  TerminalControlPause();\n"
        "  static int voiceIndex = 0;\n"
        "  ++voiceIndex;\n"
        '  return FileUtil::GetTempDir() + "/voice-" + std::to_string(voiceIndex) + ".ogg";\n'
        "}\n\n"
        "void UiModel::Impl::PostRecordVoice(const std::string& p_FilePath, bool p_Success)\n{\n"
        "  TerminalControlResume();\n"
        "  if (p_Success && !p_FilePath.empty() && FileUtil::Exists(p_FilePath))\n  {\n"
        "    TransferFile({ p_FilePath });\n"
        '    FileUtil::RmFilesByAge(FileUtil::GetTempDir(), "voice-*.ogg", 300);\n'
        "  }\n  else\n  {\n"
        "    if (!p_FilePath.empty()) FileUtil::RmFile(p_FilePath);\n"
        "    ReinitView();\n  }\n}\n",
        "uimodel.cpp voice impl",
    )
    s = insert_after(
        s,
        'void UiModel::Impl::HandleProtocolUiControlStart()\n{\n  LOG_TRACE("handle protocol ui control start");\n',
        "  ClearInlineImages();\n",
        "uimodel.cpp protocol ui control",
    )
    s = insert_after(
        s,
        "void UiModel::ReinitView()\n{\n  std::unique_lock<owned_mutex> lock(m_ModelMutex);\n  GetImpl().ReinitView();\n}\n",
        "\nvoid UiModel::ClearInlineImages()\n{\n  std::unique_lock<owned_mutex> lock(m_ModelMutex);\n  GetImpl().ClearInlineImages();\n}\n",
        "uimodel.cpp ClearInlineImages",
    )
    s = insert_after(
        s,
        '  static wint_t keySelectMention = UiKeyConfig::GetKey("select_mention");\n',
        '  static wint_t keyRecordVoice = UiKeyConfig::GetKey("record_voice");\n',
        "uimodel.cpp keyRecordVoice",
    )
    s = insert_after(
        s,
        "  else if (p_Key == keyAutoCompose)\n  {\n    OnKeyAutoCompose();\n  }\n",
        "  else if (p_Key == keyRecordVoice)\n  {\n    OnKeyRecordVoice();\n  }\n",
        "uimodel.cpp key dispatch",
    )
    s = insert_after(
        s,
        "  GetImpl().TransferFile(filePaths);\n}\n",
        "\nvoid UiModel::OnKeyRecordVoice()\n{\n"
        "  std::string voicePath;\n"
        "  {\n    std::unique_lock<owned_mutex> lock(m_ModelMutex);\n    voicePath = GetImpl().PreRecordVoice();\n  }\n\n"
        "  if (voicePath.empty()) return;\n\n"
        '  const std::string cmd = "nchat-record \'" + StrUtil::EscapeSingleQuote(voicePath) + "\'";\n'
        "  int rv = SysUtil::System(cmd);\n\n"
        "  std::unique_lock<owned_mutex> lock(m_ModelMutex);\n"
        "  GetImpl().PostRecordVoice(voicePath, rv == 0);\n}\n",
        "uimodel.cpp OnKeyRecordVoice",
    )
    return s


edit("src/uimodel.cpp", patch_uimodel_cpp)


def patch_upload_go(s):
    s = replace_exact(
        s,
        "func (cli *Client) Upload(ctx context.Context, plaintext []byte, appInfo MediaType) (resp UploadResponse, err error) {\n"
        "\tresp.FileLength = uint64(len(plaintext))\n"
        "\tresp.MediaKey = random.Bytes(32)\n\n"
        "\tplaintextSHA256 := sha256.Sum256(plaintext)\n"
        "\tresp.FileSHA256 = plaintextSHA256[:]\n\n"
        "\tiv, cipherKey, macKey, _ := getMediaKeys(resp.MediaKey, appInfo)\n\n"
        "\tvar ciphertext []byte\n"
        "\tciphertext, err = cbcutil.Encrypt(cipherKey, iv, plaintext)\n"
        "\tif err != nil {\n"
        '\t\terr = fmt.Errorf("failed to encrypt file: %w", err)\n'
        "\t\treturn\n"
        "\t}\n\n"
        "\th := hmac.New(sha256.New, macKey)\n"
        "\th.Write(iv)\n"
        "\th.Write(ciphertext)\n"
        "\tdataToUpload := append(ciphertext, h.Sum(nil)[:10]...)\n\n"
        "\tdataHash := sha256.Sum256(dataToUpload)\n"
        "\tresp.FileEncSHA256 = dataHash[:]\n\n"
        "\terr = cli.rawUpload(ctx, bytes.NewReader(dataToUpload), uint64(len(dataToUpload)), resp.FileEncSHA256, appInfo, false, &resp)\n"
        "\treturn\n"
        "}\n",
        "func (cli *Client) Upload(ctx context.Context, plaintext []byte, appInfo MediaType) (resp UploadResponse, err error) {\n"
        '\treturn cli.uploadWithMMSType(ctx, plaintext, appInfo, "")\n'
        "}\n\n"
        "// UploadPTT encrypts with MediaAudio keys while uploading to the /mms/ptt endpoint.\n"
        "func (cli *Client) UploadPTT(ctx context.Context, plaintext []byte) (resp UploadResponse, err error) {\n"
        '\treturn cli.uploadWithMMSType(ctx, plaintext, MediaAudio, "ptt")\n'
        "}\n\n"
        "func (cli *Client) uploadWithMMSType(ctx context.Context, plaintext []byte, appInfo MediaType, mmsTypeOverride string) (resp UploadResponse, err error) {\n"
        "\tresp.FileLength = uint64(len(plaintext))\n"
        "\tresp.MediaKey = random.Bytes(32)\n\n"
        "\tplaintextSHA256 := sha256.Sum256(plaintext)\n"
        "\tresp.FileSHA256 = plaintextSHA256[:]\n\n"
        "\tiv, cipherKey, macKey, _ := getMediaKeys(resp.MediaKey, appInfo)\n\n"
        "\tvar ciphertext []byte\n"
        "\tciphertext, err = cbcutil.Encrypt(cipherKey, iv, plaintext)\n"
        "\tif err != nil {\n"
        '\t\terr = fmt.Errorf("failed to encrypt file: %w", err)\n'
        "\t\treturn\n"
        "\t}\n\n"
        "\th := hmac.New(sha256.New, macKey)\n"
        "\th.Write(iv)\n"
        "\th.Write(ciphertext)\n"
        "\tdataToUpload := append(ciphertext, h.Sum(nil)[:10]...)\n\n"
        "\tdataHash := sha256.Sum256(dataToUpload)\n"
        "\tresp.FileEncSHA256 = dataHash[:]\n\n"
        "\terr = cli.rawUploadWithMMSType(ctx, bytes.NewReader(dataToUpload), uint64(len(dataToUpload)), resp.FileEncSHA256, appInfo, mmsTypeOverride, false, &resp)\n"
        "\treturn\n"
        "}\n",
        "upload.go UploadPTT",
    )
    s = replace_exact(
        s,
        "func (cli *Client) rawUpload(ctx context.Context, dataToUpload io.Reader, uploadSize uint64, fileHash []byte, appInfo MediaType, newsletter bool, resp *UploadResponse) error {\n"
        "\tmediaConn, err := cli.refreshMediaConn(ctx, false)\n"
        "\tif err != nil {\n"
        '\t\treturn fmt.Errorf("failed to refresh media connections: %w", err)\n'
        "\t}\n\n"
        "\ttoken := base64.URLEncoding.EncodeToString(fileHash)\n"
        "\tq := url.Values{\n"
        '\t\t"auth":  []string{mediaConn.Auth},\n'
        '\t\t"token": []string{token},\n'
        "\t}\n"
        "\tmmsType := mediaTypeToMMSType[appInfo]\n",
        "func (cli *Client) rawUpload(ctx context.Context, dataToUpload io.Reader, uploadSize uint64, fileHash []byte, appInfo MediaType, newsletter bool, resp *UploadResponse) error {\n"
        '\treturn cli.rawUploadWithMMSType(ctx, dataToUpload, uploadSize, fileHash, appInfo, "", newsletter, resp)\n'
        "}\n\n"
        "func (cli *Client) rawUploadWithMMSType(ctx context.Context, dataToUpload io.Reader, uploadSize uint64, fileHash []byte, appInfo MediaType, mmsTypeOverride string, newsletter bool, resp *UploadResponse) error {\n"
        "\tmediaConn, err := cli.refreshMediaConn(ctx, false)\n"
        "\tif err != nil {\n"
        '\t\treturn fmt.Errorf("failed to refresh media connections: %w", err)\n'
        "\t}\n\n"
        "\ttoken := base64.URLEncoding.EncodeToString(fileHash)\n"
        "\tq := url.Values{\n"
        '\t\t"auth":  []string{mediaConn.Auth},\n'
        '\t\t"token": []string{token},\n'
        "\t}\n"
        "\tmmsType := mediaTypeToMMSType[appInfo]\n"
        "\tif len(mmsTypeOverride) > 0 {\n"
        "\t\tmmsType = mmsTypeOverride\n"
        "\t}\n",
        "upload.go rawUploadWithMMSType",
    )
    return s


edit("lib/wmchat/go/ext/whatsmeow/upload.go", patch_upload_go)


def patch_gowm_go(s):
    s = insert_after(
        s,
        '\tMediaType  whatsmeow.MediaType `json:"MediaType_MediaType"`\n',
        '\tMmsType    string              `json:"MmsType_string,omitempty"`\n',
        "gowm.go DownloadInfo",
    )
    s = insert_after(
        s,
        "\tinfo.MediaType = whatsmeow.GetMediaType(msg)\n"
        "\tif len(info.MediaType) == 0 {\n"
        '\t\tLOG_WARNING(fmt.Sprintf("unknown mediatype in msg %+v", msg))\n'
        '\t\treturn ""\n'
        "\t}\n",
        "\tif aud, isAud := msg.(*waE2E.AudioMessage); isAud && aud.GetPTT() {\n"
        '\t\tinfo.MmsType = "ptt"\n'
        "\t}\n",
        "gowm.go DownloadableMessageToFileId",
    )
    s = replace_exact(
        s,
        "\tif len(info.DirectPath) > 0 {\n"
        '\t\tLOG_TRACE(fmt.Sprintf("download directpath: %s", info.DirectPath))\n'
        "\t\treturn client.DownloadMediaWithPath(ctx, info.DirectPath, info.FileEncSha256, info.FileSha256, info.MediaKey, info.MediaType, whatsmeow.GetMMSType(info.MediaType), false)\n"
        "\t}\n",
        "\tif len(info.DirectPath) > 0 {\n"
        '\t\tLOG_TRACE(fmt.Sprintf("download directpath: %s", info.DirectPath))\n'
        "\t\tmmsType := info.MmsType\n"
        "\t\tif len(mmsType) == 0 {\n"
        "\t\t\tmmsType = whatsmeow.GetMMSType(info.MediaType)\n"
        "\t\t}\n"
        "\t\treturn client.DownloadMediaWithPath(ctx, info.DirectPath, info.FileEncSha256, info.FileSha256, info.MediaKey, info.MediaType, mmsType, false)\n"
        "\t}\n",
        "gowm.go DownloadFromFileInfo",
    )

    mime_pat = re.compile(
        r'mimeParts := strings\.Split\(fileType, "/"\)\n'
        r'[ \t]+mimeType := mimeParts\[0\][^\n]*\n'
        r'[ \t]+mimeSubType := ""\n'
        r'[ \t]+if len\(mimeParts\) > 1 \{\n'
        r'[ \t]+mimeSubType = mimeParts\[1\][^\n]*\n'
        r'[ \t]+\}'
    )
    m = mime_pat.search(s)
    assert m, "mimeParts anchor not found in gowm.go"
    mime_add = (
        "\n"
        "\t\textLower := strings.ToLower(filepath.Ext(filePath))\n"
        '\t\tif (fileType == "application/ogg") || (extLower == ".ogg") || (extLower == ".opus") || (extLower == ".oga") {\n'
        '\t\t\tmimeType = "audio"\n'
        '\t\t\tmimeSubType = "ogg"\n'
        '\t\t\tfileType = "audio/ogg"\n'
        "\t\t}"
    )
    s = s[: m.end()] + mime_add + s[m.end() :]

    audio_pat = re.compile(
        r'\t\t\tuploaded, upErr := client\.Upload\(context\.Background\(\), data, whatsmeow\.MediaAudio\)\n'
        r'\t\t\tif upErr != nil \{\n'
        r'\t\t\t\tLOG_WARNING\(fmt\.Sprintf\("upload error %#v", upErr\)\)\n'
        r'\t\t\t\treturn -1\n'
        r'\t\t\t\}\n\n'
        r'\t\t\taudioMime := fileType\n'
        r'\t\t\tif fileType == "audio/ogg" \{\n'
        r'\t\t\t\taudioMime = "audio/ogg; codecs=opus"\n'
        r'\t\t\t\}\n\n'
        r'\t\t\taudioMessage := waE2E\.AudioMessage\{.*?\n\t\t\t\}',
        re.DOTALL,
    )
    ma = audio_pat.search(s)
    assert ma, "AudioMessage anchor not found in gowm.go"
    new_audio = (
        '\t\t\tisVoiceNote := strings.HasPrefix(filepath.Base(filePath), "voice-") &&\n'
        '\t\t\t\t(strings.ToLower(filepath.Ext(filePath)) == ".ogg")\n\n'
        "\t\t\tvar uploaded whatsmeow.UploadResponse\n"
        "\t\t\tvar upErr error\n"
        "\t\t\tif isVoiceNote {\n"
        "\t\t\t\tuploaded, upErr = client.UploadPTT(context.Background(), data)\n"
        "\t\t\t} else {\n"
        "\t\t\t\tuploaded, upErr = client.Upload(context.Background(), data, whatsmeow.MediaAudio)\n"
        "\t\t\t}\n"
        "\t\t\tif upErr != nil {\n"
        '\t\t\t\tLOG_WARNING(fmt.Sprintf("upload error %#v", upErr))\n'
        "\t\t\t\treturn -1\n"
        "\t\t\t}\n\n"
        "\t\t\taudioMime := fileType\n"
        '\t\t\tif (fileType == "audio/ogg") || (fileType == "audio/opus") {\n'
        '\t\t\t\taudioMime = "audio/ogg; codecs=opus"\n'
        "\t\t\t}\n\n"
        "\t\t\tseconds, waveform := GetAudioInfo(filePath)\n\n"
        "\t\t\taudioMessage := waE2E.AudioMessage{\n"
        "\t\t\t\tURL:               proto.String(uploaded.URL),\n"
        "\t\t\t\tDirectPath:        proto.String(uploaded.DirectPath),\n"
        "\t\t\t\tMediaKey:          uploaded.MediaKey,\n"
        "\t\t\t\tMimetype:          proto.String(audioMime),\n"
        "\t\t\t\tFileEncSHA256:     uploaded.FileEncSHA256,\n"
        "\t\t\t\tFileSHA256:        uploaded.FileSHA256,\n"
        "\t\t\t\tFileLength:        proto.Uint64(uint64(len(data))),\n"
        "\t\t\t\tMediaKeyTimestamp: proto.Int64(time.Now().Unix()),\n"
        "\t\t\t\tContextInfo:       &contextInfo,\n"
        "\t\t\t}\n"
        "\t\t\tif seconds > 0 {\n"
        "\t\t\t\taudioMessage.Seconds = proto.Uint32(seconds)\n"
        "\t\t\t}\n"
        "\t\t\tif isVoiceNote {\n"
        "\t\t\t\taudioMessage.PTT = proto.Bool(true)\n"
        "\t\t\t\tif len(waveform) > 0 {\n"
        "\t\t\t\t\taudioMessage.Waveform = waveform\n"
        "\t\t\t\t}\n"
        "\t\t\t}"
    )
    s = s[: ma.start()] + new_audio + s[ma.end() :]
    return s


edit("lib/wmchat/go/gowm.go", patch_gowm_go)
