// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/main.dart';

void main() {
  testWidgets('App renders chat screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const AiChatApp());
    await tester.pumpAndSettle();

    // Verify that the chat screen is shown.
    expect(find.text('新对话'), findsOneWidget);
    expect(find.text('开始和 Nona 对话吧'), findsOneWidget);
  });
}
