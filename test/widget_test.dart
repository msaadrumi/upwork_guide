import 'package:flutter_test/flutter_test.dart';
import 'package:main/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const DocxViewerApp());
    await tester.pump();
    expect(find.byType(DocxViewerApp), findsOneWidget);
  });
}
