import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hisab/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  testWidgets('Hisab app smoke test', (tester) async {
    // State layer smoke test: demo data loads and reconciles.
    final s = AppState();
    s.loadDemoData();
    expect(s.totalBalance, 149100);
    expect(s.entries.length, 13);
  });
}
