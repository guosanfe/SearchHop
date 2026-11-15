import 'package:material_ui/material_ui.dart';

import 'src/search_screen.dart';
import 'src/site_store.dart';
import 'src/theme.dart';
import 'src/widget_search_screen.dart';

void main() {
  runApp(const SearchHopApp());
}

@pragma('vm:entry-point')
void widgetSearchMain() {
  runApp(const WidgetSearchApp());
}

class SearchHopApp extends StatefulWidget {
  const SearchHopApp({super.key});

  @override
  State<SearchHopApp> createState() => _SearchHopAppState();
}

class _SearchHopAppState extends State<SearchHopApp> {
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
          ? SearchScreen(store: _store)
          : const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.greenDeep),
              ),
            ),
    );
  }
}