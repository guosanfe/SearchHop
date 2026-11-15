import 'package:material_ui/material_ui.dart';

import 'site.dart';
import 'site_store.dart';
import 'theme.dart';
import 'url_builder.dart';

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key, required this.store});

  final SiteStore store;

  Future<void> _edit(BuildContext context, int? index) async {
    final site = await showDialog<Site>(
      context: context,
      builder: (_) => _SiteEditorDialog(
        site: index == null ? null : store.sites[index],
      ),
    );
    if (site == null) return;
    if (index == null) {
      await store.add(site);
    } else {
      await store.update(index, site);
    }
  }

  Future<void> _delete(BuildContext context, int index) async {
    final site = store.sites[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除站点'),
        content: Text('确定删除「${site.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) await store.remove(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('站点管理'),
        actions: [
          IconButton(
            tooltip: '添加站点',
            icon: const Icon(Icons.add),
            onPressed: () => _edit(context, null),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final sites = store.sites;
          if (sites.isEmpty) {
            return const Center(
              child: Text('暂无站点，点击右上角添加',
                  style: TextStyle(color: AppColors.muted)),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sites.length,
            onReorderItem: store.reorder,
            itemBuilder: (context, index) {
              final site = sites[index];
              return Card(
                key: ObjectKey(site),
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  leading: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle, color: AppColors.muted),
                  ),
                  title: Text(site.name,
                      style: const TextStyle(color: AppColors.text)),
                  subtitle: Text(
                    site.hasApp ? 'App 直达 · 网页兜底' : '仅网页版',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: site.visible,
                        activeThumbColor: AppColors.greenDeep,
                        onChanged: (v) => store.setVisible(index, v),
                      ),
                      IconButton(
                        tooltip: '编辑',
                        icon: const Icon(Icons.edit_outlined,
                            size: 20, color: AppColors.label),
                        onPressed: () => _edit(context, index),
                      ),
                      IconButton(
                        tooltip: '删除',
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: AppColors.muted),
                        onPressed: () => _delete(context, index),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SiteEditorDialog extends StatefulWidget {
  const _SiteEditorDialog({this.site});

  final Site? site;

  @override
  State<_SiteEditorDialog> createState() => _SiteEditorDialogState();
}

class _SiteEditorDialogState extends State<_SiteEditorDialog> {
  late final _name = TextEditingController(text: widget.site?.name ?? '');
  late final _url =
      TextEditingController(text: widget.site?.urlTemplate ?? '');
  late final _app =
      TextEditingController(text: widget.site?.appTemplate ?? '');
  late final _package =
      TextEditingController(text: widget.site?.androidPackage ?? '');
  late EncodeMode _encodeMode =
      widget.site?.appEncodeMode ?? EncodeMode.query;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _app.dispose();
    _package.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final url = _url.text.trim();
    final app = _app.text.trim();
    final package = _package.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '请填写站点名称');
      return;
    }
    if (!url.contains(queryPlaceholder)) {
      setState(() => _error = '网页模板必须包含 {query} 占位符');
      return;
    }
    if (app.isNotEmpty && !app.contains(queryPlaceholder)) {
      setState(() => _error = 'App 模板必须包含 {query} 占位符');
      return;
    }
    Navigator.pop(
      context,
      Site(
        name: name,
        urlTemplate: url,
        appTemplate: app.isEmpty ? null : app,
        androidPackage: package.isEmpty ? null : package,
        appEncodeMode: _encodeMode,
        visible: widget.site?.visible ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.site == null ? '添加站点' : '编辑站点'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: '名称'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _url,
                decoration: const InputDecoration(
                  labelText: '网页模板（兜底）',
                  hintText: 'https://example.com/search?q={query}',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _app,
                decoration: const InputDecoration(
                  labelText: 'App 模板（可选）',
                  hintText: 'example://search?keyword={query}',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _package,
                decoration: const InputDecoration(
                  labelText: 'Android 包名（可选）',
                  hintText: 'com.example.app',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EncodeMode>(
                initialValue: _encodeMode,
                decoration:
                    const InputDecoration(labelText: 'App 模板编码方式'),
                items: const [
                  DropdownMenuItem(
                    value: EncodeMode.query,
                    child: Text('关键词编码（默认）'),
                  ),
                  DropdownMenuItem(
                    value: EncodeMode.wholeParams,
                    child: Text('整段参数编码（嵌套 JSON）'),
                  ),
                ],
                onChanged: (v) => setState(() => _encodeMode = v!),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }
}