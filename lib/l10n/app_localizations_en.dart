// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get aboutCopyright =>
      'Copyright © 2026 Yunling Zhang · Local first, all data stays on this device';

  @override
  String get aboutDeveloperMode => 'Developer mode';

  @override
  String get aboutDeveloperModeHint =>
      'Shows \"Developer options\" in Settings when enabled';

  @override
  String get aboutDeveloperSection => 'Developer';

  @override
  String get aboutGithub => 'GitHub repository';

  @override
  String get aboutLicense => 'License';

  @override
  String get aboutPlatform => 'Platform';

  @override
  String get aboutTagline =>
      'A simple, efficient AI chat client compatible with OpenAI APIs';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutVersion => 'Version';

  @override
  String get accentIndigo => 'Indigo';

  @override
  String get accentOrange => 'Orange';

  @override
  String get accentRed => 'Red';

  @override
  String get accentRose => 'Rose';

  @override
  String get accentSky => 'Sky';

  @override
  String get accentSlate => 'Slate';

  @override
  String get accentTeal => 'Teal';

  @override
  String get accentViolet => 'Violet';

  @override
  String get addModelApiKeyRequired => 'Please enter the API key first';

  @override
  String get addModelExample => 'e.g. gpt-4o';

  @override
  String get addModelFetch => 'Fetch model list';

  @override
  String addModelFetchFailed(String detail) {
    return '';
  }

  @override
  String get addModelFetchFromList => 'Fetch from list';

  @override
  String get addModelFetchHint =>
      'Calls the /models endpoint to fetch models\\nEnter the API key first';

  @override
  String get addModelManual => 'Manual entry';

  @override
  String get addModelManualHint => 'Enter a model ID';

  @override
  String get addModelNoModels => 'The endpoint returned no models';

  @override
  String get addModelReasoningHint => 'Reasoning models support thinking mode';

  @override
  String get addModelTitle => 'Add model';

  @override
  String get agentAdd => 'Add agent';

  @override
  String get agentConfigTitle => 'Agents';

  @override
  String get agentDefault => 'Default';

  @override
  String get agentDefaultHint => 'Auto-applied when creating a new chat';

  @override
  String get agentDefaultParams => 'Default params';

  @override
  String get agentDefaultSystemPrompt =>
      'You are Nona, a simple and efficient AI chat assistant. Respond in a clear and friendly tone, be accurate and well-organized; ask follow-up questions when the request is unclear, but don\'t overdo it. Default to the language the user is using.';

  @override
  String agentDeleteConfirm(String name) {
    return '';
  }

  @override
  String get agentDeleteTitle => 'Delete agent';

  @override
  String get agentEdit => 'Edit agent';

  @override
  String get agentEmpty => 'No agents yet, tap + to add';

  @override
  String get agentMemories => 'Long-term memory (one per line)';

  @override
  String get agentMemoriesHint => 'e.g. user prefers concise answers';

  @override
  String get agentName => 'Name';

  @override
  String get agentNameHint => 'e.g. Code assistant, Translator';

  @override
  String get agentNameRequired => 'Please enter an agent name';

  @override
  String get agentNew => 'New agent';

  @override
  String get agentSetDefault => 'Set as default agent';

  @override
  String get appTitle => 'Nona';

  @override
  String get chatClearInput => 'Clear';

  @override
  String chatContextUsage(String tokens) {
    return '';
  }

  @override
  String get chatCopyMarkdown => 'Copy as Markdown';

  @override
  String get chatDeleteSession => 'Delete session';

  @override
  String get chatDeleteSelectedTitle => 'Delete selected messages';

  @override
  String chatDeleteSelectedBody(int count) {
    return 'This will delete the selected $count messages and everything after them. This cannot be undone. Continue?';
  }

  @override
  String get chatDelete => 'Delete';

  @override
  String chatDeleted(int count) {
    return 'Deleted $count messages';
  }

  @override
  String get tokenDetailTitle => 'Token details';

  @override
  String get tokenDetailInput => 'Input (API)';

  @override
  String get tokenDetailOutput => 'Output (API)';

  @override
  String get tokenDetailElapsed => 'Elapsed';

  @override
  String get tokenDetailModel => 'Model';

  @override
  String get tokenDetailEstimated => 'Local estimate (body)';

  @override
  String get tokenDetailCost => 'Cost';

  @override
  String get tokenDetailUnavailable => '—';

  @override
  String get tokenDetailNoPrice => 'No price recorded';

  @override
  String get tokenDetailHint =>
      'Local estimate counts the reply body with tiktoken (prompt excluded).';

  @override
  String get quickPhrasesTitle => 'Quick phrases';

  @override
  String get quickPhrasesAdd => 'Add phrase';

  @override
  String get quickPhrasesEdit => 'Edit phrase';

  @override
  String get quickPhrasesEmpty => 'No quick phrases yet. Tap + to add one.';

  @override
  String get quickPhrasesContent => 'Content';

  @override
  String get quickPhrasesGlobal => 'Global (all sessions)';

  @override
  String get settingsQuickPhrasesSubtitle => 'Type / in the input to insert';

  @override
  String get quickPhrasesDeleteTitle => 'Delete quick phrase';

  @override
  String quickPhrasesDeleteBody(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get quickPhrasesDeleted => 'Deleted';

  @override
  String get iiTitle => 'Instruction injections';

  @override
  String get iiAdd => 'Add instruction';

  @override
  String get iiEdit => 'Edit instruction';

  @override
  String get iiEmpty =>
      'No instructions yet. Tap + to add one (check to activate).';

  @override
  String get iiPrompt => 'Instruction text';

  @override
  String get iiGroup => 'Group (optional)';

  @override
  String get iiDeleteTitle => 'Delete instruction';

  @override
  String iiDeleteBody(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get settingsIiSubtitle =>
      'Custom prompt snippets injected with each request';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String get updateVersion => 'Version';

  @override
  String get updateDownload => 'Go to download';

  @override
  String get settingsUpdateCheck => 'Check for updates on start';

  @override
  String get settingsUpdateSource => 'Update source (GitHub Releases URL)';

  @override
  String get devCrashReporting => 'Crash reporting (Sentry)';

  @override
  String get devCrashReportingHint =>
      'Send crash reports when enabled (requires SENTRY_DSN at build time); off by default';

  @override
  String get wfTitle => 'Automation workflows';

  @override
  String get wfAdd => 'New workflow';

  @override
  String get wfEdit => 'Edit workflow';

  @override
  String get wfName => 'Name';

  @override
  String get wfActionText =>
      'Action (send_message text; supports cur_date variables)';

  @override
  String get wfDeleteTitle => 'Delete workflow';

  @override
  String wfDeleteBody(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get wfRunSuccess => 'Workflow finished';

  @override
  String get wfRunFailed => 'Workflow failed, see run history';

  @override
  String get wfEmpty => 'No workflows yet. Tap + to create one.';

  @override
  String get wfListTitle => 'Workflows';

  @override
  String get wfRun => 'Run now';

  @override
  String get wfHistoryTitle => 'Run history';

  @override
  String get routerTitle => 'Model routing';

  @override
  String get routerEnable => 'Enable smart model routing';

  @override
  String get routerEnableHint =>
      'Auto-pick models for title/summary tasks by cost & speed (low cost first)';

  @override
  String get routerNoData =>
      'No routing records yet - they will appear here after tasks run';

  @override
  String get routerRecentStats => 'Routing stats (last 30 days)';

  @override
  String get settingsRouterSubtitle => 'Auto-pick models by cost & speed';

  @override
  String get syncIncrementalTitle => 'Multi-device incremental sync';

  @override
  String get syncIncrementalHint =>
      'Push local changes and pull changes from other devices';

  @override
  String get syncIncrementalNow => 'Sync now';

  @override
  String syncIncrementalDone(int pushed, int pulled) {
    return 'Pushed $pushed, pulled $pulled changes';
  }

  @override
  String syncLastAt(String at) {
    return 'Last sync: $at';
  }

  @override
  String syncConflicts(int n) {
    return '$n conflict(s) pending (local newer changes kept)';
  }

  @override
  String get privacyTitle => 'Privacy & offline';

  @override
  String get offlineMode => 'Offline mode';

  @override
  String get offlineModeHint =>
      'Local embeddings, no network requests; ideal for airplane mode';

  @override
  String get offlineCapabilities => 'Offline capability status';

  @override
  String get offlineCapEmbedding => 'Text embeddings';

  @override
  String get offlineCapKbSearch => 'Knowledge base search';

  @override
  String get offlineCapWebSearch => 'Web search';

  @override
  String get offlineCapTts => 'Speech (TTS)';

  @override
  String get offlineCapAsr => 'Speech input (local)';

  @override
  String get offlineStatusLocal => 'Local';

  @override
  String get offlineStatusCloud => 'Cloud';

  @override
  String get offlineStatusOff => 'Off';

  @override
  String get offlineStatusSystem => 'System';

  @override
  String get offlineStatusNeedsDownload => 'Model download needed';

  @override
  String get offlineNote =>
      'Local embeddings are deterministic hash vectors (384-d), fully offline; upgrades automatically when an ONNX semantic model is available.';

  @override
  String get settingsPrivacySubtitle => 'Offline mode & local capabilities';

  @override
  String get settingsWfSubtitle =>
      'Scheduled / event-triggered automated actions';

  @override
  String get chatDocument => 'Document';

  @override
  String chatDocumentFailed(int count) {
    return '$count documents failed to parse';
  }

  @override
  String chatDocumentSubtitle(int count) {
    return '$count chars';
  }

  @override
  String get chatDocumentTitle => 'Text Document';

  @override
  String get chatDeleteMessageConfirm =>
      'Delete this message and everything after it?';

  @override
  String get chatEffortAuto => 'Reasoning: Auto';

  @override
  String get chatEffortAutoShort => 'Auto';

  @override
  String get chatEffortHigh => 'Reasoning: High';

  @override
  String get chatEffortHighShort => 'High';

  @override
  String get chatEffortLow => 'Reasoning: Low';

  @override
  String get chatEffortLowShort => 'Low';

  @override
  String get chatEffortMedium => 'Reasoning: Medium';

  @override
  String get chatEffortMediumShort => 'Medium';

  @override
  String get chatErrorEmpty => 'The API returned no content. Please try again.';

  @override
  String get chatErrorInvalidFormat => 'Unable to parse the API response.';

  @override
  String get chatErrorMissingContent =>
      'The API response is missing the reply content.';

  @override
  String get chatErrorStream => 'Failed to read the response stream.';

  @override
  String get chatExport => 'Export';

  @override
  String get chatExportHtml => 'Export as HTML';

  @override
  String get chatExportJson => 'Export as JSON';

  @override
  String get chatExportMarkdown => 'Export as Markdown';

  @override
  String get chatExportPdf => 'Export as PDF';

  @override
  String get chatGenerating => 'Generating…';

  @override
  String get chatGenerationFailed => 'Generation failed';

  @override
  String get chatHelloSubtitle =>
      'Multi-provider AI chat. Start a new conversation.';

  @override
  String get chatHelloTitle => 'Hello, I\'m Nona';

  @override
  String get chatImage => 'Image';

  @override
  String chatImageLoadFailed(Object uri) {
    return 'Failed to load image: $uri';
  }

  @override
  String get chatInputHintEnterNewline =>
      'Type a message, Enter for newline, Ctrl+Enter to send';

  @override
  String get chatInputHintEnterSend =>
      'Type a message, Enter to send, Shift+Enter for newline';

  @override
  String get chatMermaidUnsupported =>
      'Mermaid syntax not supported, showing source';

  @override
  String get chatNewSession => 'New chat';

  @override
  String get chatNoModel => 'No model configured';

  @override
  String get chatNoProvider => 'No provider configured';

  @override
  String get chatOverLimit => 'Over limit, will trim on send';

  @override
  String get chatRegenerate => 'Regenerate';

  @override
  String get chatRollback => 'Rollback to here';

  @override
  String chatRollbackVersion(int count) {
    return 'Roll back to previous version ($count total)';
  }

  @override
  String get chatSelectModel => 'Select model';

  @override
  String get chatSessionContext => 'Session context';

  @override
  String get chatSessionCopySuffix => ' (copy)';

  @override
  String get chatSessionList => 'Sessions';

  @override
  String get assistantDisplayName => 'Nona';

  @override
  String get citationSourcesTitle => 'Sources';

  @override
  String chatSelectionTitle(int count) {
    return '$count selected';
  }

  @override
  String get chatSelectAll => 'Select all';

  @override
  String get chatEnterSelection => 'Select messages';

  @override
  String get dropBackupUnsupported =>
      'Dropped backup files are not supported here';

  @override
  String get dropUnsupported => 'Unsupported file type';

  @override
  String get dropFailed => 'Failed to process file';

  @override
  String get dropImageTooLarge => 'Image over 8MB, skipped';

  @override
  String get dropExtractFailed => 'Failed to extract document text';

  @override
  String get dropRestoreTitle => 'Restore backup';

  @override
  String dropRestoreBody(String file) {
    return 'Sessions from $file will be merged into current data (duplicates skipped). Continue?';
  }

  @override
  String get dropRestoreConfirm => 'Restore';

  @override
  String dropRestoreDone(int count) {
    return 'Restored $count sessions';
  }

  @override
  String get chatInvertSelection => 'Invert';

  @override
  String chatDeleteSelected(int count) {
    return 'Delete ($count)';
  }

  @override
  String get importSelectSessions => 'Select sessions to import';

  @override
  String get importToggleAll => 'Select all / none';

  @override
  String messageProviderBadge(String provider, String model) {
    return '($provider · $model)';
  }

  @override
  String get chatSessionNewTitle => '新对话';

  @override
  String orchestratorMemoryPrompt(String content) {
    return 'Here is long-term memory about the user and this assistant. Use it as reference:';
  }

  @override
  String orchestratorKbPrompt(String content) {
    return 'Here is relevant content from the knowledge base. Prefer it when answering:';
  }

  @override
  String get orchestratorSearchFailed =>
      'Web search failed: free engines may be unavailable in this environment. Switch to Tavily / Bocha (API Key required) or a self-hosted SearXNG server in Settings.';

  @override
  String toolApprovalTitle(String toolName) {
    return 'Allow the model to call tool \"$toolName\"?';
  }

  @override
  String get toolApprovalAllowOnce => 'Allow once';

  @override
  String get toolApprovalAllowRemember => 'Remember & allow';

  @override
  String get toolApprovalDeny => 'Deny';

  @override
  String get toolApprovalRiskHint =>
      'This tool comes from an external server and may read or modify your data. Review the arguments before deciding.';

  @override
  String toolApprovalServer(String serverName) {
    return 'Source: $serverName';
  }

  @override
  String get toolApprovalArguments => 'Arguments';

  @override
  String get toolApprovalAutoHint =>
      'This tool is remembered and will run automatically until you revoke it in MCP settings.';

  @override
  String chatShowFull(int count) {
    return 'View full text ($count chars)';
  }

  @override
  String get chatSpeak => 'Read aloud';

  @override
  String get chatStopSpeaking => 'Stop reading';

  @override
  String get chatStopped => 'Generation stopped';

  @override
  String get chatStream => 'Stream';

  @override
  String get chatThinking => 'Thinking';

  @override
  String get chatTokensDown => 'Output tokens (generated)';

  @override
  String get chatTokensUp => 'Input tokens (sent)';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDiscard => 'Leave anyway';

  @override
  String get commonWarning => 'Warning';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonCopied => 'Copied';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonDefault => 'Default';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonDeleted => 'Deleted';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonFailed => 'Failed';

  @override
  String get commonFailedTest => 'Test failed';

  @override
  String get commonImport => 'Import';

  @override
  String get commonMe => 'Me';

  @override
  String get commonNone => 'None';

  @override
  String get commonNotSpecified => 'Not specified';

  @override
  String get commonNotTested => 'Not tested';

  @override
  String get commonOff => 'Off';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonRestore => 'Restore';

  @override
  String get commonRetry => 'Retry';

  @override
  String get loadFailedBanner => 'Failed to load data. Recovery attempted';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSend => 'Send';

  @override
  String get commonSaveFailed => 'Save failed. Please try again';

  @override
  String get commonSaved => 'Saved';

  @override
  String get commonStop => 'Stop';

  @override
  String get commonUnknownError => 'Unknown error';

  @override
  String get commonUnlimited => 'Unlimited';

  @override
  String get commonUntested => 'Untested';

  @override
  String get compareEmpty => 'Pick at least one model and enter a question';

  @override
  String get compareFailed => 'Failed';

  @override
  String get compareHint => 'Ask a question and pick models to compare…';

  @override
  String get compareRunning => 'Comparing…';

  @override
  String get compareStart => 'Compare';

  @override
  String get compareTitle => 'Model Compare';

  @override
  String get compareWaiting => 'Waiting…';

  @override
  String get contextAutoTrim => 'Auto-trim old messages';

  @override
  String get contextAutoTrimHint =>
      'Automatically remove the oldest messages when over the limit';

  @override
  String get contextCommaSeparated => 'Separate with commas';

  @override
  String get contextCustom => 'Custom (manual)';

  @override
  String get contextFrequencyPenalty => 'Frequency Penalty';

  @override
  String get contextFrequencyPenaltyTip =>
      'Penalizes token frequency in the text, range -2~2.\\n\\nHigher values suppress repetition and boilerplate.';

  @override
  String get contextInfoGotIt => 'Got it';

  @override
  String get contextInfoTitle => 'Info';

  @override
  String get contextMaxContext => 'Context window management';

  @override
  String get contextMaxContextHint => '≤32000, empty = unlimited';

  @override
  String get contextMaxContextTip =>
      'Controls how much history is sent:\\n\\n· Max context: when exceeded, a strategy applies; empty = unlimited\\n· Auto-trim: estimate before sending and remove oldest messages when over the limit\\n\\nAvoids exceeding the provider\'s context window, saves cost and prevents errors.';

  @override
  String get contextMaxTokens => 'Max Tokens';

  @override
  String get contextMaxTokensHint => 'Empty = provider decides';

  @override
  String get contextMaxTokensTip =>
      'Maximum tokens for one reply; the rest is truncated.\\n\\nEmpty = provider decides based on the model limit.';

  @override
  String get contextN => 'N (candidate count)';

  @override
  String get contextNHint => 'Empty = default 1';

  @override
  String get contextNTip =>
      'How many candidate replies to generate, default 1.\\n\\nValues > 1 return multiple replies for you to choose; increases token usage.';

  @override
  String get contextNoAgent =>
      'No agents yet. Create presets in Settings → Agents for quick reuse.';

  @override
  String get contextPresencePenalty => 'Presence Penalty';

  @override
  String get contextPresencePenaltyTip =>
      'Penalizes tokens already present, range -2~2.\\n\\nHigher values encourage new topics and discourage repeating existing content.';

  @override
  String get contextQuickConfig => 'Quick config';

  @override
  String get contextResponseFormat => 'Response Format';

  @override
  String get contextResponseFormatJson => 'JSON (json_object)';

  @override
  String get contextResponseFormatJsonShort => 'JSON';

  @override
  String get contextResponseFormatText => 'Text (text)';

  @override
  String get contextResponseFormatTextShort => 'Text';

  @override
  String get contextResponseFormatTip =>
      'Expected output format:\\n\\n· Not specified: default text\\n· text: plain text\\n· json_object: only valid JSON, easy to parse programmatically\\n\\nSome models don\'t support JSON mode; check provider docs.';

  @override
  String get contextSavedNote =>
      'Params are saved with the session and only affect it.';

  @override
  String get contextSeed => 'Seed';

  @override
  String get contextSeedHint => 'Empty = random';

  @override
  String get contextSeedTip =>
      'With the same seed and input, most providers reproduce similar results — handy for debugging.\\n\\nEmpty = random.';

  @override
  String get contextStop => 'Stop sequences';

  @override
  String get contextStopTip =>
      'Stops generation when these strings are reached.\\n\\nSeparate multiple sequences with commas, e.g.:\\n\\n,。！？\\n\\nEmpty = no stop sequences.';

  @override
  String get contextSystemPrompt => 'System prompt';

  @override
  String get contextSystemPromptHint =>
      'Optional, sets the assistant\'s role and behavior';

  @override
  String get contextSystemPromptTip =>
      'Sets the assistant\'s role, style and behavior rules; sent as a system message at the front of the conversation.';

  @override
  String get contextTemperature => 'Temperature';

  @override
  String get contextTemperatureHint => 'Empty = default 1';

  @override
  String get contextTemperatureTip =>
      'Controls randomness, range 0~2.\\n\\nHigher = more creative and varied; lower = more stable and predictable. Lower it for reliable answers.';

  @override
  String get contextTitle => 'Session context';

  @override
  String get contextTopP => 'Top P (nucleus sampling)';

  @override
  String get contextTopPHint => 'Empty = default 1';

  @override
  String get contextTopPTip =>
      'Samples from the token set whose cumulative probability reaches this value, range 0~1.\\n\\nAdjust either this or Temperature; avoid changing both drastically.';

  @override
  String get devAutoUpdate => 'Auto-update on startup';

  @override
  String get devAutoUpdateHint =>
      'Silently updates the table from the network on startup; failure doesn\'t affect usage';

  @override
  String devBuiltinVersion(String version) {
    return '';
  }

  @override
  String get devCapabilityDesc =>
      'Built-in static table (offline fallback) + network-updated cache, auto-fills multimodal/reasoning per model id';

  @override
  String get devCapabilitySection => 'Model capability table';

  @override
  String get devCapabilityTitle => 'Model capability table';

  @override
  String get devConnectivitySection => 'Connectivity';

  @override
  String get devMaxLogs => 'Max retained entries';

  @override
  String get devMaxLogsExample => 'e.g. 1000';

  @override
  String get devMaxLogsInvalid => 'Please enter a non-negative integer';

  @override
  String get devMaxLogsLabel => 'Entries (empty = unlimited)';

  @override
  String devMaxLogsSubtitle(int count) {
    return 'Keep up to $count logs (0 = unlimited)';
  }

  @override
  String get devMaxLogsTitle => 'Max retained entries';

  @override
  String get devMaxLogsUnlimited => 'Unlimited, keep all records';

  @override
  String get devNetworkLog => 'Network logs';

  @override
  String devNetworkLogCount(int count) {
    return '$count logs recorded';
  }

  @override
  String get devNetworkLogDisabled =>
      'Not enabled; requests are captured once enabled';

  @override
  String get devNetworkLogEnable => 'Enable network logs';

  @override
  String get devNetworkLogEnableHint =>
      'Records all network requests (chat, tests, model fetch, etc.)';

  @override
  String get devNetworkLogSection => 'Network logs';

  @override
  String get devNoBuiltinTable => 'No built-in table';

  @override
  String get devTestPrompt => 'Connectivity test prompt';

  @override
  String get devTestPromptExample => 'e.g. ping';

  @override
  String get devTestPromptHint =>
      'Minimal request content sent to the model during connectivity tests';

  @override
  String get devTitle => 'Developer options';

  @override
  String devUpdateFailed(Object error) {
    return 'Update failed: $error';
  }

  @override
  String get devUpdateFromNetwork => 'Update from network';

  @override
  String get devUpdated => 'Capability table updated';

  @override
  String devUpdatedAt(String time) {
    return '';
  }

  @override
  String get devUpdating => 'Updating…';

  @override
  String get devUpdatingShort => 'Updating';

  @override
  String get devWarning =>
      'Developer options contain high-risk settings for advanced users. Proceed with caution.';

  @override
  String get homeAnonymousSession => 'Anonymous session';

  @override
  String get homeCopied => 'Copied to clipboard';

  @override
  String get homeCopiedMarkdown => 'Copied as Markdown';

  @override
  String get homeCopiedSession => 'Session duplicated';

  @override
  String homeDeleteSessionConfirm(String title) {
    return '';
  }

  @override
  String homeExportedTo(String path) {
    return '';
  }

  @override
  String get homeImageTooLargeSkippedAll => 'Image over 8MB, skipped';

  @override
  String get homeImageTooLargeSkippedSome =>
      'Some images over 8MB were skipped';

  @override
  String get homeModelMismatch =>
      'The current provider doesn\'t include this model; check Settings';

  @override
  String get homeNetworkError =>
      'Network request failed, check network or config';

  @override
  String get homeNoApiKey => 'Please complete the provider API key';

  @override
  String get homeNoModel => 'Please select a model first';

  @override
  String get homeNoProvider => 'Please configure a provider in Settings first';

  @override
  String get homeRenameSession => 'Rename session';

  @override
  String get homeRollbackConfirm => 'Rollback';

  @override
  String get homeRollbackContent =>
      'This deletes this message and everything after it, and fills the input box with its content for editing. Continue?';

  @override
  String get homeRollbackTitle => 'Rollback to here';

  @override
  String get homeSessionNameHint => 'Session name';

  @override
  String get homeTitlePrompt =>
      'Generate a concise title for the user\'s conversation (no more than 20 characters, no quotes, no explanation, output the title only)';

  @override
  String homeTrimmed(int count) {
    return 'Context limit reached; removed $count earliest messages';
  }

  @override
  String homeCompacted(Object count) {
    return 'Context limit reached; compressed $count earliest messages into a summary (see the bar above the messages)';
  }

  @override
  String summaryCompressed(Object count) {
    return '$count messages compressed into a summary';
  }

  @override
  String summaryCompressedMessages(Object count) {
    return 'Original compressed messages ($count):';
  }

  @override
  String get summaryTitle => 'Session summary (injected into every request)';

  @override
  String get summaryEmpty => '(summary is empty)';

  @override
  String get summaryEdit => 'Edit summary';

  @override
  String get summaryEditHint =>
      'The edited summary will replace the compressed messages in future requests';

  @override
  String get summaryClear => 'Clear compression records';

  @override
  String get kbAdd => 'Add document';

  @override
  String get kbAddFailed => 'Nothing to add';

  @override
  String kbAdded(int count) {
    return 'Added $count documents';
  }

  @override
  String get kbEmpty => 'Knowledge base is empty';

  @override
  String get kbEmptyHint => 'Tap + to add text files (txt/md/json)';

  @override
  String get kbHint => 'Relevant content is retrieved and injected during chat';

  @override
  String get kbCreateLibrary => 'New library';

  @override
  String get kbLibraryNameHint => 'Library name';

  @override
  String get kbRenameLibrary => 'Rename library';

  @override
  String get kbDeleteLibrary => 'Delete library';

  @override
  String kbDeleteLibraryConfirm(Object name) {
    return 'Deleting library \"$name\" also deletes all its documents. Continue?';
  }

  @override
  String kbDeleteConfirm(String name) {
    return '';
  }

  @override
  String get kbTitle => 'Knowledge Base';

  @override
  String get mcpAdd => 'Add server';

  @override
  String mcpDeleteConfirm(String name) {
    return '';
  }

  @override
  String get mcpEdit => 'Edit server';

  @override
  String get mcpEmpty => 'No MCP servers configured';

  @override
  String get mcpEmptyHint =>
      'Tap + in the top right to add one (MCP-compatible server URL)';

  @override
  String get mcpHeaders => 'Headers (one per line, Key: Value)';

  @override
  String get mcpHint =>
      'MCP (Model Context Protocol) lets the model call external tools. Supported transports: streamable HTTP / SSE.';

  @override
  String get mcpName => 'Server name';

  @override
  String get mcpFieldsRequired => 'Name and URL are required';

  @override
  String get mcpNeedsApproval => 'Require confirmation for tool calls';

  @override
  String get mcpNeedsApprovalHint =>
      'Ask for confirmation before executing tools';

  @override
  String get mcpTitle => 'MCP Servers';

  @override
  String get mcpUrl => 'Server URL';

  @override
  String get messageEditAssistantHint => 'Edit reply content…';

  @override
  String get messageScrollToBottom => 'Scroll to bottom';

  @override
  String get messageEditAssistantLabel => 'Reply content';

  @override
  String get messageEditAssistantTitle => 'Edit assistant reply';

  @override
  String get messageEditNote =>
      'Changes take effect in subsequent conversations';

  @override
  String get messageEditReasoningHint => 'Edit the model\'s thinking process…';

  @override
  String get messageEditReasoningLabel => 'Thinking content';

  @override
  String get messageEditReasoningNote =>
      'Both thinking and reply content are editable and feed into subsequent context';

  @override
  String get messageEditTitle => 'Edit message';

  @override
  String get messageEditUserHint => 'Edit message content…';

  @override
  String get messageEditUserLabel => 'Message content';

  @override
  String get modelConfigChatModel => 'Chat model';

  @override
  String get modelConfigChatModelDesc =>
      'Default model for new sessions. Reset to choose manually each time.';

  @override
  String get modelConfigNoModels =>
      'No models configured, add one in Providers first';

  @override
  String get modelConfigPickChat => 'Choose chat model';

  @override
  String get modelConfigPickTitle => 'Choose title model';

  @override
  String get modelConfigPickTranslator => 'Choose translation model';

  @override
  String get modelConfigResetChatContent =>
      'After reset, new sessions won\'t auto-select a model. Continue?';

  @override
  String get modelConfigResetChatTitle => 'Reset chat model';

  @override
  String get modelConfigResetTitleContent =>
      'After reset, session titles use the default first-message logic. Continue?';

  @override
  String get modelConfigResetTitleTitle => 'Reset title model';

  @override
  String get modelConfigResetTranslatorContent =>
      'After reset, AI translation falls back to the chat model. Continue?';

  @override
  String get modelConfigResetTranslatorTitle => 'Reset translation model';

  @override
  String get modelConfigSaved => 'Saved';

  @override
  String get modelConfigTitle => 'Model config';

  @override
  String get modelConfigTitleModel => 'Title generation model';

  @override
  String get modelConfigTitleModelDesc =>
      'When set, session titles are auto-generated from the first message; otherwise the default truncation logic is used.';

  @override
  String get modelConfigTranslatorModel => 'Translation model';

  @override
  String get modelConfigTranslatorModelDesc =>
      'When set, the AI translator uses this model; otherwise it falls back to the chat model.';

  @override
  String get modelConfigUnset => 'Not set';

  @override
  String get networkLogBasic => 'Basic info';

  @override
  String networkLogBodyMeta(String bytes, int lines) {
    return '';
  }

  @override
  String get networkLogClear => 'Clear logs';

  @override
  String get networkLogClearConfirm =>
      'This deletes all recorded network logs. Continue?';

  @override
  String get networkLogClearTitle => 'Clear network logs';

  @override
  String get networkLogCopiedFull => 'Copied full text';

  @override
  String get networkLogCopyFull => 'Copy full text';

  @override
  String networkLogCountLimited(int count, int max) {
    return '\$count records · max $max';
  }

  @override
  String networkLogCountUnlimited(int count) {
    return '$count records · unlimited';
  }

  @override
  String networkLogDateFull(int year, int month, int day) {
    return '\$year-\$month-$day';
  }

  @override
  String networkLogDateToday(int month, int day) {
    return '\$month-$day';
  }

  @override
  String get networkLogDetailTitle => 'Log details';

  @override
  String get networkLogDuration => 'Duration';

  @override
  String get networkLogEditorUnsupported =>
      'Opening in an external editor is not supported on this platform';

  @override
  String get networkLogEmpty => 'No network logs';

  @override
  String get networkLogEmptyHint =>
      'Enable \"Network logs\" in Developer options to start recording';

  @override
  String get networkLogExport => 'Export logs';

  @override
  String get networkLogExported => 'Logs exported';

  @override
  String get networkLogExternalEditor => 'External editor';

  @override
  String networkLogFailed(String error) {
    return '';
  }

  @override
  String get networkLogFilterAll => 'All';

  @override
  String get networkLogFilterFailed => 'Failed';

  @override
  String get networkLogFilterSuccess => 'Success';

  @override
  String get networkLogFormatJson => 'Format JSON';

  @override
  String get networkLogFormatted => ' · formatted';

  @override
  String networkLogFullTitle(String label) {
    return '';
  }

  @override
  String get networkLogInvalidJson =>
      'Content is not valid JSON, cannot format';

  @override
  String get networkLogMethod => 'Method';

  @override
  String get networkLogRequest => 'Request';

  @override
  String get networkLogRequestBody => 'Request body';

  @override
  String get networkLogRequestHeaders => 'Request headers';

  @override
  String get networkLogRequestSize => 'Request size';

  @override
  String get networkLogResponse => 'Response';

  @override
  String get networkLogResponseBody => 'Response body';

  @override
  String get networkLogResponseHeaders => 'Response headers';

  @override
  String get networkLogResponseSize => 'Response size';

  @override
  String get networkLogShowRaw => 'Show raw';

  @override
  String get networkLogStatus => 'Status';

  @override
  String get networkLogTime => 'Time';

  @override
  String get networkLogTitle => 'Network logs';

  @override
  String get networkLogToday => 'Today';

  @override
  String get networkLogType => 'Type';

  @override
  String get networkLogTypeCapability => 'Capability';

  @override
  String get networkLogTypeChat => 'Chat';

  @override
  String get networkLogTypeModels => 'Models';

  @override
  String get networkLogTypeOther => 'Other';

  @override
  String get networkLogTypeTest => 'Test';

  @override
  String get networkLogUrl => 'URL';

  @override
  String get networkLogViewFull => 'View full';

  @override
  String get networkLogYesterday => 'Yesterday';

  @override
  String get preferencesAutoRetry => 'Auto-retry failed requests';

  @override
  String get preferencesAutoRetryHint =>
      'Automatically retry on connection failures, rate limits or server errors (exponential backoff, up to 3 attempts)';

  @override
  String get preferencesDocumentThreshold => 'Text document threshold';

  @override
  String get preferencesDocumentThresholdExample => 'e.g. 40000, 0 to disable';

  @override
  String get preferencesDocumentThresholdInvalid =>
      'Please enter a non-negative number';

  @override
  String get preferencesDocumentThresholdLabel => 'Threshold (chars)';

  @override
  String get preferencesDocumentThresholdOff => 'Disabled (render directly)';

  @override
  String get preferencesDocumentThresholdTitle => 'Text document threshold';

  @override
  String preferencesDocumentThresholdValue(int count) {
    return 'Messages longer than $count chars shown as document';
  }

  @override
  String get preferencesEnterSend => 'Enter to send';

  @override
  String get preferencesEnterSendHint =>
      'When off, the IME newline key inserts a newline instead of sending.';

  @override
  String get preferencesEnterSendOff =>
      'Press Enter for newline, Ctrl+Enter to send';

  @override
  String get preferencesEnterSendOn =>
      'Press Enter to send, Shift+Enter for newline';

  @override
  String get preferencesLanguage => 'Language';

  @override
  String get preferencesLanguageEn => 'English';

  @override
  String get preferencesLanguageSystem => 'System';

  @override
  String get preferencesLanguageZh => 'Chinese';

  @override
  String get preferencesStreamMarkdown => 'Live Markdown rendering';

  @override
  String get preferencesStreamMarkdownHint =>
      'Render Markdown in real time while generating; turn off to render after generation completes (smoother for very long replies)';

  @override
  String get preferencesTitle => 'Preferences';

  @override
  String get preferencesTtsLanguage => 'Speech language';

  @override
  String get preferencesTtsLanguageEn => 'English';

  @override
  String get preferencesTtsLanguageJa => '日本語';

  @override
  String get preferencesTtsLanguageZh => '中文';

  @override
  String get preferencesTtsRate => 'Speech rate';

  @override
  String get preferencesWebSearch => 'Web search';

  @override
  String get preferencesWebSearchApiKey => 'API Key';

  @override
  String get preferencesWebSearchApiKeyHint => 'Not configured (tap to set)';

  @override
  String get searchEngineBing => 'Bing (free)';

  @override
  String get searchEngineDuckduckgo => 'DuckDuckGo (free)';

  @override
  String get searchEngineTavily => 'Tavily (API Key required)';

  @override
  String get searchEngineBocha => 'Bocha (API Key required)';

  @override
  String get searchEngineSearxng => 'SearXNG (self-hosted)';

  @override
  String get preferencesWebSearchBaseUrl => 'SearXNG URL';

  @override
  String get preferencesWebSearchBaseUrlHint => 'Not configured (tap to set)';

  @override
  String get preferencesWebSearchEngine => 'Search engine';

  @override
  String get preferencesWebSearchHint =>
      'Search the web before sending and inject results for the model to cite';

  @override
  String get providerAdd => 'Add provider';

  @override
  String get providerAddModel => 'Add model';

  @override
  String get providerAdvancedSettings => 'Advanced settings';

  @override
  String get providerBaseSettings => 'Basic settings';

  @override
  String get providerClickRetest => 'Tap to retest';

  @override
  String get providerClickTest => 'Tap to test';

  @override
  String get providerCustomBody => 'Custom request body (JSON, merged)';

  @override
  String get providerCustomBodyInvalid =>
      'Custom request body is not valid JSON; it will be lost when leaving';

  @override
  String get providerCustomHeaders =>
      'Custom headers (one per line, Key: Value)';

  @override
  String get providerCustomHeadersInvalid =>
      'Custom headers contain lines without a colon; they will be lost when leaving';

  @override
  String get providerDebug => 'Debug';

  @override
  String providerDeleteConfirm(String name) {
    return '';
  }

  @override
  String get providerDeleteTitle => 'Delete provider';

  @override
  String get providerEdit => 'Provider settings';

  @override
  String get providerEmpty => 'No providers yet, tap + to add';

  @override
  String get providerImportHint => 'Paste the shared provider text…';

  @override
  String get providerImportInvalid => 'Could not parse this text';

  @override
  String get providerImportTitle => 'Import provider';

  @override
  String get providerLatencyExcellent => 'Excellent';

  @override
  String get providerLatencyGood => 'Good';

  @override
  String get providerLatencyRecord => 'Latency records';

  @override
  String get providerLatencySlow => 'Slow';

  @override
  String get providerModel => 'Model';

  @override
  String get providerModelSettings => 'Models';

  @override
  String providerModelsCount(int count) {
    return '$count models';
  }

  @override
  String get providerModelsEmpty =>
      'No models yet. Tap \"Add model\"\\nto enter a model ID manually or fetch from /models';

  @override
  String get providerMultimodal => 'Multimodal';

  @override
  String get providerMultimodalHint =>
      'Supports images, files and other non-text input';

  @override
  String get providerName => 'Provider name';

  @override
  String get providerNameHint => 'e.g. OpenAI';

  @override
  String get providerBaseUrl => 'Base URL';

  @override
  String get providerSaveFailed => 'Save failed. Please try again';

  @override
  String get providerBaseUrlHint => 'e.g. https://api.openai.com/v1';

  @override
  String get providerApiKey => 'API Key';

  @override
  String get providerApiKeyHint => 'sk-…';

  @override
  String get providerProtocol => 'Protocol';

  @override
  String get providerProtocolAuto => 'Auto (detect by URL)';

  @override
  String get providerReasoning => 'Reasoning';

  @override
  String get providerReasoningHint =>
      'Enables deep reasoning (e.g. o1, o3 series)';

  @override
  String providerRemoveModelConfirm(String id) {
    return '';
  }

  @override
  String get providerRemoveModelTitle => 'Remove model';

  @override
  String get providerShareHint =>
      'Copy the text below to share this provider config (includes API key):';

  @override
  String get providerShareTitle => 'Share provider';

  @override
  String get providerTest => 'Test';

  @override
  String get providerTestAgain => 'Retest';

  @override
  String providerTestFailedDetail(String error) {
    return '';
  }

  @override
  String get providerTesting => 'Testing…';

  @override
  String get providerTitle => 'Providers';

  @override
  String get providerUnconfiguredModel => 'No model configured';

  @override
  String get searchHint => 'Type keywords to search all sessions';

  @override
  String searchNoResult(String query) {
    return '';
  }

  @override
  String get searchTitle => 'Search sessions & messages…';

  @override
  String get searchTitleHit => 'Title match';

  @override
  String get settingsAbout => 'About Nona';

  @override
  String get settingsAboutSubtitle => 'Version / GitHub / License';

  @override
  String get settingsAgents => 'Agents';

  @override
  String settingsAgentsSubtitle(int count) {
    return '$count agents';
  }

  @override
  String get settingsAllExist => 'All sessions already exist, nothing added';

  @override
  String get settingsClearAll => 'Clear all sessions';

  @override
  String settingsClearAllSubtitle(int count) {
    return 'Will delete all $count sessions';
  }

  @override
  String get settingsClearAllSubtitleEmpty => 'No saved sessions';

  @override
  String settingsClearConfirmContent(int count) {
    return 'This will delete all $count sessions and cannot be undone.';
  }

  @override
  String get settingsClearConfirmTitle => 'Clear all sessions';

  @override
  String get settingsCleared => 'All sessions cleared';

  @override
  String get settingsCompareSubtitle =>
      'Compare multiple models on one question';

  @override
  String get settingsDevOptions => 'Developer options';

  @override
  String get settingsDevOptionsSubtitle =>
      'Advanced connectivity / capability table';

  @override
  String get settingsExportAll => 'Export all sessions';

  @override
  String get settingsExportAllSubtitle => 'Back up as JSON, restorable anytime';

  @override
  String settingsExportFailed(Object error) {
    return 'Export failed: $error';
  }

  @override
  String settingsExportedAll(String path) {
    return '';
  }

  @override
  String get settingsFooter =>
      'Nona · Local first, all data stays on this device';

  @override
  String get settingsImport => 'Import sessions';

  @override
  String get settingsImportFailed => 'Import failed: invalid file format';

  @override
  String get settingsImportSubtitle =>
      'Import from Nona / Chatbox / Cherry / NextChat / ChatGPT / RikkaHub / Kelivo';

  @override
  String settingsImported(int count) {
    return 'Imported $count sessions';
  }

  @override
  String get settingsKbSubtitle => 'Local knowledge base, auto-retrieved';

  @override
  String get settingsMcpSubtitle => 'MCP tool servers';

  @override
  String get settingsModelConfig => 'Model config';

  @override
  String get settingsModelConfigSubtitle => 'Chat model · Title model';

  @override
  String get settingsNoExportable => 'No sessions to export';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsPreferencesEnterNewline =>
      'Enter for newline, Ctrl+Enter to send';

  @override
  String get settingsPreferencesEnterSend =>
      'Enter to send, Shift+Enter for newline';

  @override
  String get settingsProviders => 'Providers';

  @override
  String settingsProvidersSubtitle(int providers, int models) {
    return '\$providers providers · $models models';
  }

  @override
  String get settingsProvidersSubtitleEmpty =>
      'Not configured, add a provider and fetch models';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsSectionIntegrations => 'Integration & Sync';

  @override
  String get settingsSectionMemory => 'Memory & Context';

  @override
  String get settingsSectionModels => 'Models & Agents';

  @override
  String get settingsSectionPreferences => 'Preferences';

  @override
  String get settingsSectionTools => 'Tools & Enhancements';

  @override
  String get settingsSyncSubtitle => 'WebDAV / S3 backup sync';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTranslatorSubtitle => 'Translate text with AI';

  @override
  String get sidebarAnonymous => 'Anonymous session (not saved)';

  @override
  String get sidebarAnonymousActive => 'Anonymous session in progress';

  @override
  String get sidebarAnonymousHint =>
      'Conversation is kept in memory only,\\nno records after closing the app';

  @override
  String get sidebarBrandSubtitle => 'AI Chat Assistant';

  @override
  String get sidebarDuplicate => 'Duplicate session';

  @override
  String get sidebarEarlier => 'Earlier';

  @override
  String get sidebarExitAnonymous => 'Exit anonymous';

  @override
  String get sidebarExitAnonymousConfirm => 'Exit anonymous session';

  @override
  String get sidebarNewSessionAgent => 'New chat / choose Agent';

  @override
  String get sidebarNewWithAgent => 'New chat with Agent';

  @override
  String get sidebarNoMatch => 'No matching sessions';

  @override
  String get sidebarNoSessions => 'No sessions';

  @override
  String get sidebarPin => 'Pin';

  @override
  String get sidebarRename => 'Rename';

  @override
  String get sidebarSearchHint => 'Search sessions & messages…';

  @override
  String get sidebarSessionActions => 'Session actions';

  @override
  String get sidebarToday => 'Today';

  @override
  String get sidebarUnpin => 'Unpin';

  @override
  String get sidebarYesterday => 'Yesterday';

  @override
  String get syncBackupList => 'Cloud backups';

  @override
  String get syncEmpty => 'No backups yet. Tap Upload to create one';

  @override
  String syncRestoreConfirm(String name) {
    return '';
  }

  @override
  String get syncRestoreTitle => 'Restore backup';

  @override
  String syncRestored(int count) {
    return 'Restored $count new sessions';
  }

  @override
  String get syncS3Access => 'Access Key';

  @override
  String get syncS3Bucket => 'Bucket';

  @override
  String get syncS3Endpoint => 'S3 Endpoint';

  @override
  String get syncS3Region => 'Region';

  @override
  String get syncS3Secret => 'Secret Key';

  @override
  String get syncTitle => 'Cloud Sync';

  @override
  String get statsTitle => 'Stats Dashboard';

  @override
  String get settingsStatsSubtitle => 'Token usage, model ranking and cost';

  @override
  String get memoryTitle => 'Memories';

  @override
  String get settingsMemorySubtitle => 'Long-term memories, auto-extracted';

  @override
  String get memoryAdd => 'Add memory';

  @override
  String get memoryContentHint => 'Content to remember long-term';

  @override
  String get memoryEdit => 'Edit memory';

  @override
  String get memoryDeleteConfirm => 'Delete this memory?';

  @override
  String get memoryScopeGlobal => 'Global';

  @override
  String get memoryScopeAgent => 'Agent';

  @override
  String get memoryScopeSession => 'Session';

  @override
  String get memoryEmpty =>
      'No memories yet; auto-extraction runs every 10 turns';

  @override
  String get memoryPin => 'Pin';

  @override
  String get settingsWbSubtitle =>
      'World book: keyword-triggered lore injection';

  @override
  String get importTitle => 'Import Data';

  @override
  String get imgGenTitle => 'Image Generation';

  @override
  String get settingsImgGenSubtitle =>
      'Generate images with AI (image-gen capable provider)';

  @override
  String get ocrAction => 'Extract text';

  @override
  String get ocrProcessing => 'Extracting text from image…';

  @override
  String get ocrNoVisionModel =>
      'No multimodal (vision) model available in the current provider';

  @override
  String get ocrDone => 'Text extracted; image replaced with text message';

  @override
  String ocrFailed(Object error) {
    return 'OCR failed: $error';
  }

  @override
  String get imgGenProvider => 'Provider (image-gen capable)';

  @override
  String get imgGenPrompt => 'Prompt';

  @override
  String get imgGenPromptHint => 'Describe the image you want';

  @override
  String get imgGenSize => 'Size';

  @override
  String get imgGenCount => 'Count';

  @override
  String get imgGenGenerate => 'Generate';

  @override
  String get imgGenGenerating => 'Generating…';

  @override
  String get imgGenEmpty => 'No history yet; type a prompt to start';

  @override
  String get importPickHint =>
      'Pick a backup file (Nona / Chatbox / Cherry / NextChat / ChatGPT / RikkaHub / Kelivo)';

  @override
  String get importPick => 'Pick file';

  @override
  String get importConfirm => 'Confirm import';

  @override
  String importFormat(Object format) {
    return 'Detected format: $format';
  }

  @override
  String importPreview(Object messages, Object sessions) {
    return 'Preview: $sessions sessions, $messages messages';
  }

  @override
  String get importFailed => 'Import failed, check the file format';

  @override
  String importResultOk(Object count) {
    return 'Imported $count new sessions';
  }

  @override
  String importResultPartial(Object count, Object failed) {
    return 'Imported $count sessions, $failed records skipped';
  }

  @override
  String get wbTitle => 'World Book';

  @override
  String get wbAdd => 'New entry';

  @override
  String get wbEdit => 'Edit entry';

  @override
  String get wbImport => 'Import JSON';

  @override
  String get wbExport => 'Export JSON';

  @override
  String get wbEmpty => 'No entries yet; tap + to create';

  @override
  String wbDeleteConfirm(Object title) {
    return 'Delete world book entry \"$title\"?';
  }

  @override
  String wbImported(Object count) {
    return 'Imported $count entries';
  }

  @override
  String get wbImportFailed => 'Import failed: invalid JSON';

  @override
  String get wbTitleField => 'Title';

  @override
  String get wbKeywordsField => 'Trigger keywords';

  @override
  String get wbKeywordsHint =>
      'Comma separated; any keyword in a message triggers';

  @override
  String get wbContentField => 'Content';

  @override
  String get wbPriorityField => 'Priority';

  @override
  String get wbScanDepthField => 'Scan depth';

  @override
  String get wbPositionField => 'Injection position';

  @override
  String get wbCaseSensitive => 'Case-sensitive keywords';

  @override
  String get wbConstantActive => 'Always active';

  @override
  String get wbUntitled => 'Untitled entry';

  @override
  String statsBudgetWarning(Object percent) {
    return 'Monthly budget $percent% used, watch your usage';
  }

  @override
  String get statsBudgetBlocked =>
      'Monthly budget exceeded, send blocked (adjust budget in Stats)';

  @override
  String get statsBudgetWarningTitle => 'Monthly budget exhausted';

  @override
  String get statsBudgetWarningBody =>
      'Sending will exceed the monthly budget. Continue?';

  @override
  String get statsBudgetOverride => 'Send anyway';

  @override
  String get statsRefresh => 'Refresh';

  @override
  String get statsDailyTokens => 'Daily tokens (bottom: input / top: output)';

  @override
  String get statsEmpty => 'No data yet';

  @override
  String get statsCostTrend => 'Token trend';

  @override
  String get statsTopModels => 'Top 10 models';

  @override
  String get statsTopSessions => 'Top 10 sessions';

  @override
  String get statsTotalTokens => 'Total tokens';

  @override
  String get statsTotalCost => 'Total cost (USD)';

  @override
  String get syncTypeS3 => 'S3';

  @override
  String get syncTypeWebDav => 'WebDAV';

  @override
  String get syncErrorAuth => 'Authentication failed. Check your credentials';

  @override
  String get syncErrorNetwork =>
      'Network error. Check your connection and retry';

  @override
  String get syncErrorStorage =>
      'Storage service error. Check your configuration';

  @override
  String get syncUpload => 'Upload backup';

  @override
  String syncUploaded(String name) {
    return '';
  }

  @override
  String get syncWebDavPass => 'Password';

  @override
  String get syncWebDavUrl => 'WebDAV URL';

  @override
  String get syncWebDavUser => 'Username';

  @override
  String get themeAccentSection => 'Accent color';

  @override
  String get themeCustom => 'Custom';

  @override
  String get themeCustomColor => 'Custom color';

  @override
  String get themeCustomTitle => 'Custom accent color';

  @override
  String get themeDarkSection => 'Dark mode';

  @override
  String get themeHue => 'Hue';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeSection => 'Appearance mode';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeOledSubtitle =>
      'Use pure black in dark mode for OLED screens, saves power';

  @override
  String get themeOledTitle => 'OLED pure black background';

  @override
  String get themeSaturation => 'Saturation';

  @override
  String get themeTitle => 'Theme settings';

  @override
  String get themeValue => 'Brightness';

  @override
  String get translatorFailed => 'Translation failed, please retry';

  @override
  String get translatorNoModel =>
      'Set a default chat model in Model Settings first';

  @override
  String get translatorResult => 'Translation';

  @override
  String get translatorSourceHint => 'Enter text to translate…';

  @override
  String get translatorTarget => 'Target language';

  @override
  String get unitsMb => 'MB';

  @override
  String get unitsKb => 'KB';

  @override
  String get unitsB => 'B';

  @override
  String get translatorLangEn => 'English';

  @override
  String get translatorLangZh => 'Chinese';

  @override
  String get translatorLangJa => '日本語';

  @override
  String get translatorLangKo => '한국어';

  @override
  String get translatorLangFr => 'Français';

  @override
  String get translatorLangDe => 'Deutsch';

  @override
  String get translatorLangEs => 'Español';

  @override
  String get translatorLangRu => 'Русский';

  @override
  String translatorPrompt(String target, String source) {
    return 'Translate the following into $target. Output only the translation:\n\n$source';
  }

  @override
  String get translatorTitle => 'AI Translator';

  @override
  String get translatorTranslate => 'Translate';

  @override
  String get translatorTranslating => 'Translating…';

  @override
  String get chatSuggestionTitle => 'You can start with';

  @override
  String get chatSuggestionStart =>
      'Introduce yourself, including capabilities and limits';

  @override
  String get chatSuggestionFiles =>
      'How do I upload documents and get summaries?';

  @override
  String get chatSuggestionMcp =>
      'What configuration is needed to connect external tools?';

  @override
  String get chatMoreActions => 'More actions';

  @override
  String get chatSelectCopy => 'Select & copy';

  @override
  String get chatExportImage => 'Export image';

  @override
  String get chatExportSelectedImage => 'Export as image';

  @override
  String get chatExportJsonl => 'Export JSONL';

  @override
  String get chatLongImageCapturing => 'Rendering long image…';

  @override
  String get chatLongImageDone => 'Long image exported';

  @override
  String get chatSelectCopyHint =>
      'Select text then copy; optionally send with context';

  @override
  String get chatCopyWithContext => 'Copy & send with context';

  @override
  String get chatNoSelection => 'No text selected';

  @override
  String get contextManageTitle => 'Context management';

  @override
  String get contextSegments => 'Injected segments';

  @override
  String contextSegmentTokens(String tokens) {
    return '$tokens tokens';
  }

  @override
  String get contextSegmentSystem => 'System prompt';

  @override
  String get contextSegmentMemory => 'Memory';

  @override
  String get contextSegmentKnowledge => 'Knowledge base';

  @override
  String get contextSegmentSearch => 'Search results';

  @override
  String get contextSegmentWorldBook => 'World book';

  @override
  String get contextSegmentHistory => 'History';

  @override
  String get contextSegmentSummary => 'Session summary';

  @override
  String get contextSegmentInjection => 'Instruction injections';

  @override
  String get contextSegmentAgent => 'Agent prompt';

  @override
  String contextUsedTokens(String limit, String used) {
    return 'Used $used / limit $limit';
  }

  @override
  String get contextNoLimit => 'No limit set';

  @override
  String get contextCompress => 'Compress context';

  @override
  String get contextCompressHint => 'Summarize and fold history';

  @override
  String get contextClear => 'Clear context';

  @override
  String get contextClearHint =>
      'Mark truncation point; history is recoverable';

  @override
  String get contextRestore => 'Restore cleared context';

  @override
  String get contextCompressing => 'Compressing…';

  @override
  String get contextCompressDone =>
      'Context compressed; new messages start with the summary';

  @override
  String get contextToggleOffHint => 'Segment disabled for next request only';

  @override
  String get contextEnabled => 'Enabled';

  @override
  String get contextDisabled => 'Disabled';

  @override
  String get providerUseResponseApi => 'Use Responses API';

  @override
  String get providerUseResponseApiHint =>
      'For o1/o3/o4/gpt-5 series; keep off for ChatCompletions-compatible providers';

  @override
  String get providerAuthMode => 'Auth mode';

  @override
  String get providerAuthApiKey => 'API Key';

  @override
  String get providerAuthServiceAccount => 'Service Account (Vertex)';

  @override
  String get providerSaProjectId => 'Project ID';

  @override
  String get providerSaRegion => 'Region';

  @override
  String get providerSaEmail => 'Service Account email';

  @override
  String get providerSaKeyFile => 'Select SA JSON key file';

  @override
  String get providerSaKeyPaste => 'Paste SA JSON';

  @override
  String get providerSaInvalid =>
      'Invalid SA JSON: missing client_email/private_key/project_id';

  @override
  String get providerVertexHint =>
      'Bearer token is used when baseUrl contains aiplatform';

  @override
  String get providerGroupUngrouped => 'Ungrouped';

  @override
  String get providerGroupAll => 'All';

  @override
  String get providerGroupAdd => 'New group';

  @override
  String get providerGroupName => 'Group name';

  @override
  String get providerGroupRename => 'Rename';

  @override
  String get providerGroupDelete => 'Delete group';

  @override
  String get providerGroupEmpty => 'No groups yet';

  @override
  String get providerKeysTitle => 'API Keys';

  @override
  String get providerKeysBatchAdd => 'Add keys (one per line)';

  @override
  String get providerKeysTest => 'Test';

  @override
  String get providerKeysTesting => 'Testing…';

  @override
  String get providerKeysStatusActive => 'Active';

  @override
  String get providerKeysStatusCooling => 'Cooling down';

  @override
  String providerKeysStatusError(String count) {
    return 'Failed $count times';
  }

  @override
  String get providerKeysStatusDisabled => 'Disabled (consecutive failures)';

  @override
  String get providerKeysEnable => 'Enable';

  @override
  String get providerKeysDisable => 'Disable';

  @override
  String get providerKeysNone => 'No keys yet';

  @override
  String get providerKeysCopied => 'Copied (may expose to clipboard)';

  @override
  String get providerKeysTestOk => 'Test passed';

  @override
  String providerKeysTestFail(String detail) {
    return 'Test failed: $detail';
  }

  @override
  String get providerKeysRemoved => 'Key removed';

  @override
  String get imggenSize => 'Size';

  @override
  String get imggenQuality => 'Quality';

  @override
  String get imggenCount => 'Count';

  @override
  String get imggenSendToChat => 'Send to chat';

  @override
  String get imggenHistory => 'History';

  @override
  String get imggenHistoryEmpty => 'No generation history';

  @override
  String get modelSearch => 'Search models';

  @override
  String get modelFilterMultimodal => 'Multimodal';

  @override
  String get modelFilterReasoning => 'Reasoning';

  @override
  String modelContextWindow(String window) {
    return 'Context $window';
  }

  @override
  String modelPrice(String price) {
    return '\$$price/M';
  }

  @override
  String get modelNoCapability => 'Unknown capabilities';

  @override
  String get searchServicesTitle => 'Search services';

  @override
  String get searchServiceEnabled => 'Enabled';

  @override
  String get searchServiceKey => 'API Key';

  @override
  String get searchServiceTest => 'Test';

  @override
  String get searchServiceTesting => 'Testing…';

  @override
  String searchServiceTestOk(String count) {
    return 'Got $count results';
  }

  @override
  String searchServiceTestFail(String detail) {
    return 'Test failed: $detail';
  }

  @override
  String get searchServiceNeedKey => 'API key required';

  @override
  String get searchServiceNoKey => 'No key required';

  @override
  String get searchServiceSelected => 'In use';

  @override
  String get searchServiceUsageTitle => 'Search usage';

  @override
  String searchServiceCalls(String count) {
    return '$count calls';
  }

  @override
  String get searchNoKeyFallback =>
      'No key configured; falling back to Bing free engine';

  @override
  String get searchFilterTime => 'Time range';

  @override
  String get searchFilterProvider => 'Provider';

  @override
  String get searchFilterModel => 'Model';

  @override
  String get searchFilterAll => 'All';

  @override
  String get searchFilterToday => 'Today';

  @override
  String get searchFilterWeek => 'Last 7 days';

  @override
  String get searchFilterMonth => 'Last 30 days';

  @override
  String get searchFilterYear => 'Last year';

  @override
  String get searchExportResults => 'Export results';

  @override
  String searchExported(String count) {
    return 'Exported $count results';
  }

  @override
  String get kbDebugTitle => 'Retrieval test bench';

  @override
  String get kbDebugQuery => 'Query';

  @override
  String get kbDebugTopK => 'Top K';

  @override
  String get kbDebugSimilarity => 'Similarity threshold';

  @override
  String get kbDebugChunkSize => 'Chunk size (override, not persisted)';

  @override
  String kbDebugVectorHits(String count) {
    return 'Vector hits $count';
  }

  @override
  String kbDebugBigramHits(String count) {
    return 'Bigram hits $count';
  }

  @override
  String get kbDebugNoHits => 'No hits';

  @override
  String kbDebugScore(String score) {
    return 'Score $score';
  }

  @override
  String kbDebugSource(String source) {
    return 'Source: $source';
  }

  @override
  String kbDebugDocId(String id) {
    return 'Document $id';
  }

  @override
  String kbDebugRank(String rank) {
    return 'Rank #$rank';
  }

  @override
  String get worldBookNewBook => 'New world book';

  @override
  String get worldBookName => 'Name';

  @override
  String get worldBookDescription => 'Description';

  @override
  String get worldBookActive => 'Active';

  @override
  String get worldBookActivateForAgent => 'Activate for agent';

  @override
  String get worldBookHitTest => 'Hit test';

  @override
  String get worldBookHitTestInput => 'Type text to test matching';

  @override
  String get worldBookHitTestNoHit => 'No entries matched';

  @override
  String worldBookHitTestHit(String chars, String count) {
    return 'Matched $count entries, $chars chars injected';
  }

  @override
  String get worldBookGlobal => 'Global';

  @override
  String get voiceServicesTitle => 'Voice services';

  @override
  String get voiceTtsSystem => 'System TTS';

  @override
  String get voiceTtsProviders => 'Network TTS';

  @override
  String get voiceTtsProviderName => 'Provider';

  @override
  String get voiceTtsVoice => 'Voice';

  @override
  String get voiceTtsRate => 'Rate';

  @override
  String get voiceTtsModel => 'Model';

  @override
  String get voiceTtsPreview => 'Preview';

  @override
  String get voiceTtsPreviewing => 'Previewing…';

  @override
  String get voiceTtsAddProvider => 'Add TTS provider';

  @override
  String get voiceTtsTestOk => 'Preview finished';

  @override
  String voiceTtsTestFail(String detail) {
    return 'Preview failed: $detail';
  }

  @override
  String get voiceTtsFallbackSystem => 'Falling back to system TTS';

  @override
  String get voiceAsrTitle => 'Speech input (ASR)';

  @override
  String get voiceAsrSystem => 'System speech recognition';

  @override
  String get voiceAsrCloud => 'Cloud ASR';

  @override
  String get voiceAsrLocal => 'Local offline ASR';

  @override
  String get voiceAsrListening => 'Listening…';

  @override
  String get voiceAsrDone => 'Recognition done';

  @override
  String get voiceAsrCancelled => 'Cancelled';

  @override
  String get voiceAsrNoPermission => 'Microphone permission denied';

  @override
  String voiceAsrError(String detail) {
    return 'Recognition failed: $detail';
  }

  @override
  String get voiceAsrUnavailable => 'Speech input unavailable on this platform';

  @override
  String get voiceAsrTapToSpeak => 'Tap to speak';

  @override
  String get voiceModelDownload => 'Download model';

  @override
  String voiceModelDownloading(String percent) {
    return 'Downloading $percent%';
  }

  @override
  String get voiceModelInstalled => 'Installed';

  @override
  String get voiceModelDelete => 'Delete model';

  @override
  String voiceModelSize(String size) {
    return '$size';
  }

  @override
  String get mcpTransport => 'Transport';

  @override
  String get mcpTransportHttp => 'Streamable HTTP';

  @override
  String get mcpTransportSse => 'SSE';

  @override
  String get mcpTransportStdio => 'STDIO (local process)';

  @override
  String get mcpStdioCommand => 'Command';

  @override
  String get mcpStdioArgs => 'Arguments (one per line)';

  @override
  String get mcpStdioEnv => 'Environment (KEY=VALUE per line)';

  @override
  String get mcpStdioCwd => 'Working directory (optional)';

  @override
  String mcpCommandNotFound(String command) {
    return 'Command $command not found. Check PATH';
  }

  @override
  String mcpStdioStderr(String line) {
    return 'stderr: $line';
  }

  @override
  String get mcpAuthorize => 'Authorize';

  @override
  String get mcpReauthorize => 'Re-authorize';

  @override
  String get mcpAuthorized => 'Authorized';

  @override
  String get mcpNotAuthorized => 'Not authorized';

  @override
  String get mcpOAuthInProgress => 'Opening authorization page…';

  @override
  String get mcpOAuthDone => 'Authorization succeeded';

  @override
  String mcpOAuthFailed(String detail) {
    return 'Authorization failed: $detail';
  }

  @override
  String get mcpOAuthServerFound => 'Authorization server discovered';

  @override
  String get mcpOAuthTokenRefreshed => 'Token refreshed';

  @override
  String get approvalWhitelist =>
      'No-approval whitelist (tool names, one per line)';

  @override
  String get approvalBlacklist =>
      'Force-approval blacklist (tool names, one per line)';

  @override
  String get approvalTimeout => 'Approval timeout (seconds)';

  @override
  String get approvalRememberSession => 'Remember for this session';

  @override
  String get toolExecuting => 'Running';

  @override
  String get toolDone => 'Done';

  @override
  String get toolError => 'Failed';

  @override
  String get toolDetail => 'Tool details';

  @override
  String get toolArguments => 'Arguments';

  @override
  String get toolResult => 'Result';

  @override
  String get toolResultTruncated => '(result truncated)';

  @override
  String get toolApprove => 'Approve';

  @override
  String get toolReject => 'Reject';

  @override
  String get toolWaitingApproval => 'Awaiting approval';

  @override
  String get toolShowDetail => 'View details';

  @override
  String get toolHideDetail => 'Hide details';

  @override
  String get restoreModeTitle => 'Restore mode';

  @override
  String get restoreModeOverwrite => 'Overwrite (recommended)';

  @override
  String get restoreModeMerge => 'Merge (keep existing)';

  @override
  String get restoreModeHint =>
      'Overwrite replaces all local data; merge keeps existing sessions and providers';

  @override
  String get restorePreparing => 'Restoring…';

  @override
  String get restoreDone => 'Restore completed';

  @override
  String get restoreRolledBack => 'Restore failed; original data restored';

  @override
  String get restoreCorrupt => 'Backup corrupt or verification failed';

  @override
  String get restoreResume => 'Unfinished restore detected; finalizing…';

  @override
  String get shareQrTab => 'QR code';

  @override
  String get scanQrTitle => 'Scan QR code';

  @override
  String get scanQrCameraPermission =>
      'Camera permission needed to scan QR codes';

  @override
  String get scanQrInvalid => 'Unrecognized QR code content';

  @override
  String get scanQrProviderImported => 'Provider imported';

  @override
  String get tagsTitle => 'Tags';

  @override
  String get tagsAdd => 'New tag';

  @override
  String get tagsName => 'Tag name';

  @override
  String get tagsColor => 'Color';

  @override
  String get tagsApply => 'Add tag';

  @override
  String get tagsFilter => 'Filter by tag';

  @override
  String get tagsNone => 'No tags';

  @override
  String get tagsManage => 'Manage tags';

  @override
  String get statsHeatmapTitle => 'Activity heatmap';

  @override
  String get statsHeatmapLegend => 'Less → More';

  @override
  String get statsTrendTitle => 'Trend';

  @override
  String get statsRankProviders => 'Provider ranking';

  @override
  String get statsRankModels => 'Model ranking';

  @override
  String get statsRankSessions => 'Session ranking';

  @override
  String get statsViewAll => 'View all';

  @override
  String get statsRangeAllTime => 'All time';

  @override
  String get statsRangeLast30 => 'Last 30 days';

  @override
  String get statsRangePrevMonth => 'Previous month';

  @override
  String get statsRangeCustom => 'Custom';

  @override
  String statsMessages(String count) {
    return '$count messages';
  }

  @override
  String get displayFontFamily => 'UI font';

  @override
  String get displayFontSystem => 'System default';

  @override
  String get displayCodeFont => 'Code font';

  @override
  String get displayUiDensity => 'UI density';

  @override
  String get densityCompact => 'Compact';

  @override
  String get densityStandard => 'Standard';

  @override
  String get densityComfortable => 'Comfortable';

  @override
  String get displayChatFontScale => 'Chat font size';

  @override
  String get fontImportLocal => 'Import local font file';

  @override
  String get fontImported => 'Font imported';

  @override
  String get androidBackgroundMode => 'Background generation';

  @override
  String get androidBackgroundOff => 'Off';

  @override
  String get androidBackgroundOn => 'On';

  @override
  String get androidBackgroundOnNotify => 'On + notify';

  @override
  String get androidBackgroundHint =>
      'Keep generating when screen is locked or app is in background';

  @override
  String get notificationChatCompleted => 'Generation finished';

  @override
  String get notificationChatFailed => 'Generation failed';

  @override
  String get desktopAutostart => 'Launch at startup';

  @override
  String get desktopAutostartHint => 'Start Nona when you sign in';

  @override
  String desktopAutostartError(String detail) {
    return 'Failed to set autostart: $detail';
  }

  @override
  String get deeplinkChatTitle => 'From external link';

  @override
  String get devColdStartTiming => 'Cold start timings (ms)';

  @override
  String get chatOpenDocument => 'Open document';

  @override
  String contextSummaryPrompt(String source) {
    return 'Summarize the key points of the following conversation concisely, keeping conclusions, decisions and todos, within 300 words:\n\n$source';
  }

  @override
  String get providerAuthorized => 'Imported (credentials stored encrypted)';

  @override
  String get commonAuto => 'Auto';

  @override
  String kbChunkCount(String count) {
    return '$count chunks';
  }

  @override
  String get ttsSpeakSelection => 'Speak selection';

  @override
  String get ttsFloatingPaused => 'Paused';

  @override
  String get ttsFloatingSpeaking => 'Speaking';

  @override
  String get ttsFloatingPause => 'Pause';

  @override
  String get ttsFloatingResume => 'Resume';

  @override
  String get ttsFloatingStop => 'Stop';

  @override
  String get ttsFloatingSpeed => 'Speed';

  @override
  String get offlineBadge => 'Offline';

  @override
  String get voiceSherpaSelected => 'In use';

  @override
  String get voiceSherpaUse => 'Use';

  @override
  String get voiceSherpaNotInstalled => 'Not installed (download required)';

  @override
  String get voiceSherpaHint =>
      'Works fully offline after download: recognition runs local ONNX inference, no audio leaves your device.';
}
