import 'package:flutter_test/flutter_test.dart';
import 'package:home_mind_mobile/main.dart';

void main() {
  testWidgets('HomeMind renders its primary navigation', (tester) async {
    await tester.pumpWidget(const HomeMindApp());
    expect(find.text('看见每一点小小的坚持'), findsOneWidget);
    expect(find.text('统计'), findsNWidgets(2));
    expect(find.text('待办'), findsOneWidget);
  });
}
