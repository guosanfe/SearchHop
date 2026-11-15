import 'package:flutter/services.dart' show PlatformException;
import 'package:url_launcher/url_launcher.dart';

import 'site.dart';
import 'url_builder.dart';

enum LaunchTarget { app, web }

class LaunchFailure implements Exception {
  LaunchFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// App-first, web-fallback. Only externalApplication mode is used — the app
/// never embeds a WebView, matching the desktop product boundary.
///
/// launchUrl is attempted directly instead of gating on canLaunchUrl:
/// canLaunchUrl resolves with MATCH_DEFAULT_ONLY and yields false negatives
/// for some apps' intent filters (observed on real devices with Bilibili/XHS).
/// On Android url_launcher throws ACTIVITY_NOT_FOUND instead of returning
/// false when nothing handles the scheme, so the app attempt must be guarded
/// or the web fallback never runs.
Future<LaunchTarget> launchSearch(Site site, String query) async {
  if (site.hasApp) {
    final uri = Uri.parse(
      buildSearchUrl(site.appTemplate!, query, encodeMode: site.appEncodeMode),
    );
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return LaunchTarget.app;
      }
    } on PlatformException {
      // Scheme unhandled (app not installed): fall through to web.
    }
  }
  final webUri = Uri.parse(buildSearchUrl(site.urlTemplate, query));
  try {
    if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
      return LaunchTarget.web;
    }
  } on PlatformException {
    // No browser available either: reported as LaunchFailure below.
  }
  throw LaunchFailure('无法打开浏览器，请检查系统默认浏览器设置');
}