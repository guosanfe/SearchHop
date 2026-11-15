import 'package:flutter_test/flutter_test.dart';
import 'package:searchhop/src/widget_search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('widget search dialog renders and validates empty query',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const WidgetSearchApp());
    await tester.pumpAndSettle();

    expect(find.text('搜跳 · 快速搜索'), findsOneWidget);
    expect(find.text('Bilibili'), findsOneWidget);

    await tester.tap(find.text('搜索'));
    await tester.pump();
    expect(find.text('请输入关键词'), findsOneWidget);
  });

  testWidgets('widget search remembers last chosen site', (tester) async {
    SharedPreferences.setMockInitialValues({widgetSitePrefKey: '知乎'});
    await tester.pumpWidget(const WidgetSearchApp());
    await tester.pumpAndSettle();

    expect(find.text('知乎'), findsOneWidget);
  });
}