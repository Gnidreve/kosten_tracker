import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

const _cream = Color(0xFFF6EDC3);
const _paper = Color(0xFFFFF9E6);
const _ink = Color(0xFF2F2118);
const _flameRed = Color(0xFFFF3B1F);
const _ember = Color(0xFFFFC928);
const _moneyGreen = Color(0xFF89DA35);

BoxDecoration _panelDecoration(
  Color color, {
  Color borderColor = _ink,
  double radius = 22,
  Offset shadowOffset = const Offset(0, 6),
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor, width: 3),
    boxShadow: [
      BoxShadow(
        color: borderColor.withValues(alpha: 0.18),
        offset: shadowOffset,
        blurRadius: 0,
      ),
    ],
  );
}

// ─────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DB.instance.init();
  runApp(const TrackerApp());
}

// ─────────────────────────────────────────────
// APP ROOT
// ─────────────────────────────────────────────

class TrackerApp extends StatelessWidget {
  const TrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.spaceGroteskTextTheme(
      ThemeData.light().textTheme,
    ).apply(bodyColor: _ink, displayColor: _ink);

    return MaterialApp(
      title: 'Stop the Bleeding!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: _flameRed,
          secondary: _moneyGreen,
          surface: _paper,
          onSurface: _ink,
          error: _flameRed,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: _cream,
        canvasColor: _cream,
        dialogTheme: DialogThemeData(
          backgroundColor: _paper,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: _ink, width: 3),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          modalBackgroundColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _cream,
          indicatorColor: _moneyGreen,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: states.contains(WidgetState.selected) ? _ink : _ink,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            return IconThemeData(
              color: _ink,
              size: states.contains(WidgetState.selected) ? 24 : 20,
            );
          }),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 54,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _flameRed,
          foregroundColor: _paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _ink, width: 3),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _paper,
          labelStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _ink, width: 3),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _ink, width: 3),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _flameRed, width: 3),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _flameRed, width: 3),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _flameRed, width: 3),
          ),
        ),
        textTheme: baseTextTheme.copyWith(
          headlineMedium: GoogleFonts.bungee(
            fontSize: 31,
            fontWeight: FontWeight.w400,
            color: _ink,
            height: 0.95,
          ),
          titleLarge: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
          bodyLarge: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
          bodyMedium: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
          labelLarge: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
      ),
      home: const HomeShell(),
    );
  }
}

// ─────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────

enum Interval_ { monthly, quarterly, yearly }

extension IntervalLabel on Interval_ {
  String get label {
    switch (this) {
      case Interval_.monthly:
        return 'Monatlich';
      case Interval_.quarterly:
        return 'Quartalsweise';
      case Interval_.yearly:
        return 'Jährlich';
    }
  }

  double get monthlyFactor {
    switch (this) {
      case Interval_.monthly:
        return 1.0;
      case Interval_.quarterly:
        return 1 / 3.0;
      case Interval_.yearly:
        return 1 / 12.0;
    }
  }

  static Interval_ fromString(String s) {
    return Interval_.values.firstWhere(
      (e) => e.name == s,
      orElse: () => Interval_.monthly,
    );
  }
}

class Fixkosten {
  final int? id;
  final String name;
  final String description;
  final double amount;
  final Interval_ interval;

  const Fixkosten({
    this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.interval,
  });

  double get monthlyAmount => amount * interval.monthlyFactor;
  double get yearlyAmount => monthlyAmount * 12;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'description': description,
    'amount': amount,
    'interval': interval.name,
  };

  factory Fixkosten.fromMap(Map<String, dynamic> m) => Fixkosten(
    id: m['id'] as int?,
    name: m['name'] as String,
    description: m['description'] as String? ?? '',
    amount: (m['amount'] as num).toDouble(),
    interval: IntervalLabel.fromString(m['interval'] as String),
  );

  Fixkosten copyWith({
    int? id,
    String? name,
    String? description,
    double? amount,
    Interval_? interval,
  }) => Fixkosten(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    interval: interval ?? this.interval,
  );
}

// ─────────────────────────────────────────────
// DATABASE
// ─────────────────────────────────────────────

class DB {
  DB._();
  static final DB instance = DB._();

  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'tracker.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE fixkosten (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    NOT NULL,
            description TEXT    NOT NULL DEFAULT '',
            amount      REAL    NOT NULL,
            interval    TEXT    NOT NULL DEFAULT 'monthly'
          )
        ''');
        // Optional view – aggregated monthly totals per interval bucket
        await db.execute('''
          CREATE VIEW IF NOT EXISTS v_summary AS
          SELECT
            interval,
            COUNT(*)                        AS count,
            SUM(amount)                     AS raw_sum,
            SUM(CASE
              WHEN interval = 'monthly'     THEN amount
              WHEN interval = 'quarterly'   THEN amount / 3.0
              WHEN interval = 'yearly'      THEN amount / 12.0
              ELSE 0
            END)                            AS monthly_equiv
          FROM fixkosten
          GROUP BY interval
        ''');
      },
    );
  }

  Database get _database => _db!;

  Future<List<Fixkosten>> getAll() async {
    final rows = await _database.query('fixkosten', orderBy: 'name ASC');
    return rows.map(Fixkosten.fromMap).toList();
  }

  Future<int> insert(Fixkosten f) => _database.insert('fixkosten', f.toMap());

  Future<int> update(Fixkosten f) => _database.update(
    'fixkosten',
    f.toMap(),
    where: 'id = ?',
    whereArgs: [f.id],
  );

  Future<int> delete(int id) =>
      _database.delete('fixkosten', where: 'id = ?', whereArgs: [id]);
}

// ─────────────────────────────────────────────
// STATE  (simple ValueNotifier – no extra package)
// ─────────────────────────────────────────────

class AppState extends ChangeNotifier {
  List<Fixkosten> _items = [];
  List<Fixkosten> get items => _items;

  Future<void> load() async {
    _items = await DB.instance.getAll();
    notifyListeners();
  }

  Future<void> save(Fixkosten f) async {
    if (f.id == null) {
      await DB.instance.insert(f);
    } else {
      await DB.instance.update(f);
    }
    await load();
  }

  Future<void> remove(int id) async {
    await DB.instance.delete(id);
    await load();
  }
}

// ─────────────────────────────────────────────
// HOME SHELL  (BottomNavBar)
// ─────────────────────────────────────────────

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _state = AppState();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _state.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        return Scaffold(
          body: _tab == 0
              ? DashboardPage(items: _state.items)
              : ListPage(
                  items: _state.items,
                  onSave: _state.save,
                  onDelete: _state.remove,
                ),
          floatingActionButton: _tab == 1
              ? FloatingActionButton(
                  onPressed: () => _openSheet(context, null),
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            decoration: _panelDecoration(
              _paper,
              radius: 28,
              shadowOffset: const Offset(0, 4),
            ),
            child: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Übersicht',
                ),
                NavigationDestination(
                  icon: Icon(Icons.list_outlined),
                  selectedIcon: Icon(Icons.list),
                  label: 'Liste',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSheet(BuildContext context, Fixkosten? item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          EntrySheet(item: item, onSave: _state.save, onDelete: _state.remove),
    );
  }
}

// ─────────────────────────────────────────────
// DASHBOARD PAGE
// ─────────────────────────────────────────────

class DashboardPage extends StatelessWidget {
  final List<Fixkosten> items;
  const DashboardPage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final totalMonthly = items.fold<double>(0, (s, i) => s + i.monthlyAmount);
    final totalQuarterly = totalMonthly * 3;
    final totalYearly = totalMonthly * 12;

    final monthlyOnly = items
        .where((i) => i.interval == Interval_.monthly)
        .fold<double>(0, (s, i) => s + i.amount);
    final quarterlyOnly = items
        .where((i) => i.interval == Interval_.quarterly)
        .fold<double>(0, (s, i) => s + i.amount);
    final yearlyOnly = items
        .where((i) => i.interval == Interval_.yearly)
        .fold<double>(0, (s, i) => s + i.amount);

    final kpis = [
      _KPI(
        label: 'Jährliche Belastung',
        value: _fmt(totalYearly),
        subtitle: 'normalisiert',
        icon: Icons.calendar_today,
        accent: const Color(0xFFFF7043),
      ),
      _KPI(
        label: 'Jahresposten',
        value: _fmt(yearlyOnly),
        subtitle: 'Rohsumme / Jahr',
        icon: Icons.event_repeat,
        accent: const Color(0xFF66BB6A),
      ),
      _KPI(
        label: 'Quartalsmäßige Belastung',
        value: _fmt(totalQuarterly),
        subtitle: 'normalisiert',
        icon: Icons.calendar_view_month,
        accent: const Color(0xFF7E57C2),
      ),
      _KPI(
        label: 'Quartalsposten',
        value: _fmt(quarterlyOnly),
        subtitle: 'Rohsumme / Quartal',
        icon: Icons.repeat_on,
        accent: const Color(0xFF26C6DA),
      ),
      _KPI(
        label: 'Monatliche Belastung',
        value: _fmt(totalMonthly),
        subtitle: 'normalisiert',
        icon: Icons.calendar_month,
        accent: const Color(0xFFEF5350),
      ),
      _KPI(
        label: 'Monatliche Posten',
        value: _fmt(monthlyOnly),
        subtitle: 'Rohsumme / Monat',
        icon: Icons.repeat,
        accent: const Color(0xFF42A5F5),
      ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  'Stop the Bleeding!',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(letterSpacing: -1.1),
                ),
              ),
            ),
            const SizedBox(height: 32),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.84,
              ),
              itemCount: kpis.length,
              itemBuilder: (_, i) => _KPICard(kpi: kpis[i]),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      '${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} €';
}

class _KPI {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _KPI({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });
}

class _KPICard extends StatelessWidget {
  final _KPI kpi;
  const _KPICard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final cardColor = Color.alphaBlend(
      kpi.accent.withValues(alpha: 0.18),
      _paper,
    );
    return Container(
      decoration: _panelDecoration(cardColor),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: _panelDecoration(
                  kpi.accent,
                  radius: 14,
                  shadowOffset: const Offset(0, 2),
                ),
                child: Icon(kpi.icon, size: 18, color: _ink),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            kpi.value,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: _panelDecoration(
              kpi.accent,
              radius: 14,
              shadowOffset: const Offset(0, 2),
            ),
            child: Text(
              kpi.label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: _ink,
              ),
              maxLines: 2,
              overflow: TextOverflow.fade,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            kpi.subtitle,
            style: TextStyle(
              fontSize: 10,
              color: _ink.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LIST PAGE
// ─────────────────────────────────────────────

class ListPage extends StatelessWidget {
  final List<Fixkosten> items;
  final Future<void> Function(Fixkosten) onSave;
  final Future<void> Function(int) onDelete;

  const ListPage({
    super.key,
    required this.items,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: _panelDecoration(_paper),
            child: const Text(
              'Noch keine Einträge.\nTippe auf + um zu starten.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
        itemCount: items.length,
        separatorBuilder: (_, index) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          return _EntryTile(
            item: item,
            onEdit: () => _openSheet(context, item),
          );
        },
      ),
    );
  }

  void _openSheet(BuildContext context, Fixkosten item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          EntrySheet(item: item, onSave: onSave, onDelete: onDelete),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final Fixkosten item;
  final VoidCallback onEdit;

  const _EntryTile({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(_paper, radius: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onEdit,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.68),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(children: [_Chip(item.interval.label)]),
              ],
            ),
            trailing: Text(
              '${item.amount.toStringAsFixed(2)} €',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: _flameRed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: _panelDecoration(
        _moneyGreen,
        radius: 999,
        shadowOffset: const Offset(0, 2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: _ink,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ENTRY BOTTOM SHEET
// ─────────────────────────────────────────────

class EntrySheet extends StatefulWidget {
  final Fixkosten? item;
  final Future<void> Function(Fixkosten) onSave;
  final Future<void> Function(int)? onDelete;

  const EntrySheet({super.key, this.item, required this.onSave, this.onDelete});

  @override
  State<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<EntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _amount;
  late Interval_ _interval;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.name ?? '');
    _desc = TextEditingController(text: widget.item?.description ?? '');
    _amount = TextEditingController(
      text: widget.item != null ? widget.item!.amount.toStringAsFixed(2) : '',
    );
    _interval = widget.item?.interval ?? Interval_.monthly;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final entry = Fixkosten(
      id: widget.item?.id,
      name: _name.text.trim(),
      description: _desc.text.trim(),
      amount: double.parse(_amount.text.trim().replaceAll(',', '.')),
      interval: _interval,
    );
    await widget.onSave(entry);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final currentItem = widget.item;
    if (currentItem == null ||
        currentItem.id == null ||
        widget.onDelete == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eintrag löschen'),
        content: Text('„${currentItem.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Löschen',
              style: TextStyle(color: _flameRed, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    await widget.onDelete!(currentItem.id!);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: _panelDecoration(_paper, radius: 28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isEdit ? 'Eintrag bearbeiten' : 'Neuer Eintrag',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if (isEdit && widget.onDelete != null)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      decoration: _panelDecoration(
                        const Color(0xFFFFD5CF),
                        radius: 14,
                        shadowOffset: const Offset(0, 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Löschen',
                        color: _flameRed,
                        onPressed: _saving ? null : _delete,
                      ),
                    ),
                  Container(
                    decoration: _panelDecoration(
                      _ember,
                      radius: 14,
                      shadowOffset: const Offset(0, 2),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      color: _ink,
                      onPressed: _saving ? null : () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _Field(
                controller: _name,
                label: 'Name',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
              ),
              const SizedBox(height: 14),
              _Field(controller: _desc, label: 'Beschreibung', maxLines: 2),
              const SizedBox(height: 14),
              _Field(
                controller: _amount,
                label: 'Betrag (€)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Pflichtfeld';
                  final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Ungültiger Betrag';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<Interval_>(
                initialValue: _interval,
                decoration: const InputDecoration(labelText: 'Intervall'),
                dropdownColor: _paper,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
                items: Interval_.values
                    .map(
                      (i) => DropdownMenuItem(value: i, child: Text(i.label)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _interval = v!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _moneyGreen,
                    foregroundColor: _ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: _ink, width: 3),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _ink,
                          ),
                        )
                      : Text(
                          isEdit ? 'Speichern' : 'Hinzufügen',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
      decoration: InputDecoration(labelText: label),
    );
  }
}
