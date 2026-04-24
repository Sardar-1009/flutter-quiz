import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quiz_app/main.dart';
import 'package:flutter_quiz_app/viewmodels/quiz_viewmodel.dart';

void main() {
  testWidgets('App starts on home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => QuizViewModel(),
        child: const FlutterQuizApp(),
      ),
    );
    expect(find.text('Flutter Quiz'), findsOneWidget);
  });
}
