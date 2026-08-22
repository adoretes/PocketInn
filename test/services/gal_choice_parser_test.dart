import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/services/gal_choice_parser.dart';

void main() {
  group('parseGalChoices', () {
    test('解析标准 JSON 对象', () {
      expect(
        parseGalChoices('{"choices": ["推开房门", "询问她的名字", "保持沉默"]}'),
        ['推开房门', '询问她的名字', '保持沉默'],
      );
    });

    test('解析纯数组', () {
      expect(
        parseGalChoices('["选项一", "选项二"]'),
        ['选项一', '选项二'],
      );
    });

    test('剥除 Markdown 围栏与前后杂文本', () {
      const raw = '好的，以下是选项：\n```json\n{"choices": ["A", "B"]}\n```\n希望对你有帮助';
      expect(parseGalChoices(raw), ['A', 'B']);
    });

    test('接受对象数组形式', () {
      const raw =
          '[{"text": "进门"}, {"label": "离开"}, {"content": "等待"}, {"choice": "回头"}]';
      expect(
        parseGalChoices(raw),
        ['进门', '离开', '等待', '回头'],
      );
    });

    test('接受映射形式的 choices', () {
      const raw = '{"choices": {"1": "敲门", "2": "离开"}}';
      expect(parseGalChoices(raw), ['敲门', '离开']);
    });

    test('忽略空白选项', () {
      expect(parseGalChoices('["", "  ", "有效"]'), ['有效']);
    });

    test('非法输出返回空列表', () {
      expect(parseGalChoices('这不是 JSON'), isEmpty);
      expect(parseGalChoices(''), isEmpty);
      expect(parseGalChoices('{"choices": 3}'), isEmpty);
      expect(parseGalChoices('{"other": ["a"]}'), isEmpty);
    });

    test('未闭合 JSON 返回空列表', () {
      expect(parseGalChoices('{"choices": ["a"'), isEmpty);
    });
  });
}
