import 'package:material_ui/material_ui.dart';

import 'launcher.dart';
import 'manage_screen.dart';
import 'site_store.dart';
import 'theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.store});

  final SiteStore store;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  int _selectedIndex = 0;
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
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

  Future<void> _search() async {
    final query = _controller.text.trim();
    final sites = widget.store.visibleSites;
    if (query.isEmpty) {
      _showSnackBar('请输入关键词');
      return;
    }
    if (sites.isEmpty) {
      _showSnackBar('没有可用站点，请先在管理中添加');
      return;
    }
    final site = sites[_selectedIndex];
    setState(() => _launching = true);
    try {
      final target = await launchSearch(site, query);
      if (target == LaunchTarget.web && mounted) {
        _showSnackBar('未唤起 ${site.name} App，已打开网页版');
      }
    } on LaunchFailure catch (e) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('打开失败'),
            content: Text(e.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      }
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '搜跳',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.greenSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SearchHop',
                      style: TextStyle(fontSize: 11, color: AppColors.greenDeep),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '站点管理',
                    icon: const Icon(Icons.tune, color: AppColors.label),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageScreen(store: widget.store),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (sites.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '所有站点均已隐藏，请在管理中添加或显示站点',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < sites.length; i++)
                      ChoiceChip(
                        label: Text(sites[i].name),
                        selected: i == _selectedIndex,
                        showCheckmark: false,
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.greenDeep,
                        side: const BorderSide(color: AppColors.border),
                        shape: const StadiumBorder(),
                        labelPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        labelStyle: TextStyle(
                          color: i == _selectedIndex
                              ? Colors.white
                              : AppColors.label,
                        ),
                        onSelected: (_) => setState(() => _selectedIndex = i),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '输入关键词',
                  prefixIcon: const Icon(Icons.search,
                      size: 20, color: AppColors.muted),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear,
                              size: 20, color: AppColors.muted),
                          onPressed: () {
                            _controller.clear();
                            setState(() {});
                          },
                        ),
                ),
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
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search, size: 18),
                          SizedBox(width: 8),
                          Text('搜索'),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}