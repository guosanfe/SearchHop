import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:searchhop/src/manage_screen.dart';
import 'package:searchhop/src/site_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('editor cancel closes dialog and stays on manage screen',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = SiteStore();
    await store.load();
    await tester.pumpWidget(MaterialApp(home: ManageScreen(store: store)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('编辑').first);
    await tester.pumpAndSettle();
    expect(find.text('编辑站点'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('编辑站点'), findsNothing);
    expect(find.text('站点管理'), findsOneWidget);
    expect(find.text(store.sites.first.name), findsOneWidget);
  });
}