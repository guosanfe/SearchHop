import 'package:flutter/services.dart' show SystemNavigator;
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'launcher.dart';
import 'site_store.dart';
import 'theme.dart';

const widgetSitePrefKey = 'searchhop.widget.site';

class WidgetSearchApp extends StatefulWidget {
  const WidgetSearchApp({super.key});

  @override
  State<WidgetSearchApp> createState() => _WidgetSearchAppState();
}

class _WidgetSearchAppState extends State<WidgetSearchApp> {
  final _store = SiteStore();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _store.load().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '搜跳',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: _ready
          ? WidgetSearchScreen(store: _store)
          : const Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.greenDeep),
              ),
            ),
    );
  }
}

/// Compact dialog-style search surface launched from the home-screen widget.
class WidgetSearchScreen extends StatefulWidget {
  const WidgetSearchScreen({super.key, required this.store});

  final SiteStore store;

  @override
  State<WidgetSearchScreen> createState() => _WidgetSearchScreenState();
}

class _WidgetSearchScreenState extends State<WidgetSearchScreen> {
  final _controller = TextEditingController();
  int _selectedIndex = 0;
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
    SharedPreferences.getInstance().then((prefs) {
      final name = prefs.getString(widgetSitePrefKey);
      final index = widget.store.visibleSites.indexWhere((s) => s.name == name);
      if (index >= 0 && mounted) setState(() => _selectedIndex = index);
    });
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    final count = widget.store.visibleSites.length;
    if (_selectedIndex >= count) _selectedIndex = count == 0 ? 0 : count - 1;
    if (mounted) setState(() {});
  }

  Future<void> _selectSite(String? name) async {
    final index = widget.store.visibleSites.indexWhere((s) => s.name == name);
    if (index < 0) return;
    setState(() => _selectedIndex = index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widgetSitePrefKey, name!);
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    final sites = widget.store.visibleSites;
    if (query.isEmpty) {
      _showSnackBar('请输入关键词');
      return;
    }
    if (sites.isEmpty) {
      _showSnackBar('没有可用站点，请先在 App 管理中添加');
      return;
    }
    setState(() => _launching = true);
    try {
      await launchSearch(sites[_selectedIndex], query);
      if (mounted) await SystemNavigator.pop();
    } on LaunchFailure catch (e) {
      if (mounted) _showSnackBar(e.message);
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final sites = widget.store.visibleSites;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => SystemNavigator.pop(),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 360),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '搜跳 · 快速搜索',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: '关闭',
                        icon: const Icon(Icons.close,
                            size: 20, color: AppColors.muted),
                        onPressed: () => SystemNavigator.pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (sites.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '没有可用站点，请先在 App 管理中添加',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      initialValue: sites[_selectedIndex].name,
                      items: [
                        for (final site in sites)
                          DropdownMenuItem(
                            value: site.name,
                            child: Text(site.name),
                          ),
                      ],
                      onChanged: _selectSite,
                      decoration: const InputDecoration(labelText: '搜索站点'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: const InputDecoration(hintText: '输入关键词'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _launching ? null : _search,
                      child: _launching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('搜索'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}