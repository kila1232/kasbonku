import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kPrimary = Color(0xFFE76F51);
const Color kBg = Color(0xFFFFF8F0);
const Color kText = Color(0xFF2D2A26);
const Color kMuted = Color(0xFF7A6F68);
const Color kGreen = Color(0xFF2A9D8F);
const Color kRed = Color(0xFFD62828);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(KasbonApp(store: BonStore(prefs)));
}

class KasbonApp extends StatelessWidget {
  final BonStore store;
  const KasbonApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KasbonKu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimary).copyWith(
          primary: kPrimary,
          onPrimary: Colors.white,
        ),
        scaffoldBackgroundColor: kBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          foregroundColor: kText,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      builder: (context, child) {
        return ColoredBox(
          color: const Color(0xFFEDE4DA),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      home: HomeScreen(store: store),
    );
  }
}

/* ----------------------------- MODEL ----------------------------- */

class BonItem {
  final String nama;
  final int qty;
  final int harga;

  const BonItem({required this.nama, required this.qty, required this.harga});

  int get subtotal => qty * harga;

  Map<String, dynamic> toJson() => {'nama': nama, 'qty': qty, 'harga': harga};

  factory BonItem.fromJson(Map<String, dynamic> json) => BonItem(
        nama: json['nama'] as String? ?? '',
        qty: (json['qty'] as num?)?.toInt() ?? 1,
        harga: (json['harga'] as num?)?.toInt() ?? 0,
      );
}

class Bon {
  final String id;
  final String warung;
  final DateTime tanggal;
  final List<BonItem> items;
  int dibayar;
  final String catatan;

  Bon({
    required this.id,
    required this.warung,
    required this.tanggal,
    required this.items,
    required this.dibayar,
    required this.catatan,
  });

  int get total => items.fold(0, (sum, item) => sum + item.subtotal);
  int get sisa => total - dibayar;
  bool get lunas => sisa <= 0;
  String get status =>
      lunas ? 'Lunas' : (dibayar > 0 ? 'Dibayar sebagian' : 'Belum bayar');

  Map<String, dynamic> toJson() => {
        'id': id,
        'warung': warung,
        'tanggal': tanggal.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'dibayar': dibayar,
        'catatan': catatan,
      };

  factory Bon.fromJson(Map<String, dynamic> json) => Bon(
        id: json['id'] as String? ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        warung: json['warung'] as String? ?? 'Warung',
        tanggal: DateTime.tryParse(json['tanggal'] as String? ?? '') ??
            DateTime.now(),
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => BonItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        dibayar: (json['dibayar'] as num?)?.toInt() ?? 0,
        catatan: json['catatan'] as String? ?? '',
      );
}

class BonStore {
  final SharedPreferences prefs;
  final List<Bon> bons = [];

  BonStore(this.prefs) {
    final raw = prefs.getString('bons_v1');
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      bons.addAll(
        list.map((e) => Bon.fromJson(Map<String, dynamic>.from(e as Map))),
      );
    } catch (_) {
      // Data rusak diabaikan supaya aplikasi tetap bisa dibuka.
    }
  }

  Future<void> save() async {
    await prefs.setString(
      'bons_v1',
      jsonEncode(bons.map((b) => b.toJson()).toList()),
    );
  }
}

/* ----------------------------- HELPERS ----------------------------- */

int parseAngka(String value) =>
    int.tryParse(value.replaceAll('.', '').replaceAll(' ', '')) ?? 0;

String rupiah(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return 'Rp${buffer.toString()}';
}

const List<String> _bulan = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String tanggalPendek(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String tanggalPanjang(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

InputDecoration deco(String label, {String? hint, String? prefix}) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide.none,
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefix,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    border: border,
    enabledBorder: border,
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: kPrimary, width: 1.5),
    ),
  );
}

/* ----------------------------- HOME ----------------------------- */

class HomeScreen extends StatefulWidget {
  final BonStore store;
  const HomeScreen({super.key, required this.store});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _openForm() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BonFormScreen(store: widget.store)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openDetail(Bon bon) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BonDetailScreen(store: widget.store, bon: bon),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bons = [...widget.store.bons]
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
    final aktif = bons.where((b) => !b.lunas).toList();
    final lunas = bons.where((b) => b.lunas).toList();
    final totalAktif = aktif.fold<int>(0, (sum, b) => sum + b.sisa);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KasbonKu',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Bon tercatat, bayar tenang',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: kMuted,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Bon baru',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _TotalCard(total: totalAktif, jumlah: aktif.length),
          const SizedBox(height: 20),
          if (bons.isEmpty)
            _EmptyState(onTap: _openForm)
          else ...[
            const _SectionTitle('Bon aktif'),
            const SizedBox(height: 10),
            if (aktif.isEmpty)
              const _InfoCard(text: 'Semua bon sudah lunas. Mantap!')
            else
              ...aktif.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BonCard(bon: b, onTap: () => _openDetail(b)),
                ),
              ),
            if (lunas.isNotEmpty) ...[
              const SizedBox(height: 14),
              const _SectionTitle('Riwayat lunas'),
              const SizedBox(height: 10),
              ...lunas.take(5).map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BonCard(bon: b, onTap: () => _openDetail(b)),
                    ),
                  ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final int total;
  final int jumlah;

  const _TotalCard({required this.total, required this.jumlah});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [kPrimary, Color(0xFFF4A261)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33E76F51),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Total kasbon aktif',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              rupiah(total),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$jumlah bon belum lunas',
            style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: kText,
        ),
      );
}

class _InfoCard extends StatelessWidget {
  final String text;
  const _InfoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F3EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1B7F6B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8E0),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.menu_book, size: 38, color: kPrimary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada bon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: kText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Catat bon pertamamu supaya tidak perlu mengingat-ingat lagi.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: kMuted, height: 1.4),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add),
            label: const Text('Catat bon pertama'),
          ),
        ],
      ),
    );
  }
}

class BonCard extends StatelessWidget {
  final Bon bon;
  final VoidCallback onTap;

  const BonCard({super.key, required this.bon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront, color: kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bon.warung,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: kText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tanggalPendek(bon.tanggal),
                      style: const TextStyle(fontSize: 12, color: kMuted),
                    ),
                    const SizedBox(height: 6),
                    StatusChip(bon.status),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rupiah(bon.total),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: kText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bon.lunas ? 'Lunas' : 'Sisa ${rupiah(bon.sisa)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: bon.lunas ? kGreen : kMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (status) {
      case 'Lunas':
        bg = const Color(0xFFD8F3EC);
        fg = const Color(0xFF1B7F6B);
        break;
      case 'Dibayar sebagian':
        bg = const Color(0xFFFFE8CC);
        fg = const Color(0xFFB25E00);
        break;
      default:
        bg = const Color(0xFFFFE1DE);
        fg = const Color(0xFFB3261E);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

/* ----------------------------- DETAIL ----------------------------- */

class BonDetailScreen extends StatefulWidget {
  final BonStore store;
  final Bon bon;

  const BonDetailScreen({super.key, required this.store, required this.bon});

  @override
  State<BonDetailScreen> createState() => _BonDetailScreenState();
}

class _BonDetailScreenState extends State<BonDetailScreen> {
  Bon get bon => widget.bon;

  Future<void> _bayar() async {
    final nominal = await showDialog<int>(
      context: context,
      builder: (_) => PaymentDialog(max: bon.sisa),
    );
    if (nominal == null) return;
    setState(() {
      bon.dibayar += nominal;
    });
    await widget.store.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pembayaran ${rupiah(nominal)} tercatat')),
    );
  }

  Future<void> _hapus() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus bon?'),
        content: Text(
          'Bon di ${bon.warung} sebesar ${rupiah(bon.total)} akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    widget.store.bons.removeWhere((b) => b.id == bon.id);
    await widget.store.save();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Bon')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE8E0),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.storefront, color: kPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bon.warung,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tanggalPanjang(bon.tanggal),
                            style: const TextStyle(
                              fontSize: 12,
                              color: kMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(bon.status),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  rupiah(bon.total),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: kText,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Dibayar',
                        value: rupiah(bon.dibayar),
                        color: kGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                        label: 'Sisa',
                        value: rupiah(bon.sisa),
                        color: bon.lunas ? kGreen : kRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Rincian item'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                ...List.generate(bon.items.length, (index) {
                  final item = bon.items[index];
                  return Column(
                    children: [
                      if (index > 0)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: kText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.qty} x ${rupiah(item.harga)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: kMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              rupiah(item.subtotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: kText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                      Text(
                        rupiah(bon.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (bon.catatan.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Catatan: ${bon.catatan}',
                style: const TextStyle(fontSize: 13, color: kText),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (!bon.lunas)
            FilledButton.icon(
              onPressed: _bayar,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Bayar Kasbon'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          if (!bon.lunas) const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _hapus,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Hapus Bon'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: kRed,
              side: const BorderSide(color: Color(0x33D62828)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: kMuted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentDialog extends StatefulWidget {
  final int max;
  const PaymentDialog({super.key, required this.max});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _isi(int n) {
    setState(() {
      _controller.text = '$n';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bayar Kasbon'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sisa kasbon ${rupiah(widget.max)}',
            style: const TextStyle(fontSize: 13, color: kMuted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: deco('Jumlah bayar', prefix: 'Rp ')
                .copyWith(errorText: _error),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => _isi(widget.max),
                child: const Text('Lunasi'),
              ),
              TextButton(
                onPressed: () => _isi(widget.max ~/ 2),
                child: const Text('Setengah'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final n = parseAngka(_controller.text);
            if (n <= 0 || n > widget.max) {
              setState(() => _error = 'Nominal harus 1 - ${rupiah(widget.max)}');
              return;
            }
            Navigator.pop(context, n);
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

/* ----------------------------- FORM ----------------------------- */

class BonFormScreen extends StatefulWidget {
  final BonStore store;
  const BonFormScreen({super.key, required this.store});

  @override
  State<BonFormScreen> createState() => _BonFormScreenState();
}

class _BonFormScreenState extends State<BonFormScreen> {
  final _warung = TextEditingController(text: 'Warung Mang');
  final _catatan = TextEditingController();
  final List<_ItemDraft> _items = [_ItemDraft()];

  int get _total => _items.fold(
        0,
        (sum, item) => sum + item.qty * parseAngka(item.harga.text),
      );

  @override
  void dispose() {
    _warung.dispose();
    _catatan.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _tambahItem() => setState(() => _items.add(_ItemDraft()));

  void _hapusItem(int index) {
    setState(() {
      _items.removeAt(index);
      if (_items.isEmpty) _items.add(_ItemDraft());
    });
  }

  void _tambahCepat(String nama, int harga) {
    setState(() {
      final kosong = _items.indexWhere(
        (e) => e.nama.text.trim().isEmpty && e.harga.text.trim().isEmpty,
      );
      if (kosong >= 0) {
        _items[kosong].nama.text = nama;
        _items[kosong].harga.text = '$harga';
      } else {
        _items.add(_ItemDraft(nama: nama, harga: '$harga'));
      }
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _simpan() async {
    final warung = _warung.text.trim();
    if (warung.isEmpty) {
      _snack('Nama warung wajib diisi');
      return;
    }
    final items = <BonItem>[];
    for (final draft in _items) {
      final nama = draft.nama.text.trim();
      final harga = parseAngka(draft.harga.text);
      if (nama.isEmpty) continue;
      if (harga <= 0) {
        _snack('Harga $nama harus lebih dari 0');
        return;
      }
      if (draft.qty <= 0) {
        _snack('Qty $nama harus lebih dari 0');
        return;
      }
      items.add(BonItem(nama: nama, qty: draft.qty, harga: harga));
    }
    if (items.isEmpty) {
      _snack('Tambahkan minimal satu item');
      return;
    }
    final bon = Bon(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      warung: warung,
      tanggal: DateTime.now(),
      items: items,
      dibayar: 0,
      catatan: _catatan.text.trim(),
    );
    widget.store.bons.insert(0, bon);
    await widget.store.save();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bon Baru')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(
            controller: _warung,
            textCapitalization: TextCapitalization.words,
            decoration: deco('Nama warung', hint: 'Contoh: Warung Mang'),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Item bon'),
          const SizedBox(height: 4),
          const Text(
            'Tap menu cepat, atau isi manual di bawah.',
            style: TextStyle(fontSize: 12, color: kMuted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Magelangan 14k'),
                onPressed: () => _tambahCepat('Magelangan', 14000),
              ),
              ActionChip(
                label: const Text('Es Teh 4k'),
                onPressed: () => _tambahCepat('Es Teh', 4000),
              ),
              ActionChip(
                label: const Text('Sate 10k'),
                onPressed: () => _tambahCepat('Sate', 10000),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(
            _items.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildItemCard(index),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _tambahItem,
              icon: const Icon(Icons.add),
              label: const Text('Tambah item manual'),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _catatan,
            decoration: deco(
              'Catatan (opsional)',
              hint: 'Contoh: bon makan siang',
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 11, color: kMuted),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        rupiah(_total),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: kText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _simpan,
                icon: const Icon(Icons.check),
                label: const Text('Simpan Bon'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];
    final subtotal = item.qty * parseAngka(item.harga.text);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: item.nama,
                  decoration: deco('Nama item', hint: 'Contoh: Magelangan'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _hapusItem(index),
                icon: const Icon(Icons.close, size: 20),
                color: kMuted,
                tooltip: 'Hapus item',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: item.harga,
                  keyboardType: TextInputType.number,
                  decoration: deco('Harga satuan', prefix: 'Rp '),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              _QtyStepper(
                qty: item.qty,
                onMinus:
                    item.qty > 1 ? () => setState(() => item.qty--) : null,
                onPlus: () => setState(() => item.qty++),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Subtotal  ${rupiah(subtotal)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemDraft {
  final TextEditingController nama;
  final TextEditingController harga;
  int qty;

  _ItemDraft({String nama = '', String harga = '', this.qty = 1})
      : nama = TextEditingController(text: nama),
        harga = TextEditingController(text: harga);

  void dispose() {
    nama.dispose();
    harga.dispose();
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  const _QtyStepper({
    required this.qty,
    this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onMinus,
            icon: const Icon(Icons.remove, size: 18),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            padding: EdgeInsets.zero,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: kText,
              ),
            ),
          ),
          IconButton(
            onPressed: onPlus,
            icon: const Icon(Icons.add, size: 18),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
