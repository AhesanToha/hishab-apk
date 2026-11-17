import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'charts.dart';
import 'store.dart';

// ---------- Design B: Dark + Colorful, teal/cyan, NO violet, high contrast,
// solid colours only — no blur, no glass, no hazy washes. ------------------
const bgColor = Color(0xFF0A0F14);
const cardColor = Color(0xFF111E28);
const cardColor2 = Color(0xFF16232E);
const borderColor = Color(0xFF1E3A45);
const teal = Color(0xFF00B8A9);
const cyan = Color(0xFF00E5FF);
const incomeGreen = Color(0xFF00D9A3);
const expenseRed = Color(0xFFFF5A4E);
const amber = Color(0xFFFFB020);
const textWhite = Colors.white;
const textSoft = Color(0xFFD7E6EB);
const textDim = Color(0xFF8FA6B3);

IconData catIcon(String icon) {
  switch (icon) {
    case 'food': return Icons.restaurant;
    case 'cart': return Icons.shopping_cart;
    case 'bus': return Icons.directions_bus;
    case 'home': return Icons.home;
    case 'phone': return Icons.phone_android;
    case 'bag': return Icons.shopping_bag;
    case 'health': return Icons.local_hospital;
    case 'book': return Icons.menu_book;
    case 'work': return Icons.work;
    case 'shop': return Icons.store;
    case 'laptop': return Icons.laptop;
    default: return Icons.more_horiz;
  }
}

IconData walletIcon(String id) {
  switch (id) {
    case 'cash': return Icons.account_balance_wallet;
    case 'bkash': return Icons.phone_android;
    case 'nagad': return Icons.account_balance;
    case 'bank': return Icons.business;
    default: return Icons.wallet;
  }
}

void main() {
  runApp(const HisabApp());
}

class HisabApp extends StatefulWidget {
  const HisabApp({super.key});
  @override
  State<HisabApp> createState() => _HisabAppState();
}

class _HisabAppState extends State<HisabApp> {
  final AppState state = AppState();
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    state.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        if (!state.loaded) {
          return MaterialApp(
            theme: _theme(),
            home: const Scaffold(
              backgroundColor: bgColor,
              body: Center(child: CircularProgressIndicator(color: cyan)),
            ),
          );
        }
        final locked = state.pinEnabled && state.pin.isNotEmpty && !_unlocked;
        return MaterialApp(
          title: 'Hisab',
          debugShowCheckedModeBanner: false,
          theme: _theme(),
          home: locked
              ? LockScreen(onUnlock: () => setState(() => _unlocked = true),
                  correctPin: state.pin)
              : HomeShell(state: state),
        );
      },
    );
  }

  ThemeData _theme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: bgColor,
      colorScheme: const ColorScheme.dark(
        primary: teal,
        secondary: cyan,
        surface: cardColor,
        onSurface: textWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: textWhite,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cyan, width: 2),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: cardColor2,
        contentTextStyle: TextStyle(color: textWhite),
      ),
    );
  }
}

// ---------- shared widgets -------------------------------------------------
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const AppCard({super.key, required this.child,
    this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) {
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(
      padding: padding, child: child));
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const SectionTitle(this.title, {super.key, this.onSeeAll});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  color: textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('সব দেখো',
                  style: TextStyle(color: cyan, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

Future<int?> askAmountDialog(BuildContext context, String title,
    {int initial = 0}) async {
  final ctrl = TextEditingController(text: initial > 0 ? '$initial' : '');
  final v = await showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: cardColor,
      title: Text(title, style: const TextStyle(color: textWhite)),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: textWhite, fontSize: 20),
        decoration: const InputDecoration(prefixText: '৳ ', hintText: '0'),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল', style: TextStyle(color: textDim))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: teal),
          onPressed: () =>
              Navigator.pop(ctx, int.tryParse(ctrl.text) ?? 0),
          child: const Text('সেভ', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  return v;
}

// ---------- PIN lock -------------------------------------------------------
class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  final String correctPin;
  const LockScreen({super.key, required this.onUnlock, required this.correctPin});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  String _error = '';

  void _press(String d) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += d;
      _error = '';
    });
    if (_pin.length == 4) {
      if (_pin == widget.correctPin) {
        widget.onUnlock();
      } else {
        setState(() {
          _error = 'ভুল PIN — আবার চেষ্টা করো';
          _pin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset('assets/logo.png', width: 96, height: 96),
            ),
            const SizedBox(height: 16),
            const Text('Hisab',
                style: TextStyle(
                    color: textWhite, fontSize: 28, fontWeight: FontWeight.bold)),
            const Text('PIN দিয়ে খুলো',
                style: TextStyle(color: textSoft, fontSize: 14)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                margin: const EdgeInsets.all(6),
                width: 16, height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? cyan : cardColor2,
                  border: Border.all(color: borderColor),
                ),
              )),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error,
                    style: const TextStyle(color: expenseRed)),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: 260,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6),
                itemCount: 12,
                itemBuilder: (ctx, i) {
                  if (i == 9) return const SizedBox.shrink();
                  if (i == 10) {
                    return _pinKey('0');
                  }
                  if (i == 11) {
                    return IconButton(
                      onPressed: () => setState(() {
                        if (_pin.isNotEmpty) {
                          _pin = _pin.substring(0, _pin.length - 1);
                        }
                      }),
                      icon: const Icon(Icons.backspace, color: textWhite),
                    );
                  }
                  return _pinKey('${i + 1}');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pinKey(String d) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: cardColor,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: borderColor),
          ),
        ),
        onPressed: () => _press(d),
        child: Text(d,
            style: const TextStyle(color: textWhite, fontSize: 22)),
      );
}

// ---------- home shell: bottom nav + centre FAB ---------------------------
class HomeShell extends StatefulWidget {
  final AppState state;
  const HomeShell({super.key, required this.state});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(state: widget.state, goTab: (i) => setState(() => _tab = i)),
      HistoryPage(state: widget.state),
      ReportPage(state: widget.state),
      MorePage(state: widget.state),
    ];
    return Scaffold(
      body: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) => pages[_tab],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(context, null),
        backgroundColor: cyan,
        foregroundColor: const Color(0xFF0A0F14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: cardColor,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home, 'হোম', 0),
            _navItem(Icons.history, 'হিস্ট্রি', 1),
            const SizedBox(width: 48),
            _navItem(Icons.pie_chart, 'রিপোর্ট', 2),
            _navItem(Icons.more_horiz, 'আরো', 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int tab) {
    final active = _tab == tab;
    return InkWell(
      onTap: () => setState(() => _tab = tab),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? cyan : textDim, size: 24),
            Text(label,
                style: TextStyle(
                    color: active ? cyan : textDim, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Future<void> _openAdd(BuildContext context, Entry? existing) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddPage(state: widget.state, existing: existing)),
    );
  }
}

// ---------- entry row (shared by Home + History) ---------------------------
class EntryRow extends StatelessWidget {
  final Entry entry;
  final VoidCallback onTap;
  const EntryRow({super.key, required this.entry, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final info = categoryInfo(entry.category, entry.isIncome);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Color(info.color).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(catIcon(info.icon),
                  color: Color(info.color), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.category,
                      style: const TextStyle(
                          color: textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  Text(
                      '${entry.note.isNotEmpty ? '${entry.note} · ' : ''}'
                      '${entry.account == 'cash' ? 'Cash' : entry.account == 'bkash' ? 'bKash' : entry.account == 'nagad' ? 'Nagad' : 'Bank'}'
                      ' · ${shortDate(entry.date)}',
                      style: const TextStyle(color: textDim, fontSize: 12)),
                ],
              ),
            ),
            Text(
              '${entry.isIncome ? '+' : '−'} ${formatTaka(entry.amount)}',
              style: TextStyle(
                color: entry.isIncome ? incomeGreen : expenseRed,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- HOME ------------------------------------------------------------
class HomePage extends StatelessWidget {
  final AppState state;
  final void Function(int) goTab;
  const HomePage({super.key, required this.state, required this.goTab});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = state.sortedEntries
        .where((e) => dayKey(e.date) == dayKey(now))
        .toList();
    final spend = state.monthSpendByCategory(now);
    final warnings = state.budgets.entries
        .where((b) => (spend[b.key] ?? 0) >= b.value * 0.8)
        .toList();
    final saving = state.monthSaving(now);
    final monthIn = state.monthIn(now);
    final savePct = monthIn > 0 ? (saving * 100 / monthIn).round() : 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset('assets/logo.png', width: 36, height: 36),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hisab',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('আয়-ব্যয়ের হিসাব',
                    style: TextStyle(color: textDim, fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: textWhite),
                if (warnings.isNotEmpty)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 9, height: 9,
                      decoration: const BoxDecoration(
                          color: expenseRed, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showAlerts(context, warnings, spend),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // Total balance
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('মোট ব্যালেন্স',
                    style: TextStyle(color: textSoft, fontSize: 13)),
                const SizedBox(height: 4),
                Text(formatTaka(state.totalBalance),
                    style: const TextStyle(
                        color: textWhite,
                        fontSize: 34,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.wallets.map((w) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cardColor2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(walletIcon(w.id),
                            size: 14, color: Color(w.color)),
                        const SizedBox(width: 5),
                        Text('${w.name} ${formatTaka(w.balance)}',
                            style: const TextStyle(
                                color: textSoft, fontSize: 12)),
                      ],
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          // Today + month
          Row(
            children: [
              Expanded(child: _miniCard('আজকের আয়',
                  state.todayIn(now), incomeGreen)),
              const SizedBox(width: 12),
              Expanded(child: _miniCard('আজকের খরচ',
                  state.todayOut(now), expenseRed)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _miniCard('এই মাসে আয়',
                  state.monthIn(now), incomeGreen)),
              const SizedBox(width: 12),
              Expanded(child: _miniCard('এই মাসে খরচ',
                  state.monthOut(now), expenseRed)),
            ],
          ),
          // Saving
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.savings, color: teal, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('এই মাসে বাঁচলো ${formatTaka(saving)}'
                          '${monthIn > 0 ? ' ($savePct%)' : ''}',
                          style: const TextStyle(
                              color: textWhite,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      Text(
                          'গড়ে দিনে খরচ ${formatTaka(now.day > 0 ? state.monthOut(now) ~/ now.day : 0)}',
                          style: const TextStyle(color: textDim, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (warnings.isNotEmpty)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber, color: amber, size: 20),
                      SizedBox(width: 6),
                      Text('বাজেট সতর্কতা',
                          style: TextStyle(
                              color: amber,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...warnings.map((b) {
                    final spent = spend[b.key] ?? 0;
                    final over = spent >= b.value;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${b.key}: ${formatTaka(spent)} / ${formatTaka(b.value)}'
                        '${over ? ' — লিমিট পার!' : ' — ৮০% পার'}',
                        style: TextStyle(
                            color: over ? expenseRed : amber, fontSize: 13),
                      ),
                    );
                  }),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => BudgetPage(state: state))),
                    child: const Text('বাজেট দেখো',
                        style: TextStyle(color: cyan)),
                  ),
                ],
              ),
            ),
          SectionTitle('আজকের লিস্ট', onSeeAll: () => goTab(1)),
          if (today.isEmpty)
            const AppCard(
                child: Text('আজ এখনো কোনো এন্ট্রি নেই — + চাপো',
                    style: TextStyle(color: textDim)))
          else
            AppCard(
              child: Column(
                children: today
                    .map((e) => EntryRow(
                          entry: e,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => AddPage(
                                      state: state, existing: e))),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniCard(String label, int amount, Color color) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: textSoft, fontSize: 12)),
          const SizedBox(height: 4),
          Text(formatTaka(amount),
              style: TextStyle(
                  color: color, fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAlerts(BuildContext context,
      List<MapEntry<String, int>> warnings, Map<String, int> spend) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('নোটিফিকেশন',
                style: TextStyle(
                    color: textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (warnings.isEmpty)
              const Text('কোনো সতর্কতা নেই — সব বাজেটের ভেতরে আছে',
                  style: TextStyle(color: textSoft))
            else
              ...warnings.map((b) {
                final spent = spend[b.key] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                      '⚠ ${b.key}: ${formatTaka(spent)} / ${formatTaka(b.value)}',
                      style: const TextStyle(color: amber)),
                );
              }),
            if (state.lendTotal > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('💰 পাওনা আছে ${formatTaka(state.lendTotal)}',
                    style: const TextStyle(color: incomeGreen)),
              ),
            if (state.borrowTotal > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('💸 দিতে হবে ${formatTaka(state.borrowTotal)}',
                    style: const TextStyle(color: expenseRed)),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ---------- HISTORY ---------------------------------------------------------
class HistoryPage extends StatefulWidget {
  final AppState state;
  const HistoryPage({super.key, required this.state});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _query = '';
  String _type = 'all'; // all | income | expense
  String _account = 'all';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final list = widget.state.sortedEntries.where((e) {
      if (_type == 'income' && !e.isIncome) return false;
      if (_type == 'expense' && e.isIncome) return false;
      if (_account != 'all' && e.account != _account) return false;
      if (q.isNotEmpty &&
          !e.category.toLowerCase().contains(q) &&
          !e.note.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('হিস্ট্রি',
          style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: textWhite),
              decoration: const InputDecoration(
                hintText: 'খুঁজো — ক্যাটাগরি বা নোট',
                hintStyle: TextStyle(color: textDim),
                prefixIcon: Icon(Icons.search, color: textDim),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _chip('সব', _type == 'all', () => setState(() => _type = 'all')),
                _chip('আয়', _type == 'income',
                    () => setState(() => _type = 'income')),
                _chip('খরচ', _type == 'expense',
                    () => setState(() => _type = 'expense')),
                const SizedBox(width: 8),
                ...['cash', 'bkash', 'nagad', 'bank'].map((a) => _chip(
                    a == 'cash' ? 'Cash' : a == 'bkash' ? 'bKash' : a == 'nagad' ? 'Nagad' : 'Bank',
                    _account == a,
                    () => setState(() => _account = _account == a ? 'all' : a))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text('কোনো এন্ট্রি পাওয়া যায়নি',
                        style: TextStyle(color: textDim)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final e = list[i];
                      final showDate = i == 0 ||
                          dayKey(list[i - 1].date) != dayKey(e.date);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 4),
                              child: Text(shortDate(e.date),
                                  style: const TextStyle(
                                      color: textDim,
                                      fontWeight: FontWeight.bold)),
                            ),
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: EntryRow(
                                entry: e,
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AddPage(
                                            state: widget.state,
                                            existing: e))),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onTap(),
        selectedColor: teal,
        backgroundColor: cardColor,
        labelStyle: TextStyle(
            color: active ? Colors.white : textSoft, fontSize: 13),
        side: const BorderSide(color: borderColor),
      ),
    );
  }
}

// ---------- REPORT ----------------------------------------------------------
class ReportPage extends StatefulWidget {
  final AppState state;
  const ReportPage({super.key, required this.state});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int _monthOffset = 0;

  @override
  Widget build(BuildContext context) {
    final now0 = DateTime.now();
    final now = DateTime(now0.year, now0.month + _monthOffset);
    final spend = widget.state.monthSpendByCategory(now);
    final monthIn = widget.state.monthIn(now);
    final monthOut = widget.state.monthOut(now);
    final title =
        '${monthNames[now.month - 1]} ${now.year}${_monthOffset == 0 ? ' (এই মাস)' : ''}';

    return Scaffold(
      appBar: AppBar(title: const Text('রিপোর্ট',
          style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => _monthOffset--),
                icon: const Icon(Icons.chevron_left, color: textWhite),
              ),
              Text(title,
                  style: const TextStyle(
                      color: textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: _monthOffset < 0
                    ? () => setState(() => _monthOffset++)
                    : null,
                icon: Icon(Icons.chevron_right,
                    color: _monthOffset < 0 ? textWhite : textDim),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                  child: AppCard(
                      child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('আয়', style: TextStyle(color: textSoft)),
                  Text(formatTaka(monthIn),
                      style: const TextStyle(
                          color: incomeGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ))),
              const SizedBox(width: 12),
              Expanded(
                  child: AppCard(
                      child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('খরচ', style: TextStyle(color: textSoft)),
                  Text(formatTaka(monthOut),
                      style: const TextStyle(
                          color: expenseRed,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ))),
            ],
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('কোন খাতে কত গেল',
                    style: TextStyle(
                        color: textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (spend.isEmpty)
                  const Text('এই মাসে এখনো খরচ নেই',
                      style: TextStyle(color: textDim))
                else
                  DonutChart(data: spend, total: monthOut),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('শেষ ৭ দিন — আয় vs খরচ',
                    style: TextStyle(
                        color: textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                WeekBarChart(days: widget.state.last7Days(DateTime.now())),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('সবচেয়ে বেশি খরচ',
                    style: TextStyle(
                        color: textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...(() {
                  final sorted = spend.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  return sorted.take(3).map((e) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                            '${e.key}: ${formatTaka(e.value)}'
                            ' (${monthOut > 0 ? (e.value * 100 / monthOut).round() : 0}%)',
                            style: const TextStyle(color: textSoft)),
                      ));
                })(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- BUDGET ----------------------------------------------------------
class BudgetPage extends StatelessWidget {
  final AppState state;
  const BudgetPage({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final spend = state.monthSpendByCategory(now);
    return Scaffold(
      appBar: AppBar(title: const Text('বাজেট',
          style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          ...state.budgets.entries.map((b) {
            final spent = spend[b.key] ?? 0;
            final pct = b.value > 0 ? spent / b.value : 0;
            final color = pct >= 1
                ? expenseRed
                : pct >= 0.8
                    ? amber
                    : teal;
            final info = categoryInfo(b.key, false);
            return AppCard(
              child: InkWell(
                onTap: () async {
                  final v = await askAmountDialog(context,
                      '${b.key} — মাসের লিমিট', initial: b.value);
                  if (v != null && v > 0) state.setBudget(b.key, v);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(catIcon(info.icon), color: Color(info.color)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(b.key,
                                style: const TextStyle(
                                    color: textWhite,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600))),
                        Text('${formatTaka(spent)} / ${formatTaka(b.value)}',
                            style: const TextStyle(color: textSoft)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0).toDouble(),
                        minHeight: 10,
                        backgroundColor: cardColor2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        pct >= 1
                            ? 'লিমিট পার! বাকি ${formatTaka(spent - b.value)} বেশি'
                            : 'বাকি ${formatTaka(b.value - spent)} (${(pct * 100).round()}%)',
                        style: TextStyle(
                            color: color, fontSize: 12)),
                    const Text('লিমিট বদলাতে চাপো',
                        style: TextStyle(color: textDim, fontSize: 11)),
                  ],
                ),
              ),
            );
          }),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: teal,
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () async {
              final ctx = context; // capture before awaits
              final missing = expenseCategories
                  .where((c) => !state.budgets.containsKey(c.name))
                  .toList();
              if (missing.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('সব ক্যাটাগরির বাজেট আছে')));
                return;
              }
              final picked = await showDialog<String>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  backgroundColor: cardColor,
                  title: const Text('কোন খাতে বাজেট?',
                      style: TextStyle(color: textWhite)),
                  children: missing
                      .map((c) => SimpleDialogOption(
                            onPressed: () => Navigator.pop(ctx, c.name),
                            child: Text(c.name,
                                style: const TextStyle(color: textSoft)),
                          ))
                      .toList(),
                ),
              );
              if (picked != null) {
                final v = await askAmountDialog(
                    // ignore: use_build_context_synchronously
                    ctx, '$picked — মাসের লিমיט');
                if (v != null && v > 0) state.setBudget(picked, v);
              }
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('নতুন বাজেট যোগ করো',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ---------- DHAR / PAWNA ----------------------------------------------------
class DebtsPage extends StatefulWidget {
  final AppState state;
  const DebtsPage({super.key, required this.state});
  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  @override
  Widget build(BuildContext context) {
    final debts = widget.state.debts;
    return Scaffold(
      appBar: AppBar(title: const Text('ধার / পাওনা',
          style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Row(
            children: [
              Expanded(
                  child: AppCard(
                      child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('পাবো', style: TextStyle(color: textSoft)),
                  Text(formatTaka(widget.state.lendTotal),
                      style: const TextStyle(
                          color: incomeGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ))),
              const SizedBox(width: 12),
              Expanded(
                  child: AppCard(
                      child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('দিতে হবে', style: TextStyle(color: textSoft)),
                  Text(formatTaka(widget.state.borrowTotal),
                      style: const TextStyle(
                          color: expenseRed,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ))),
            ],
          ),
          if (debts.isEmpty)
            const AppCard(
                child: Text('কোনো ধার/পাওনা নেই',
                    style: TextStyle(color: textDim))),
          ...debts.map((d) => AppCard(
                child: Row(
                  children: [
                    Icon(d.isLend ? Icons.arrow_downward : Icons.arrow_upward,
                        color: d.isLend ? incomeGreen : expenseRed),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.name,
                              style: TextStyle(
                                  color: textWhite,
                                  fontSize: 15,
                                  decoration: d.settled
                                      ? TextDecoration.lineThrough
                                      : null)),
                          Text(d.isLend ? 'আমাকে দিবে' : 'আমি দিবো',
                              style: const TextStyle(
                                  color: textDim, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(formatTaka(d.amount),
                        style: const TextStyle(
                            color: textWhite, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(
                          d.settled
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: d.settled ? incomeGreen : textDim),
                      onPressed: () =>
                          widget.state.toggleDebtSettled(d.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: expenseRed),
                      onPressed: () => widget.state.deleteDebt(d.id),
                    ),
                  ],
                ),
              )),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: teal,
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () => _addDebt(context),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('ধার / পাওনা যোগ করো',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _addDebt(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    var isLend = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: cardColor,
          title: const Text('ধার / পাওনা যোগ করো',
              style: TextStyle(color: textWhite)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: textWhite),
                decoration: const InputDecoration(hintText: 'কার নাম?'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: textWhite),
                decoration:
                    const InputDecoration(prefixText: '৳ ', hintText: 'টাকা'),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('পাবো'),
                      selected: isLend,
                      onSelected: (_) => setD(() => isLend = true),
                      selectedColor: teal,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('দিতে হবে'),
                      selected: !isLend,
                      onSelected: (_) => setD(() => isLend = false),
                      selectedColor: expenseRed,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('বাতিল',
                    style: TextStyle(color: textDim))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: teal),
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('সেভ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      final amt = int.tryParse(amtCtrl.text) ?? 0;
      if (amt > 0) {
        widget.state.addDebt(Debt(
          id: widget.state.newId(),
          name: nameCtrl.text.trim(),
          isLend: isLend,
          amount: amt,
        ));
      }
    }
  }
}

// ---------- MORE / SETTINGS --------------------------------------------------
class MorePage extends StatelessWidget {
  final AppState state;
  const MorePage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('আরো',
          style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          SectionTitle('ওয়ালেট'),
          ...state.wallets.map((w) => AppCard(
                child: Row(
                  children: [
                    Icon(walletIcon(w.id), color: Color(w.color)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(w.name,
                            style: const TextStyle(
                                color: textWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.w600))),
                    Text(formatTaka(w.balance),
                        style: const TextStyle(
                            color: textWhite, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () async {
                        final v = await askAmountDialog(context,
                            '${w.name} — আসল ব্যালেন্স বসাও',
                            initial: w.balance);
                        if (v != null) {
                          w.balance = v;
                          await state.saveNow();
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('ব্যালেন্স ঠিক করা হয়েছে')));
                        }
                      },
                      child:
                          const Text('ঠিক করো', style: TextStyle(color: cyan)),
                    ),
                  ],
                ),
              )),
          SectionTitle('সঞ্চয় লক্ষ্য'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.savings, color: teal),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(state.goalName,
                            style: const TextStyle(
                                color: textWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.bold))),
                    Text(
                        '${formatTaka(state.goalSaved)} / ${formatTaka(state.goalTarget)}',
                        style: const TextStyle(color: textSoft)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: state.goalTarget > 0
                        ? (state.goalSaved / state.goalTarget).clamp(0.0, 1.0)
                        : 0,
                    minHeight: 10,
                    backgroundColor: cardColor2,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(teal),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: teal)),
                        onPressed: () async {
                          final v = await askAmountDialog(
                              context, 'লক্ষ্যে কত যোগ করবো? (Cash থেকে যাবে)');
                          if (v != null && v > 0) {
                            state.addToGoal(v);
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '${formatTaka(v)} লক্ষ্যে যোগ হয়েছে')));
                          }
                        },
                        child: const Text('টাকা যোগ করো',
                            style: TextStyle(color: teal)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: borderColor)),
                        onPressed: () async {
                          final v = await askAmountDialog(context,
                              'লক্ষ্য কত টাকা?', initial: state.goalTarget);
                          if (v != null && v > 0) state.setGoal(state.goalName, v);
                        },
                        child: const Text('লক্ষ্য বদলাও',
                            style: TextStyle(color: textSoft)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionTitle('ধার / পাওনা'),
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                  'পাবো ${formatTaka(state.lendTotal)}  •  দিতে হবে ${formatTaka(state.borrowTotal)}',
                  style: const TextStyle(color: textWhite)),
              trailing:
                  const Icon(Icons.chevron_right, color: textDim),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DebtsPage(state: state))),
            ),
          ),
          SectionTitle('বাজেট'),
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('মাসের বাজেট দেখো / বদলাও',
                  style: TextStyle(color: textWhite)),
              trailing:
                  const Icon(Icons.chevron_right, color: textDim),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BudgetPage(state: state))),
            ),
          ),
          SectionTitle('সেটিংস'),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('PIN লক',
                      style: TextStyle(color: textWhite)),
                  subtitle: const Text('অ্যাপ খুলতে ৪ সংখ্যার PIN লাগবে',
                      style: TextStyle(color: textDim, fontSize: 12)),
                  value: state.pinEnabled,
                  activeThumbColor: teal,
                  onChanged: (v) async {
                    if (v) {
                      final pin = await _askPin(context);
                      if (pin != null && pin.length == 4) {
                        state.setPin(true, pin);
                      }
                    } else {
                      state.setPin(false, '');
                    }
                  },
                ),
                const Divider(color: borderColor),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.download, color: cyan),
                  title: const Text('ব্যাকআপ — CSV এক্সপোর্ট',
                      style: TextStyle(color: textWhite)),
                  subtitle: const Text('Downloads/Hisab ফোল্ডারে সেভ হবে',
                      style: TextStyle(color: textDim, fontSize: 12)),
                  onTap: () => _exportCsv(context),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.upload, color: cyan),
                  title: const Text('ব্যাকআপ থেকে রিস্টোর',
                      style: TextStyle(color: textWhite)),
                  subtitle: const Text('Downloads/Hisab থেকে CSV পড়বে',
                      style: TextStyle(color: textDim, fontSize: 12)),
                  onTap: () => _importCsv(context),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.copy, color: cyan),
                  title: const Text('CSV কপি করো',
                      style: TextStyle(color: textWhite)),
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: state.toCsv()));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CSV কপি হয়েছে')));
                  },
                ),
                const Divider(color: borderColor),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.science, color: amber),
                  title: const Text('ডেমো ডাটা যোগ করো',
                      style: TextStyle(color: textWhite)),
                  subtitle: const Text('টেস্টের জন্য নমুনা হিসাব বসাবে',
                      style: TextStyle(color: textDim, fontSize: 12)),
                  onTap: () {
                    state.loadDemoData();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ডেমো ডাটা যোগ হয়েছে')));
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.delete_forever, color: expenseRed),
                  title: const Text('সব ডাটা মুছে ফেলো',
                      style: TextStyle(color: expenseRed)),
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: cardColor,
                        title: const Text('সব মুছে যাবে!',
                            style: TextStyle(color: textWhite)),
                        content: const Text(
                            'সব এন্ট্রি, ধার আর লক্ষ্য মুছে যাবে। আগে CSV ব্যাকআপ নিয়ে নাও।',
                            style: TextStyle(color: textSoft)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('বাতিল',
                                  style: TextStyle(color: textDim))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: expenseRed),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('হ্যাঁ, মুছে ফেলো',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) state.clearAll();
                  },
                ),
              ],
            ),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Hisab v1.0.0 • ফ্রি • অফলাইন • শুধু তোমার ফোনে',
                  style: TextStyle(color: textDim, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _askPin(BuildContext context) async {
    final ctrl = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('৪ সংখ্যার PIN বসাও',
            style: TextStyle(color: textWhite)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          style: const TextStyle(color: textWhite, fontSize: 20),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('বাতিল', style: TextStyle(color: textDim))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: teal),
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('সেভ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return v;
  }

  Future<void> _exportCsv(BuildContext context) async {
    try {
      final dir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/Hisab');
      await folder.create(recursive: true);
      final file = File('${folder.path}/hisab-backup.csv');
      await file.writeAsString(state.toCsv());
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ব্যাকআপ সেভ হয়েছে: ${file.path}')));
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ব্যাকআপ হয়নি: $e')));
    }
  }

  Future<void> _importCsv(BuildContext context) async {
    try {
      final dir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/Hisab/hisab-backup.csv');
      if (!await file.exists()) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('ব্যাকআপ ফাইল পাওয়া যায়নি — আগে এক্সপোর্ট করো')));
        return;
      }
      final n = state.importCsv(await file.readAsString());
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(n < 0
              ? 'ফাইলটা Hisab-এর ব্যাকআপ না'
              : '$n টা এন্ট্রি ফিরিয়ে আনা হয়েছে')));
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('রিস্টোর হয়নি: $e')));
    }
  }
}

// ---------- QUICK ADD / EDIT -------------------------------------------------
class AddPage extends StatefulWidget {
  final AppState state;
  final Entry? existing;
  const AddPage({super.key, required this.state, this.existing});
  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  bool _isIncome = false;
  String _amount = '';
  String _category = 'Khabar';
  String _account = 'cash';
  DateTime _date = DateTime.now();
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _isIncome = e.isIncome;
      _amount = '${e.amount}';
      _category = e.category;
      _account = e.account;
      _date = e.date;
      _noteCtrl.text = e.note;
    }
  }

  List<CategoryInfo> get _cats =>
      _isIncome ? incomeCategories : expenseCategories;

  void _pressKey(String k) {
    setState(() {
      if (k == '⌫') {
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
      } else if (k == '00') {
        if (_amount.isNotEmpty && _amount.length < 8) _amount += '00';
      } else {
        if (_amount.length < 9) {
          if (_amount == '0') {
            _amount = k;
          } else {
            _amount += k;
          }
        }
      }
    });
  }

  void _save() {
    final amt = int.tryParse(_amount) ?? 0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('আগে টাকার অংক বসাও')));
      return;
    }
    final e = widget.existing;
    if (e != null) {
      widget.state.updateEntry(Entry(
        id: e.id,
        isIncome: _isIncome,
        amount: amt,
        category: _category,
        account: _account,
        note: _noteCtrl.text.trim(),
        date: _date,
      ));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ এন্ট্রি ঠিক করা হয়েছে')));
    } else {
      widget.state.addEntry(Entry(
        id: widget.state.newId(),
        isIncome: _isIncome,
        amount: amt,
        category: _category,
        account: _account,
        note: _noteCtrl.text.trim(),
        date: _date,
      ));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '✓ ${formatTaka(amt)} যোগ হয়েছে')));
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final e = widget.existing;
    if (e == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('এন্ট্রি মুছে ফেলবো?',
            style: TextStyle(color: textWhite)),
        content: Text('${e.category} ${formatTaka(e.amount)}',
            style: const TextStyle(color: textSoft)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('বাতিল', style: TextStyle(color: textDim))),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: expenseRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছে ফেলো',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      widget.state.deleteEntry(e.id);
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'এন্ট্রি ঠিক করো' : 'নতুন এন্ট্রি',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: expenseRed),
              onPressed: _delete,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type toggle
                  Row(
                    children: [
                      Expanded(
                          child: _typeBtn(false, 'খরচ', expenseRed)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _typeBtn(true, 'আয়', incomeGreen)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Amount display
                  Center(
                    child: Text(
                      _amount.isEmpty
                          ? '৳0'
                          : formatTaka(int.parse(_amount)),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: _isIncome ? incomeGreen : expenseRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Keypad (min 48px keys)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.4,
                    ),
                    itemCount: 12,
                    itemBuilder: (ctx, i) {
                      const keys = [
                        '1', '2', '3', '4', '5', '6',
                        '7', '8', '9', '00', '0', '⌫',
                      ];
                      final k = keys[i];
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cardColor,
                          minimumSize: const Size(48, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: borderColor),
                          ),
                        ),
                        onPressed: () => _pressKey(k),
                        child: Text(k,
                            style: const TextStyle(
                                color: textWhite, fontSize: 22)),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('ক্যাটাগরি',
                      style: TextStyle(
                          color: textWhite, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _cats.map((c) {
                      final active = _category == c.name;
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(catIcon(c.icon), size: 16,
                                color: active
                                    ? Colors.white
                                    : Color(c.color)),
                            const SizedBox(width: 4),
                            Text(c.name),
                          ],
                        ),
                        selected: active,
                        onSelected: (_) =>
                            setState(() => _category = c.name),
                        selectedColor: Color(c.color),
                        backgroundColor: cardColor,
                        labelStyle: TextStyle(
                            color: active ? Colors.white : textSoft),
                        side: const BorderSide(color: borderColor),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('কোন ওয়ালেট থেকে?',
                      style: TextStyle(
                          color: textWhite, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.state.wallets.map((w) {
                      final active = _account == w.id;
                      return ChoiceChip(
                        label: Text(
                            '${w.name} (${formatTaka(w.balance)})'),
                        selected: active,
                        onSelected: (_) =>
                            setState(() => _account = w.id),
                        selectedColor: Color(w.color),
                        backgroundColor: cardColor,
                        labelStyle: TextStyle(
                            color: active ? Colors.white : textSoft),
                        side: const BorderSide(color: borderColor),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteCtrl,
                    style: const TextStyle(color: textWhite),
                    decoration: const InputDecoration(
                        hintText: 'নোট (ঐচ্ছিক)',
                        hintStyle: TextStyle(color: textDim)),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.calendar_today, color: cyan),
                    title: Text(
                        'তারিখ: ${shortDate(_date)}',
                        style: const TextStyle(color: textWhite)),
                    trailing: const Text('বদলাও',
                        style: TextStyle(color: cyan)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(
                            const Duration(days: 1)),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: teal,
                              surface: cardColor,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() => _date = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          // Save pinned at bottom, always visible
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isIncome ? incomeGreen : expenseRed,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _save,
              child: Text(isEdit ? 'সেভ করো' : 'যোগ করো',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeBtn(bool income, String label, Color color) {
    final active = _isIncome == income;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? color : cardColor,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: active ? color : borderColor),
        ),
      ),
      onPressed: () {
        setState(() {
          _isIncome = income;
          _category = _cats.first.name;
        });
      },
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}
