import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for ALL money state.
/// Home, Report and Budget never keep their own copies — every derived
/// number (totals, charts, budgets, saving) is computed from [entries]
/// and [wallets] here, so an add/edit/delete updates every screen at once.
/// (This was the reviewer defect in the web prototype: Report/Budget
/// were rendered once from hardcoded arrays and went stale after Quick Add.)

String formatTaka(int n) {
  final neg = n < 0;
  var s = n.abs().toString();
  String out;
  if (s.length <= 3) {
    out = s;
  } else {
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    out = '${parts.join(',')},$last3';
  }
  return '${neg ? '-' : ''}৳$out';
}

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

const monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
String shortDate(DateTime d) => '${d.day} ${monthNames[d.month - 1]}';

class CategoryInfo {
  final String name;
  final int color; // 0xAARRGGBB
  final String icon; // emoji-free: we map to an icon codepoint name in UI
  const CategoryInfo(this.name, this.color, this.icon);
}

const expenseCategories = <CategoryInfo>[
  CategoryInfo('Khabar', 0xFF00B8A9, 'food'),
  CategoryInfo('Bazar', 0xFF22D3EE, 'cart'),
  CategoryInfo('Transport', 0xFFFFB020, 'bus'),
  CategoryInfo('Vara', 0xFF4DA3FF, 'home'),
  CategoryInfo('Mobile', 0xFF34D399, 'phone'),
  CategoryInfo('Shopping', 0xFFFF8A3D, 'bag'),
  CategoryInfo('Health', 0xFFFF5A4E, 'health'),
  CategoryInfo('Porashona', 0xFF7DD3FC, 'book'),
  CategoryInfo('Others', 0xFF94A3B8, 'more'),
];
const incomeCategories = <CategoryInfo>[
  CategoryInfo('Salary', 0xFF00B8A9, 'work'),
  CategoryInfo('Business', 0xFF22D3EE, 'shop'),
  CategoryInfo('Freelance', 0xFF34D399, 'laptop'),
  CategoryInfo('Others', 0xFF94A3B8, 'more'),
];

CategoryInfo categoryInfo(String name, bool isIncome) {
  final list = isIncome ? incomeCategories : expenseCategories;
  return list.firstWhere((c) => c.name == name, orElse: () => list.last);
}

class Wallet {
  final String id;
  final String name;
  final int color;
  int balance;
  Wallet(this.id, this.name, this.color, this.balance);
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'color': color, 'balance': balance};
  factory Wallet.fromJson(Map<String, dynamic> j) => Wallet(
      j['id'] as String, j['name'] as String, j['color'] as int,
      (j['balance'] as num).toInt());
}

const walletDefs = <(String, String, int)>[
  ('cash', 'Cash', 0xFF00B8A9),
  ('bkash', 'bKash', 0xFFE2136E),
  ('nagad', 'Nagad', 0xFFFF6A00),
  ('bank', 'Bank', 0xFF4DA3FF),
];

class Entry {
  final String id;
  bool isIncome;
  int amount;
  String category;
  String account;
  String note;
  DateTime date;
  Entry({
    required this.id,
    required this.isIncome,
    required this.amount,
    required this.category,
    required this.account,
    required this.note,
    required this.date,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'isIncome': isIncome,
        'amount': amount,
        'category': category,
        'account': account,
        'note': note,
        'date': date.toIso8601String(),
      };
  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
        id: j['id'] as String,
        isIncome: j['isIncome'] as bool,
        amount: (j['amount'] as num).toInt(),
        category: j['category'] as String,
        account: j['account'] as String,
        note: j['note'] as String? ?? '',
        date: DateTime.parse(j['date'] as String),
      );
}

class Debt {
  final String id;
  String name;
  bool isLend; // true = keu amake dibe (Pabo), false = ami dibo (Debo)
  int amount;
  bool settled;
  Debt({required this.id, required this.name, required this.isLend,
    required this.amount, this.settled = false});
  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'isLend': isLend,
        'amount': amount, 'settled': settled,
      };
  factory Debt.fromJson(Map<String, dynamic> j) => Debt(
        id: j['id'] as String,
        name: j['name'] as String,
        isLend: j['isLend'] as bool,
        amount: (j['amount'] as num).toInt(),
        settled: j['settled'] as bool? ?? false,
      );
}

class AppState extends ChangeNotifier {
  static const _key = 'hisab_state_v1';
  List<Entry> entries = [];
  List<Wallet> wallets = [
    for (final w in walletDefs) Wallet(w.$1, w.$2, w.$3, 0),
  ];
  Map<String, int> budgets = {
    'Khabar': 15000, 'Bazar': 12000, 'Transport': 5000, 'Vara': 8000,
    'Mobile': 2000, 'Shopping': 6000, 'Health': 3000, 'Porashona': 4000,
    'Others': 5000,
  };
  List<Debt> debts = [];
  String goalName = 'Emergency Fund';
  int goalTarget = 50000;
  int goalSaved = 0;
  bool pinEnabled = false;
  String pin = '';

  bool _loaded = false;
  bool get loaded => _loaded;

  Wallet wallet(String id) =>
      wallets.firstWhere((w) => w.id == id, orElse: () => wallets.first);

  // ---------- derived values: everything reads from entries/wallets ----
  int get totalBalance => wallets.fold(0, (s, w) => s + w.balance);

  List<Entry> get sortedEntries {
    final l = List<Entry>.from(entries);
    l.sort((a, b) => b.date.compareTo(a.date));
    return l;
  }

  int _sum(bool income, DateTime from, DateTime to) => entries
      .where((e) =>
          e.isIncome == income &&
          !e.date.isBefore(from) &&
          e.date.isBefore(to))
      .fold(0, (s, e) => s + e.amount);

  int todayIn(DateTime now) =>
      _sum(true, DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day + 1));
  int todayOut(DateTime now) =>
      _sum(false, DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day + 1));
  int monthIn(DateTime now) =>
      _sum(true, DateTime(now.year, now.month), DateTime(now.year, now.month + 1));
  int monthOut(DateTime now) =>
      _sum(false, DateTime(now.year, now.month), DateTime(now.year, now.month + 1));
  int monthSaving(DateTime now) => monthIn(now) - monthOut(now);

  /// Expense per category for the current month.
  Map<String, int> monthSpendByCategory(DateTime now) {
    final m = <String, int>{};
    for (final e in entries) {
      if (!e.isIncome &&
          e.date.year == now.year &&
          e.date.month == now.month) {
        m[e.category] = (m[e.category] ?? 0) + e.amount;
      }
    }
    return m;
  }

  /// Last 7 days, oldest -> newest, aggregated from entries (never hardcoded).
  List<({DateTime day, int income, int expense})> last7Days(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return (
        day: d,
        income: _sum(true, d, d.add(const Duration(days: 1))),
        expense: _sum(false, d, d.add(const Duration(days: 1))),
      );
    });
  }

  int get lendTotal => debts
      .where((d) => d.isLend && !d.settled)
      .fold(0, (s, d) => s + d.amount);
  int get borrowTotal => debts
      .where((d) => !d.isLend && !d.settled)
      .fold(0, (s, d) => s + d.amount);

  // ---------- mutations: wallet effect is always applied with the entry --
  void _applyWallet(Entry e, int sign) {
    final w = wallet(e.account);
    w.balance += sign * (e.isIncome ? e.amount : -e.amount);
  }

  void addEntry(Entry e) {
    entries.add(e);
    _applyWallet(e, 1);
    _save();
    notifyListeners();
  }

  void updateEntry(Entry updated) {
    final i = entries.indexWhere((e) => e.id == updated.id);
    if (i < 0) return;
    _applyWallet(entries[i], -1); // reverse old effect
    entries[i] = updated;
    _applyWallet(updated, 1); // apply new effect
    _save();
    notifyListeners();
  }

  void deleteEntry(String id) {
    final i = entries.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _applyWallet(entries[i], -1);
    entries.removeAt(i);
    _save();
    notifyListeners();
  }

  void setBudget(String category, int limit) {
    budgets[category] = limit;
    _save();
    notifyListeners();
  }

  void addDebt(Debt d) {
    debts.add(d);
    _save();
    notifyListeners();
  }

  void toggleDebtSettled(String id) {
    final d = debts.firstWhere((x) => x.id == id);
    d.settled = !d.settled;
    _save();
    notifyListeners();
  }

  void deleteDebt(String id) {
    debts.removeWhere((d) => d.id == id);
    _save();
    notifyListeners();
  }

  void setGoal(String name, int target) {
    goalName = name;
    goalTarget = target;
    _save();
    notifyListeners();
  }

  /// Move money from Cash wallet into the savings goal (keeps totals honest).
  void addToGoal(int amount) {
    if (amount <= 0) return;
    wallet('cash').balance -= amount;
    goalSaved += amount;
    _save();
    notifyListeners();
  }

  void setPin(bool enabled, String newPin) {
    pinEnabled = enabled;
    pin = enabled ? newPin : '';
    _save();
    notifyListeners();
  }

  void clearAll() {
    entries = [];
    wallets = [for (final w in walletDefs) Wallet(w.$1, w.$2, w.$3, 0)];
    debts = [];
    goalSaved = 0;
    _save();
    notifyListeners();
  }

  void loadDemoData() {
    // Opening balances chosen so that after applying the demo entries
    // the closing balances match the prototype: Cash 8450, bKash 23150,
    // Nagad 5200, Bank 112300 (total ৳1,49,100). Every entry is applied
    // through the wallet, so later edit/delete stays consistent.
    entries = [];
    debts = [];
    goalSaved = 0;
    wallets[0].balance = 15520; // Cash
    wallets[1].balance = 25630; // bKash
    wallets[2].balance = 6820; // Nagad
    wallets[3].balance = 98400; // Bank
    final now = DateTime.now();
    int n = 0;
    Entry e(bool inc, int amt, String cat, String acc, String note, int daysAgo) {
      return Entry(
        id: 'demo-${n++}',
        isIncome: inc, amount: amt, category: cat, account: acc,
        note: note,
        date: DateTime(now.year, now.month, now.day - daysAgo, 12),
      );
    }
    final demo = [
      e(true, 5000, 'Salary', 'bank', 'Salary', 0),
      e(false, 1250, 'Khabar', 'cash', 'Bazar', 0),
      e(false, 450, 'Transport', 'bkash', 'Rickshaw', 0),
      e(false, 180, 'Mobile', 'bkash', 'Recharge', 0),
      e(false, 100, 'Khabar', 'cash', 'Snacks', 0),
      e(true, 12000, 'Business', 'bank', 'Shop sale', 1),
      e(false, 2400, 'Bazar', 'cash', 'Weekly bazar', 1),
      e(false, 120, 'Transport', 'cash', 'Bus', 1),
      e(false, 860, 'Khabar', 'cash', 'Lunch', 2),
      e(false, 3100, 'Vara', 'bank', 'Room rent part', 3),
      e(false, 1620, 'Shopping', 'nagad', 'Shirt', 4),
      e(false, 2340, 'Bazar', 'cash', 'Bazar', 5),
      e(false, 1850, 'Health', 'bkash', 'Medicine', 6),
    ];
    for (final entry in demo) {
      entries.add(entry);
      _applyWallet(entry, 1);
    }
    _save();
    notifyListeners();
  }

  // ---------- persistence ------------------------------------------------
  Map<String, dynamic> toJson() => {
        'entries': entries.map((e) => e.toJson()).toList(),
        'wallets': wallets.map((w) => w.toJson()).toList(),
        'budgets': budgets,
        'debts': debts.map((d) => d.toJson()).toList(),
        'goalName': goalName,
        'goalTarget': goalTarget,
        'goalSaved': goalSaved,
        'pinEnabled': pinEnabled,
        'pin': pin,
      };

  void fromJson(Map<String, dynamic> j) {
    entries = (j['entries'] as List? ?? [])
        .map((e) => Entry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    wallets = (j['wallets'] as List? ?? [])
        .map((w) => Wallet.fromJson(Map<String, dynamic>.from(w as Map)))
        .toList();
    if (wallets.isEmpty) {
      wallets = [for (final w in walletDefs) Wallet(w.$1, w.$2, w.$3, 0)];
    }
    budgets = Map<String, int>.from(
        (j['budgets'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toInt())));
    debts = (j['debts'] as List? ?? [])
        .map((d) => Debt.fromJson(Map<String, dynamic>.from(d as Map)))
        .toList();
    goalName = j['goalName'] as String? ?? 'Emergency Fund';
    goalTarget = (j['goalTarget'] as num?)?.toInt() ?? 50000;
    goalSaved = (j['goalSaved'] as num?)?.toInt() ?? 0;
    pinEnabled = j['pinEnabled'] as bool? ?? false;
    pin = j['pin'] as String? ?? '';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // corrupted state: start clean rather than crash
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(toJson()));
  }

  Future<void> saveNow() => _save();

  // ---------- CSV backup -------------------------------------------------
  String toCsv() {
    final b = StringBuffer('type,amount,category,account,note,date\n');
    for (final e in sortedEntries) {
      final note = e.note.replaceAll(',', ' ').replaceAll('\n', ' ');
      b.writeln(
          '${e.isIncome ? 'income' : 'expense'},${e.amount},${e.category},${e.account},$note,${dayKey(e.date)}');
    }
    b.writeln('---WALLETS---');
    for (final w in wallets) {
      b.writeln('wallet,${w.balance},${w.name},${w.id},,');
    }
    return b.toString();
  }

  /// Returns number of entries imported, or -1 if the CSV is not ours.
  int importCsv(String csv) {
    final lines = const LineSplitter().convert(csv);
    if (lines.isEmpty || !lines.first.startsWith('type,amount,category')) {
      return -1;
    }
    final imported = <Entry>[];
    final fileWallets = <String, int>{};
    var inWallets = false;
    var count = 0;
    for (final line in lines.skip(1)) {
      if (line.startsWith('---WALLETS---')) {
        inWallets = true;
        continue;
      }
      if (line.trim().isEmpty) continue;
      final p = line.split(',');
      if (inWallets) {
        if (p.length >= 4) {
          final bal = int.tryParse(p[1].trim());
          if (bal != null) fileWallets[p[3].trim()] = bal;
        }
        continue;
      }
      if (p.length < 6) continue;
      final amount = int.tryParse(p[1].trim());
      final date = DateTime.tryParse(p[5].trim());
      if (amount == null || date == null) continue;
      imported.add(Entry(
        id: 'imp-${DateTime.now().microsecondsSinceEpoch}-$count',
        isIncome: p[0].trim() == 'income',
        amount: amount,
        category: p[2].trim(),
        account: p[3].trim(),
        note: p[4].trim(),
        date: date,
      ));
      count++;
    }
    // Restore: wallet opening = file closing balance minus the net effect
    // of the imported entries, then apply every entry through the wallet.
    // That keeps edit/delete consistent after a restore.
    entries = [];
    for (final w in wallets) {
      final closing = fileWallets[w.id] ?? w.balance;
      final net = imported
          .where((e) => e.account == w.id)
          .fold(0, (s, e) => s + (e.isIncome ? e.amount : -e.amount));
      w.balance = closing - net;
    }
    for (final e in imported) {
      entries.add(e);
      _applyWallet(e, 1);
    }
    _save();
    notifyListeners();
    return count;
  }

  String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}';
}
