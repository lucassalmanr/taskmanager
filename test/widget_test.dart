import 'package:flutter_test/flutter_test.dart';
import 'package:teste/app.dart';

void main() {
  testWidgets('App loads and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const AppWidget());
    expect(find.text('Task Manager'), findsOneWidget);
    expect(find.text('Add Tarefa'), findsOneWidget);
  });
}
