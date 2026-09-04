import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wrd/app.dart';
import 'package:wrd/store/wrd_store.dart';

void main() {
  testWidgets('first launch shows the welcome screen, RTL, with the slogan', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await WrdStore.load();
    addTearDown(store.dispose); // cancels the midnight-rollover timer
    await tester.pumpWidget(WrdApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('وِردُكَ نُورُك'), findsOneWidget);
    expect(find.text('ابدأ رحلة النور'), findsOneWidget);
    expect(store.hasOnboarded, isFalse);
  });

  testWidgets('after onboarding the five tabs appear', (tester) async {
    SharedPreferences.setMockInitialValues({'wrd.onboarded': true});
    final store = await WrdStore.load();
    addTearDown(store.dispose); // cancels the midnight-rollover timer
    await tester.pumpWidget(WrdApp(store: store));
    await tester.pumpAndSettle();

    for (final tab in ['اليوم', 'أورادي', 'المكتبة', 'المشكاة', 'الحلقات']) {
      expect(find.text(tab), findsWidgets, reason: '$tab tab missing');
    }
  });
}
