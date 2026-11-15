import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:searchhop/src/default_sites.dart';
import 'package:searchhop/src/launcher.dart';
import 'package:searchhop/src/site.dart';
import 'package:searchhop/src/url_builder.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Mirrors url_launcher_android: an unhandled scheme throws
/// ACTIVITY_NOT_FOUND instead of returning false.
class _FakeLauncher extends UrlLauncherPlatform {
  _FakeLauncher({this.appHandled = true, this.webHandled = true});

  final bool appHandled;
  final bool webHandled;
  final List<String> launched = [];
  final List<PreferredLaunchMode> modes = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    modes.add(options.mode);
    final handled = url.startsWith('https://') ? webHandled : appHandled;
    if (!handled) {
      throw PlatformException(
        code: 'ACTIVITY_NOT_FOUND',
        message: 'No Activity found to handle intent { $url }',
      );
    }
    return true;
  }
}

void main() {
  late UrlLauncherPlatform previous;
  setUp(() => previous = UrlLauncherPlatform.instance);
  tearDown(() => UrlLauncherPlatform.instance = previous);

  final site = Site(
    name: '微博',
    urlTemplate: 'https://s.weibo.com/weibo?q={query}',
    appTemplate: 'sinaweibo://searchall?q={query}',
  );

  test('uninstalled app scheme falls back to web', () async {
    final fake = _FakeLauncher(appHandled: false);
    UrlLauncherPlatform.instance = fake;

    expect(await launchSearch(site, 'hello world'), LaunchTarget.web);
    expect(fake.launched, [
      'sinaweibo://searchall?q=hello%20world',
      'https://s.weibo.com/weibo?q=hello%20world',
    ]);
    expect(fake.modes, [
      PreferredLaunchMode.externalApplication,
      PreferredLaunchMode.externalApplication,
    ]);
  });

  test('installed app scheme wins without web attempt', () async {
    final fake = _FakeLauncher();
    UrlLauncherPlatform.instance = fake;

    expect(await launchSearch(site, 'hello'), LaunchTarget.app);
    expect(fake.launched, ['sinaweibo://searchall?q=hello']);
  });

  test('web-only site launches browser directly', () async {
    final fake = _FakeLauncher();
    UrlLauncherPlatform.instance = fake;
    final webOnly = Site(name: '百度', urlTemplate: 'https://www.baidu.com/s?wd={query}');

    expect(await launchSearch(webOnly, 'hello'), LaunchTarget.web);
    expect(fake.launched, ['https://www.baidu.com/s?wd=hello']);
  });

  test('no browser either surfaces LaunchFailure', () async {
    UrlLauncherPlatform.instance = _FakeLauncher(appHandled: false, webHandled: false);

    expect(() => launchSearch(site, 'hello'), throwsA(isA<LaunchFailure>()));
  });

  test('every default site falls back to its own web template', () async {
    for (final s in defaultSites()) {
      final fake = _FakeLauncher(appHandled: false);
      UrlLauncherPlatform.instance = fake;

      expect(await launchSearch(s, 'hello world'), LaunchTarget.web,
          reason: s.name);
      expect(fake.launched.last, buildSearchUrl(s.urlTemplate, 'hello world'),
          reason: s.name);
      if (s.hasApp) {
        expect(
            fake.launched.first,
            buildSearchUrl(s.appTemplate!, 'hello world',
                encodeMode: s.appEncodeMode),
            reason: s.name);
      } else {
        expect(fake.launched.length, 1, reason: s.name);
      }
    }
  });
}