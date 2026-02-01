import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/reports_provider.dart';
import '../format.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  int _preset = 1; // 1: today, 7, 30, 0: custom

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().load(from: Format.ymd(_from), to: Format.ymd(_to));
    });
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      _from = picked;
      _preset = 0;
    });
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      _to = picked;
      _preset = 0;
    });
  }

  void _presetDays(int days) {
    final now = DateTime.now();
    setState(() {
      _to = now;
      _from = now.subtract(Duration(days: days - 1));
      _preset = days;
    });
    context.read<ReportsProvider>().load(from: Format.ymd(_from), to: Format.ymd(_to));
  }

  Future<void> _refresh() async {
    await context.read<ReportsProvider>().load(from: Format.ymd(_from), to: Format.ymd(_to));
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ReportsProvider>();
    final e = rp.employee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        actions: [
          IconButton(
            onPressed: rp.loading
                ? null
                : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RangeCard(
                from: _from,
                to: _to,
                preset: _preset,
                onFrom: _pickFrom,
                onTo: _pickTo,
                onPreset: _presetDays,
              ),
              if (rp.loading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(minHeight: 2),
              ],
              if (rp.error != null) ...[
                const SizedBox(height: 12),
                _ErrorCard(message: rp.error!),
              ],
              const SizedBox(height: 12),
              if (rp.loading && e == null)
                const _KpiSkeleton()
              else
                _KpiGrid(
                  ordersCount: e?.ordersCount ?? 0,
                  ordersTotal: e?.ordersTotal ?? 0,
                ),
              const SizedBox(height: 12),
              _SummaryCard(
                ordersCount: e?.ordersCount ?? 0,
                ordersTotal: e?.ordersTotal ?? 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeCard extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final int preset;
  final VoidCallback onFrom;
  final VoidCallback onTo;
  final void Function(int days) onPreset;

  const _RangeCard({
    required this.from,
    required this.to,
    required this.preset,
    required this.onFrom,
    required this.onTo,
    required this.onPreset,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.calendar_month, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الفترة', style: TextStyle(fontWeight: FontWeight.w900)),
                    SizedBox(height: 2),
                    Text('اختر التاريخ أو استخدم الاختصارات', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onFrom,
                  icon: const Icon(Icons.event),
                  label: Text('من: ${Format.dmy(from)}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onTo,
                  icon: const Icon(Icons.event),
                  label: Text('إلى: ${Format.dmy(to)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            emptySelectionAllowed: true,
            segments: const [
              ButtonSegment(value: 1, label: Text('اليوم')),
              ButtonSegment(value: 7, label: Text('٧ أيام')),
              ButtonSegment(value: 30, label: Text('٣٠ يوم')),
            ],
            selected: preset == 1 || preset == 7 || preset == 30 ? {preset} : <int>{},
            onSelectionChanged: (s) {
              if (s.isEmpty) return;
              final v = s.first;
              onPreset(v);
            },
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final int ordersCount;
  final double ordersTotal;

  const _KpiGrid({
    required this.ordersCount,
    required this.ordersTotal,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      children: [
        _MetricTile(
          title: 'عدد طلباتي (التطبيق)',
          value: '$ordersCount',
          icon: Icons.shopping_cart_checkout,
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
          accent: scheme.primary,
        ),
        _MetricTile(
          title: 'قيمة طلباتي (التطبيق)',
          value: '${Format.money(ordersTotal)} د.ع',
          icon: Icons.payments_outlined,
          background: scheme.tertiaryContainer,
          foreground: scheme.onTertiaryContainer,
          accent: scheme.tertiary,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color accent;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: background,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 200),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 80)),
                ),
                child: Icon(icon, color: accent),
              ),
              const Spacer(),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w800, color: foreground.withValues(alpha: 170)),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: foreground),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int ordersCount;
  final double ordersTotal;

  const _SummaryCard({
    required this.ordersCount,
    required this.ordersTotal,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: scheme.primary),
                const SizedBox(width: 8),
                const Text('ملخص سريع', style: TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 12),
            _kvRow('عدد طلباتي (التطبيق)', '$ordersCount'),
            _kvRow('قيمة طلباتي (التطبيق)', '${Format.money(ordersTotal)} د.ع'),
            const SizedBox(height: 8),
            const Text(
              'اسحب للأسفل للتحديث',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _kvRow(String k, String v) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(child: Text(k, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700))),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 64)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceContainerHighest;
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      children: List.generate(
        2,
        (_) => Container(
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

