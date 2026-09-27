import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_chat/main.dart';

void main() {
  testWidgets('NexoraApp initialization test', (WidgetTester tester) async {
    await tester.pumpWidget(const NexoraApp());
    expect(find.byType(NexoraApp), findsOneWidget);
  });
}
