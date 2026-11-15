import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:searchhop/src/default_sites.dart';
import 'package:searchhop/src/site.dart';
import 'package:searchhop/src/url_builder.dart';

void main() {
  test('site json roundtrip keeps all fields', () {
    final site = Site(
      name: '京东',
      urlTemplate: 'https://search.jd.com/Search?keyword={query}&enc=utf8',
      appTemplate: 'openapp.jdmobile://virtual?params={"keyWord":"{query}"}',
      androidPackage: 'com.jingdong.app.mall',
      appEncodeMode: EncodeMode.wholeParams,
      visible: false,
    );
    final restored =
        Site.fromJson(jsonDecode(jsonEncode(site.toJson())) as Map<String, dynamic>);
    expect(restored.name, site.name);
    expect(restored.urlTemplate, site.urlTemplate);
    expect(restored.appTemplate, site.appTemplate);
    expect(restored.androidPackage, site.androidPackage);
    expect(restored.appEncodeMode, EncodeMode.wholeParams);
    expect(restored.visible, false);
  });

  test('minimal json restores defaults', () {
    final site = Site.fromJson({
      'name': '百度',
      'url_template': 'https://www.baidu.com/s?wd={query}',
    });
    expect(site.hasApp, false);
    expect(site.visible, true);
    expect(site.appEncodeMode, EncodeMode.query);
  });

  test('default sites match desktop config', () {
    final sites = defaultSites();
    expect(sites.length, 9);
    expect(sites.map((s) => s.name).toList(),
        ['Bilibili', '知乎', '微博', '百度', '小红书', '抖音', '淘宝', '京东', '拼多多']);
    for (final site in sites) {
      expect(site.urlTemplate, contains('{query}'));
      if (site.hasApp) expect(site.appTemplate, contains('{query}'));
    }
    expect(sites.firstWhere((s) => s.name == '百度').hasApp, false);
    expect(sites.firstWhere((s) => s.name == '京东').appEncodeMode,
        EncodeMode.wholeParams);
  });
}