import 'dart:async';

import '../models/api_config.dart';
import '../models/prompt_context_entry.dart';
import 'openai_compatible_api_service.dart';

abstract class IOpenAiApiService {
  Future<List<FetchedModelInfo>> fetchModels(ResolvedApiConfig config);

  Future<ApiConnectionTestResult> testConnection(ResolvedApiConfig config);

  Future<ChatCompletionResult> createChatCompletion(
    ResolvedApiConfig config, {
    required List<Map<String, dynamic>> messages,
    Map<String, dynamic>? defaults,
    List<PromptContextEntry> contextEntries = const <PromptContextEntry>[],
    ChatCompletionCancelToken? cancellationToken,
  });

  Stream<ChatCompletionProgress> createStreamingChatCompletion(
    ResolvedApiConfig config, {
    required List<Map<String, dynamic>> messages,
    Map<String, dynamic>? defaults,
    List<PromptContextEntry> contextEntries = const <PromptContextEntry>[],
    ChatCompletionCancelToken? cancellationToken,
  });
}
