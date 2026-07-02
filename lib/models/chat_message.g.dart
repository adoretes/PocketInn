// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  id: json['id'] as String?,
  sessionId: json['sessionId'] as String?,
  parentId: json['parentId'] as String?,
  text: json['text'] as String,
  isMe: json['isMe'] as bool,
  index: (json['index'] as num?)?.toInt() ?? 1,
  total: (json['total'] as num?)?.toInt() ?? 1,
  siblingIds:
      (json['siblingIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  thinkingChain: json['thinkingChain'] as String?,
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'parentId': instance.parentId,
      'text': instance.text,
      'isMe': instance.isMe,
      'index': instance.index,
      'total': instance.total,
      'siblingIds': instance.siblingIds,
      'thinkingChain': instance.thinkingChain,
    };
