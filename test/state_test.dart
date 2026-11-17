import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hisab/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  test('add 500 Khabar Cash updates Home, Report and Budget together', () {
    final s = AppState();
    s.loadDemoData();
    final now = DateTime.now();
    final monthOutBefore = s.monthOut(now);
    final cashBefore = s.wallet('cash').balance;
    final khabarBefore = s.monthSpendByCategory(now)['Khabar'] ?? 0;
    final totalBefore = s.totalBalance;

    s.addEntry(Entry(
      id: 't1', isIncome: false, amount: 500, category: 'Khabar',
      account: 'cash', note: 'test', date: now,
    ));

    expect(s.monthOut(now), monthOutBefore + 500);
    expect(s.wallet('cash').balance, cashBefore - 500);
    expect(s.totalBalance, totalBefore - 500);
    expect((s.monthSpendByCategory(now)['Khabar'] ?? 0), khabarBefore + 500);
    expect(s.todayOut(now), 500 + 1980); // demo today out was 1980
    // last-7-days chart is derived from the same entries
    final day = s.last7Days(now).last;
    expect(day.expense, 1980 + 500);
    // edit reverses the old effect and applies the new one
    final e = s.entries.firstWhere((x) => x.id == 't1');
    s.updateEntry(Entry(
      id: e.id, isIncome: false, amount: 800, category: 'Khabar',
      account: 'cash', note: 'test', date: now,
    ));
    expect(s.wallet('cash').balance, cashBefore - 800);
    expect(s.monthOut(now), monthOutBefore + 800);
    // delete reverses fully
    s.deleteEntry('t1');
    expect(s.wallet('cash').balance, cashBefore);
    expect(s.monthOut(now), monthOutBefore);
  });

  test('wallets sum to total balance after demo load', () {
    final s = AppState();
    s.loadDemoData();
    expect(s.totalBalance, 149100);
    expect(s.wallet('cash').balance, 8450);
    expect(s.wallet('bkash').balance, 23150);
    expect(s.wallet('nagad').balance, 5200);
    expect(s.wallet('bank').balance, 112300);
  });

  test('taka formatting uses lakh grouping', () {
    expect(formatTaka(149100), '৳1,49,100');
    expect(formatTaka(500), '৳500');
    expect(formatTaka(125000), '৳1,25,000');
  });

  test('CSV export/import round-trips entries and wallets', () {
    final s = AppState();
    s.loadDemoData();
    final csv = s.toCsv();
    final s2 = AppState();
    final n = s2.importCsv(csv);
    expect(n, s.entries.length);
    expect(s2.totalBalance, s.totalBalance);
    expect(s2.monthOut(DateTime.now()), s.monthOut(DateTime.now()));
  });
}
