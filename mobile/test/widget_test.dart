import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:searchhop/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app boots with default sites and search field',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SearchHopApp());
    await tester.pumpAndSettle();

    expect(find.text('搜跳'), findsOneWidget);
    expect(find.text('Bilibili'), findsOneWidget);
    expect(find.text('百度'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('搜索'), findsOneWidget);
  });

  testWidgets('empty keyword shows hint instead of launching',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SearchHopApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('搜索'));
    await tester.pump();
    expect(find.text('请输入关键词'), findsOneWidget);
  });
}