import 'package:flutter_test/flutter_test.dart';
import 'package:nemesis_core/main.dart';
import 'package:nemesis_core/services/terminal_service.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';

class MockTerminalService extends TerminalService {
  @override
  void connect() {
    // Do nothing in tests to avoid WebSocket exceptions
  }
}

void main() {
  testWidgets('Nemesis App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Wrap with provider using the MockTerminalService
    await tester.pumpWidget(
      ChangeNotifierProvider<TerminalService>(
        create: (_) => MockTerminalService(),
        child: const NemesisApp(),
      ),
    );

    // Verify that the title is present.
    expect(find.text('NEMESIS CORE'), findsOneWidget);

    // Check if the terminal view is present.
    expect(find.byType(TerminalView), findsOneWidget);
  });
}
