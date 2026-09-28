import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nexora_chat/main.dart';
import 'package:nexora_chat/models/user_model.dart';
import 'package:nexora_chat/providers/call_provider.dart';

void main() {
  testWidgets('NexoraApp initialization test', (WidgetTester tester) async {
    await tester.pumpWidget(const NexoraApp());

    final materialApp = tester.element(find.byType(MaterialApp));
    final callProvider = Provider.of<CallProvider>(materialApp, listen: false);
    await callProvider.initialize(
      UserModel(
        id: 'test-user',
        name: 'Test User',
        email: 'test@example.com',
      ),
    );

    expect(find.byType(NexoraApp), findsOneWidget);
    await tester.pump();
  });
}
