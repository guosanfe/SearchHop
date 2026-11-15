import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'default_sites.dart';
import 'site.dart';

class SiteStore extends ChangeNotifier {
  // v2: refreshed default app templates after real-device verification
  // (Taobao native search route); v1 stored the broken H5 route.
  static const _prefsKey = 'searchhop.sites.v2';

  List<Site> _sites = [];

  List<Site> get sites => List.unmodifiable(_sites);

  List<Site> get visibleSites => _sites.where((s) => s.visible).toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    var loaded = defaultSites();
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => Site.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) loaded = list;
      } on FormatException {
        // Corrupted storage falls back to defaults.
      }
    }
    _sites = loaded;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_sites.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> add(Site site) async {
    _sites.add(site);
    notifyListeners();
    await _persist();
  }

  Future<void> update(int index, Site site) async {
    _sites[index] = site;
    notifyListeners();
    await _persist();
  }

  Future<void> remove(int index) async {
    _sites.removeAt(index);
    notifyListeners();
    await _persist();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final site = _sites.removeAt(oldIndex);
    _sites.insert(newIndex, site);
    notifyListeners();
    await _persist();
  }

  Future<void> setVisible(int index, bool visible) async {
    _sites[index].visible = visible;
    notifyListeners();
    await _persist();
  }
}