import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_grade/main.dart';

void main() {
  testWidgets('usuário de teste acessa a tela inicial', (tester) async {
    await tester.pumpWidget(const N1App());

    final campos = find.byType(EditableText);
    await tester.enterText(campos.at(0), 'User');
    await tester.enterText(campos.at(1), 'User');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Olá User!'), findsOneWidget);
  });
}
