import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/app.dart';

void main() {
  testWidgets('AdaptiLearn tampil layar awal Bahasa Indonesia',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AdaptiLearnApp()));
    await tester.pumpAndSettle();

    expect(find.text('AdaptiLearn'), findsOneWidget);
    expect(find.text('Selamat datang di AdaptiLearn'), findsOneWidget);
  });
}
