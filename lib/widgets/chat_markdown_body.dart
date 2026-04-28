import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../data/app_settings.dart';

const String _quoteTokenTag = 'pinn_quote';
const String _bracketTokenTag = 'pinn_bracket';
const String _quoteTokenPattern = r'%%PINN_Q:([-_A-Za-z0-9=]+)%%';
const String _bracketTokenPattern = r'%%PINN_B:([-_A-Za-z0-9=]+)%%';

class ChatMarkdownBody extends StatelessWidget {
  const ChatMarkdownBody({
    super.key,
    required this.text,
    required this.settings,
    required this.textColor,
    required this.inlineCodeColor,
    required this.codeBlockColor,
    this.selectable = true,
  });

  final String text;
  final AppSettings settings;
  final Color textColor;
  final Color inlineCodeColor;
  final Color codeBlockColor;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chatTextTheme = resolveActiveChatTextTheme(settings);

    return MarkdownBody(
      data: formatChatMarkdownText(text),
      selectable: selectable,
      inlineSyntaxes: buildChatMarkdownInlineSyntaxes(),
      builders: buildChatMarkdownBuilders(
        chatTextTheme: chatTextTheme,
        colorScheme: colorScheme,
        textColor: textColor,
      ),
      styleSheet: buildChatMarkdownStyleSheet(
        chatTextTheme: chatTextTheme,
        colorScheme: colorScheme,
        textColor: textColor,
        inlineCodeColor: inlineCodeColor,
        codeBlockColor: codeBlockColor,
      ),
    );
  }
}

String formatChatMarkdownText(String input) {
  if (input.isEmpty) {
    return input;
  }

  final protectedPattern = RegExp(r'```[\s\S]*?```|`[^`\n]+`', dotAll: true);
  final buffer = StringBuffer();
  var cursor = 0;

  for (final match in protectedPattern.allMatches(input)) {
    if (match.start > cursor) {
      buffer.write(
        _transformStyledSegments(input.substring(cursor, match.start)),
      );
    }
    buffer.write(match.group(0));
    cursor = match.end;
  }

  if (cursor < input.length) {
    buffer.write(_transformStyledSegments(input.substring(cursor)));
  }

  return buffer.toString();
}

List<md.InlineSyntax> buildChatMarkdownInlineSyntaxes() {
  return <md.InlineSyntax>[
    _InlineTokenSyntax(_quoteTokenPattern, _quoteTokenTag),
    _InlineTokenSyntax(_bracketTokenPattern, _bracketTokenTag),
  ];
}

Map<String, MarkdownElementBuilder> buildChatMarkdownBuilders({
  required ChatTextThemeSettings chatTextTheme,
  required ColorScheme colorScheme,
  required Color textColor,
}) {
  return <String, MarkdownElementBuilder>{
    _quoteTokenTag: _QuoteTokenBuilder(
      chatTextTheme: chatTextTheme,
      colorScheme: colorScheme,
      textColor: textColor,
    ),
    _bracketTokenTag: _BracketTokenBuilder(
      chatTextTheme: chatTextTheme,
      colorScheme: colorScheme,
      textColor: textColor,
    ),
  };
}

MarkdownStyleSheet buildChatMarkdownStyleSheet({
  required ChatTextThemeSettings chatTextTheme,
  required ColorScheme colorScheme,
  required Color textColor,
  required Color inlineCodeColor,
  required Color codeBlockColor,
}) {
  final baseTextStyle = buildBaseMessageTextStyle(
    textColor: textColor,
    brightness: colorScheme.brightness,
    enableShadow: chatTextTheme.enableMessageTextShadow,
  );

  return MarkdownStyleSheet(
    p: baseTextStyle,
    em: buildDecoratedChatTextStyle(
      baseStyle: baseTextStyle,
      config: chatTextTheme.italicTextStyle,
    ),
    strong: buildDecoratedChatTextStyle(
      baseStyle: baseTextStyle,
      config: chatTextTheme.boldTextStyle,
    ),
    del: baseTextStyle.copyWith(decoration: TextDecoration.none),
    code: TextStyle(
      fontSize: 14,
      height: 1.45,
      color: textColor,
      backgroundColor: inlineCodeColor,
      fontFamily: 'monospace',
    ),
    codeblockDecoration: BoxDecoration(
      color: codeBlockColor,
      borderRadius: BorderRadius.circular(8),
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: textColor.withValues(alpha: 0.25), width: 0.3),
      ),
    ),
  );
}

TextStyle buildBaseMessageTextStyle({
  required Color textColor,
  required Brightness brightness,
  required bool enableShadow,
}) {
  return TextStyle(
    fontSize: 15,
    height: 1.5,
    color: textColor,
    shadows: enableShadow ? _buildMessageTextShadows(brightness) : null,
  );
}

TextStyle buildDecoratedChatTextStyle({
  required TextStyle baseStyle,
  required ChatTextStyleConfig config,
}) {
  final paletteIndex = config.paletteIndex.clamp(
    0,
    customThemePalette.length - 1,
  );
  var textStyle = baseStyle.copyWith(
    color: customThemePalette[paletteIndex].withValues(alpha: config.opacity),
  );

  switch (config.fontStyleMode) {
    case ChatTextFontStyleMode.platform:
      return textStyle.copyWith(
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.normal,
        letterSpacing: 0,
      );
    case ChatTextFontStyleMode.italic:
      return textStyle.copyWith(
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.normal,
      );
    case ChatTextFontStyleMode.bold:
      return textStyle.copyWith(
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
      );
  }
}

String _transformStyledSegments(String input) {
  var output = input;

  for (final pattern in _quotePatterns) {
    output = output.replaceAllMapped(pattern, (match) {
      final content = match.group(1)?.trim();
      if (content == null || content.isEmpty) {
        return match.group(0) ?? '';
      }
      return _buildInlineToken(_quoteTokenTag, content);
    });
  }

  for (final pattern in _bracketPatterns) {
    output = output.replaceAllMapped(pattern, (match) {
      final content = match.group(1)?.trim();
      if (content == null || content.isEmpty) {
        return match.group(0) ?? '';
      }
      return _buildInlineToken(_bracketTokenTag, content);
    });
  }

  return output;
}

String _buildInlineToken(String tag, String content) {
  final encoded = base64Url.encode(utf8.encode(content));
  return switch (tag) {
    _quoteTokenTag => '%%PINN_Q:$encoded%%',
    _bracketTokenTag => '%%PINN_B:$encoded%%',
    _ => content,
  };
}

List<Shadow> _buildMessageTextShadows(Brightness brightness) {
  final shadowColor = brightness == Brightness.dark
      ? Colors.black.withValues(alpha: 0.34)
      : Colors.black.withValues(alpha: 0.16);

  return <Shadow>[
    Shadow(color: shadowColor, blurRadius: 2.5, offset: const Offset(0, 1)),
  ];
}

final List<RegExp> _quotePatterns = <RegExp>[
  RegExp(r'“([^“”\n]+)”'),
  RegExp(r'‘([^‘’\n]+)’'),
  RegExp(r'「([^「」\n]+)」'),
  RegExp(r'『([^『』\n]+)』'),
  RegExp(r'(?<!\w)"([^"\n]+)"(?!\w)'),
];

final List<RegExp> _bracketPatterns = <RegExp>[
  RegExp(r'[（(]([^()（）\n]+)[)）]'),
  RegExp(r'[【\[]([^\[\]【】\n]+)[】\]]'),
];

class _InlineTokenSyntax extends md.InlineSyntax {
  _InlineTokenSyntax(super.pattern, this.tag);

  final String tag;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final encoded = match.group(1);
    if (encoded == null || encoded.isEmpty) {
      return false;
    }

    parser.addNode(
      md.Element.text(tag, utf8.decode(base64Url.decode(encoded))),
    );
    return true;
  }
}

class _QuoteTokenBuilder extends MarkdownElementBuilder {
  _QuoteTokenBuilder({
    required this.chatTextTheme,
    required this.colorScheme,
    required this.textColor,
  });

  final ChatTextThemeSettings chatTextTheme;
  final ColorScheme colorScheme;
  final Color textColor;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final baseStyle =
        parentStyle ??
        preferredStyle ??
        buildBaseMessageTextStyle(
          textColor: textColor,
          brightness: colorScheme.brightness,
          enableShadow: chatTextTheme.enableMessageTextShadow,
        );
    final contentStyle = buildDecoratedChatTextStyle(
      baseStyle: baseStyle,
      config: chatTextTheme.quotedTextStyle,
    );
    final quoteStyle = baseStyle.copyWith(
      color: contentStyle.color,
      fontWeight: contentStyle.fontWeight,
      fontStyle: contentStyle.fontStyle,
    );

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: chatTextTheme.quoteStyle.leading, style: quoteStyle),
          TextSpan(text: element.textContent, style: contentStyle),
          TextSpan(text: chatTextTheme.quoteStyle.trailing, style: quoteStyle),
        ],
      ),
    );
  }
}

class _BracketTokenBuilder extends MarkdownElementBuilder {
  _BracketTokenBuilder({
    required this.chatTextTheme,
    required this.colorScheme,
    required this.textColor,
  });

  final ChatTextThemeSettings chatTextTheme;
  final ColorScheme colorScheme;
  final Color textColor;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final baseStyle =
        parentStyle ??
        preferredStyle ??
        buildBaseMessageTextStyle(
          textColor: textColor,
          brightness: colorScheme.brightness,
          enableShadow: chatTextTheme.enableMessageTextShadow,
        );
    final contentStyle = buildDecoratedChatTextStyle(
      baseStyle: baseStyle,
      config: chatTextTheme.bracketTextStyle,
    );

    return Text.rich(TextSpan(text: element.textContent, style: contentStyle));
  }
}
