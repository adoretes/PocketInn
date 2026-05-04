import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:pocket_inn/widgets/chat_markdown_body.dart';

void main() {
  group('ChatMarkdownBody HTML tags', () {
    test('parses simple inline html tags into markdown elements', () {
      final tags = _elementTags(
        _parseChatMarkdown(
          'hello <b>bold</b> <strong>strong</strong> '
          '<i>italic</i> <em>em</em> <u>under</u> '
          '<s>gone</s> <strike>strike</strike> <del>del</del>'
          '<br><code>plain **code**</code>',
        ),
      );

      expect(tags.where((tag) => tag == 'strong'), hasLength(2));
      expect(tags.where((tag) => tag == 'em'), hasLength(2));
      expect(tags, containsAll(<String>['u', 'del', 'br', 'code']));
      expect(tags.where((tag) => tag == 'del'), hasLength(3));
    });

    test('keeps html tags literal inside code spans and fenced code', () {
      final tags = _elementTags(
        _parseChatMarkdown('`<b>raw</b>`\n\n```\n<i>raw</i>\n```'),
      );

      expect(tags, isNot(contains('strong')));
      expect(tags, isNot(contains('em')));
    });

    test('normalizes simple html block tags before markdown parsing', () {
      final formatted = formatChatMarkdownText(
        '<p>Hello</p><div>Next</div><hr>',
      );

      expect(formatted, contains('Hello\n\n'));
      expect(formatted, contains('Next\n\n'));
      expect(formatted, contains('---'));
    });
  });
}

List<md.Node> _parseChatMarkdown(String input) {
  final document = md.Document(
    inlineSyntaxes: buildChatMarkdownInlineSyntaxes(),
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  );

  return document.parseLines(formatChatMarkdownText(input).split('\n'));
}

List<String> _elementTags(List<md.Node> nodes) {
  final tags = <String>[];

  void walk(md.Node node) {
    if (node is md.Element) {
      tags.add(node.tag);
      for (final child in node.children ?? const <md.Node>[]) {
        walk(child);
      }
    }
  }

  for (final node in nodes) {
    walk(node);
  }

  return tags;
}
