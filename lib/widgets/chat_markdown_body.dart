import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../data/app_settings.dart';

const String _quoteTokenTag = 'pinn_quote';
const String _bracketTokenTag = 'pinn_bracket';
const String _underlineTag = 'u';
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
    this.applyBodyTextColor = true,
    this.selectable = true,
  });

  final String text;
  final AppSettings settings;
  final Color textColor;
  final Color inlineCodeColor;
  final Color codeBlockColor;
  final bool applyBodyTextColor;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chatTextTheme = resolveActiveChatTextTheme(settings);
    final effectiveTextColor = applyBodyTextColor
        ? resolveBodyMessageTextColor(chatTextTheme, fallback: textColor)
        : textColor;

    final body = MarkdownBody(
      key: ValueKey<String>(_buildChatMarkdownThemeKey(settings)),
      data: formatChatMarkdownText(text),
      // SelectionArea can select across Markdown's multiple text widgets.
      selectable: false,
      inlineSyntaxes: buildChatMarkdownInlineSyntaxes(),
      builders: buildChatMarkdownBuilders(
        chatTextTheme: chatTextTheme,
        colorScheme: colorScheme,
        textColor: effectiveTextColor,
      ),
      styleSheet: buildChatMarkdownStyleSheet(
        chatTextTheme: chatTextTheme,
        colorScheme: colorScheme,
        textColor: effectiveTextColor,
        inlineCodeColor: inlineCodeColor,
        codeBlockColor: codeBlockColor,
      ),
    );

    if (!selectable) {
      return body;
    }

    return SelectionArea(child: body);
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
    _SimpleHtmlBreakSyntax(),
    _SimpleHtmlInlineSyntax(htmlTagPattern: 'b|strong', markdownTag: 'strong'),
    _SimpleHtmlInlineSyntax(htmlTagPattern: 'i|em', markdownTag: 'em'),
    _SimpleHtmlInlineSyntax(htmlTagPattern: 'u', markdownTag: _underlineTag),
    _SimpleHtmlInlineSyntax(htmlTagPattern: 's|strike|del', markdownTag: 'del'),
    _SimpleHtmlInlineSyntax(
      htmlTagPattern: 'code',
      markdownTag: 'code',
      parseChildren: false,
    ),
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
    _underlineTag: _UnderlineBuilder(),
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
    del: baseTextStyle.copyWith(decoration: TextDecoration.lineThrough),
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

String _buildChatMarkdownThemeKey(AppSettings settings) {
  final themeConfig = resolveThemeConfig(settings);
  final chatTextTheme = themeConfig.chatTextTheme;

  return <String>[
    settings.themePreset.name,
    themeConfig.useWenKaiScreenFont ? 'wenkai' : 'system',
    chatTextTheme.quoteStyle.name,
    chatTextTheme.enableMessageTextShadow ? 'shadow' : 'plain',
    chatTextTheme.bodyTextColorPaletteIndex?.toString() ?? 'body-auto',
    _buildTextStyleConfigKey(chatTextTheme.quotedTextStyle),
    _buildTextStyleConfigKey(chatTextTheme.bracketTextStyle),
    _buildTextStyleConfigKey(chatTextTheme.italicTextStyle),
    _buildTextStyleConfigKey(chatTextTheme.boldTextStyle),
  ].join('|');
}

String _buildTextStyleConfigKey(ChatTextStyleConfig config) {
  return <String>[
    config.paletteIndex.toString(),
    config.fontStyleMode.name,
    config.opacity.toStringAsFixed(3),
  ].join(':');
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

Color resolveBodyMessageTextColor(
  ChatTextThemeSettings chatTextTheme, {
  required Color fallback,
}) {
  final paletteIndex = chatTextTheme.bodyTextColorPaletteIndex;
  if (paletteIndex == null ||
      paletteIndex < 0 ||
      paletteIndex >= customThemePalette.length) {
    return fallback;
  }
  return customThemePalette[paletteIndex];
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
  var output = _transformSimpleHtmlBlocks(input);

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

String _transformSimpleHtmlBlocks(String input) {
  if (!input.contains('<')) {
    return input;
  }

  return input
      .replaceAll(RegExp(r'<(?:p|div)(?:\s+[^>]*)?>', caseSensitive: false), '')
      .replaceAll(RegExp(r'</(?:p|div)\s*>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<hr\s*/?>', caseSensitive: false), '\n\n---\n\n');
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
  //RegExp(r'‘([^‘’\n]+)’'),
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

class _SimpleHtmlBreakSyntax extends md.InlineSyntax {
  _SimpleHtmlBreakSyntax()
    : super(r'<br\s*/?>', caseSensitive: false, startCharacter: _lessThanCode);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.empty('br'));
    return true;
  }
}

class _SimpleHtmlInlineSyntax extends md.InlineSyntax {
  _SimpleHtmlInlineSyntax({
    required String htmlTagPattern,
    required this.markdownTag,
    this.parseChildren = true,
  }) : super(
         '<($htmlTagPattern)(?:\\s+[^>]*)?>([\\s\\S]*?)</\\1\\s*>',
         caseSensitive: false,
         startCharacter: _lessThanCode,
       );

  final String markdownTag;
  final bool parseChildren;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match.group(2) ?? '';
    final children = parseChildren
        ? parser.document.parseInline(content)
        : <md.Node>[md.Text(content)];

    parser.addNode(md.Element(markdownTag, children));
    return true;
  }
}

const int _lessThanCode = 60;

class _UnderlineBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final style = (parentStyle ?? preferredStyle ?? const TextStyle()).copyWith(
      decoration: TextDecoration.underline,
    );

    return Text.rich(TextSpan(text: element.textContent, style: style));
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
