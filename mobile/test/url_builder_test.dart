import 'package:flutter_test/flutter_test.dart';
import 'package:searchhop/src/url_builder.dart';

void main() {
  group('query mode (ported from desktop test_url_builder.py)', () {
    test('normal template', () {
      expect(
        buildSearchUrl('https://www.baidu.com/s?wd={query}', 'hello'),
        'https://www.baidu.com/s?wd=hello',
      );
    });

    test('chinese query is encoded', () {
      expect(
        buildSearchUrl(
            'https://search.bilibili.com/all?keyword={query}', 'Python 入门'),
        'https://search.bilibili.com/all?keyword=Python%20%E5%85%A5%E9%97%A8',
      );
    });

    test('douyin path segment is encoded', () {
      expect(
        buildSearchUrl('https://www.douyin.com/search/{query}', '猫咪 日常'),
        'https://www.douyin.com/search/%E7%8C%AB%E5%92%AA%20%E6%97%A5%E5%B8%B8',
      );
    });

    test('missing placeholder raises', () {
      expect(
        () => buildSearchUrl('https://example.com/search?q=fixed', 'anything'),
        throwsA(isA<MissingQueryPlaceholderError>()),
      );
    });

    test('missing placeholder is an ArgumentError', () {
      expect(
        () => buildSearchUrl('https://example.com/', 'anything'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('reserved characters are encoded', () {
      expect(
        buildSearchUrl('https://s.taobao.com/search?q={query}', 'a&b=c d'),
        'https://s.taobao.com/search?q=a%26b%3Dc%20d',
      );
    });

    test('xiaohongshu keeps extra params', () {
      expect(
        buildSearchUrl(
          'https://www.xiaohongshu.com/search_result?keyword={query}&source=web_explore_feed',
          '秋冬穿搭',
        ),
        'https://www.xiaohongshu.com/search_result?keyword=%E7%A7%8B%E5%86%AC%E7%A9%BF%E6%90%AD&source=web_explore_feed',
      );
    });
  });

  group('app scheme templates', () {
    test('bilibili scheme', () {
      expect(
        buildSearchUrl('bilibili://search?keyword={query}', '测试'),
        'bilibili://search?keyword=%E6%B5%8B%E8%AF%95',
      );
    });

    test('xiaohongshu scheme', () {
      expect(
        buildSearchUrl('xhsdiscover://search/result?keyword={query}', '秋冬 穿搭'),
        'xhsdiscover://search/result?keyword=%E7%A7%8B%E5%86%AC%20%E7%A9%BF%E6%90%AD',
      );
    });

    test('scheme without placeholder raises', () {
      expect(
        () => buildSearchUrl('bilibili://home', 'anything'),
        throwsA(isA<MissingQueryPlaceholderError>()),
      );
    });
  });

  group('wholeParams mode (nested JSON)', () {
    const jdTemplate =
        'openapp.jdmobile://virtual?params={"des":"productList","keyWord":"{query}","from":"search","category":"jump"}';

    test('encodes the entire params value', () {
      expect(
        buildSearchUrl(jdTemplate, '手机 壳', encodeMode: EncodeMode.wholeParams),
        'openapp.jdmobile://virtual?params='
        '${Uri.encodeComponent('{"des":"productList","keyWord":"手机 壳","from":"search","category":"jump"}')}',
      );
    });

    test('reserved characters inside JSON stay safe', () {
      final result =
          buildSearchUrl(jdTemplate, 'a&b=c', encodeMode: EncodeMode.wholeParams);
      final params = Uri.parse(result).queryParameters['params'];
      expect(params, contains('"keyWord":"a&b=c"'));
    });

    test('missing placeholder raises in wholeParams mode too', () {
      expect(
        () => buildSearchUrl('openapp.jdmobile://virtual?params=fixed', 'x',
            encodeMode: EncodeMode.wholeParams),
        throwsA(isA<MissingQueryPlaceholderError>()),
      );
    });
  });
}