import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/order_provider.dart';
import '../../models/pos_order.dart';
import '../format.dart';
import 'edit_pos_order_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final _qCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadMyOrders();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _qCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<OrderProvider>().loadMyOrders(q: v);
    });
  }

  Future<void> _openDetails(PosOrderLite o) async {
    final op = context.read<OrderProvider>();
    Map<String, dynamic>? full;
    String? err;
    try {
      full = await op.fetchPosOrder(o.id);
    } catch (e) {
      err = e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final t = Theme.of(ctx).textTheme;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: err != null
                  ? Center(child: Text(err, style: const TextStyle(color: Colors.red)))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'الطلب #${o.id}',
                                style: (t.titleMedium ?? const TextStyle()).copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                o.status,
                                style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w900, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView(
                            children: [
                              _kv('الزبون', o.customerName ?? '—'),
                              _kv('الهاتف', o.customerPhone ?? '—', ltr: true),
                              _kv('مودن', '${o.deliveryCityName ?? '—'} • ${o.deliveryRegionName ?? '—'}'),
                              _kv('أقرب نقطة', o.addressText ?? '—'),
                              if ((o.merchantNotes ?? '').isNotEmpty) _kv('ملاحظات للمندوب', o.merchantNotes!),
                              _kv('حالة مودن', o.modonStatus ?? '—'),
                              const Divider(),
                              Text('الأصناف', style: (t.titleSmall ?? const TextStyle()).copyWith(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              ...(((full?['items'] as List?) ?? const []).whereType<Map>().map((raw) {
                                final it = raw.cast<String, dynamic>();
                                final qty = (it['quantity'] as num?)?.toInt() ?? 1;
                                final unit = (it['unit_price'] as num?)?.toDouble() ?? (it['price'] as num?)?.toDouble() ?? 0;
                                final name = (it['product'] as Map?)?['name'] as String? ?? (it['meta'] as Map?)?['name'] as String? ?? '—';
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  subtitle: Text('العدد: $qty  •  سعر القطعة: ${Format.money(unit)}'),
                                  trailing: Text(Format.money(unit * qty), style: const TextStyle(fontWeight: FontWeight.w900)),
                                );
                              })),
                              const Divider(),
                              _kv('الإجمالي', '${Format.money(o.total)} د.ع'),
                              if ((o.suspendedNote ?? '').isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.red.withValues(alpha: 60)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('ملاحظة التعليق', style: TextStyle(fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 6),
                                      Text(o.suspendedNote!),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (o.status == 'suspended')
                          FilledButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => EditPosOrderScreen(orderId: o.id)),
                              );
                              if (!mounted) return;
                              await context.read<OrderProvider>().loadMyOrders(q: _qCtrl.text);
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('تعديل الطلب (معلق فقط)'),
                          )
                        else
                          FilledButton.tonal(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('إغلاق'),
                          ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v, {bool ltr = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(k, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black54))),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.left,
              textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي'),
        actions: [
          IconButton(
            onPressed: orders.loadingMyOrders ? null : () => context.read<OrderProvider>().loadMyOrders(q: _qCtrl.text),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _qCtrl,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'بحث: رقم الطلب / هاتف / عنوان / اسم',
                ),
              ),
            ),
            if (orders.loadingMyOrders) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: orders.myOrders.isEmpty
                  ? const Center(child: Text('لا توجد طلبات'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: orders.myOrders.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final o = orders.myOrders[i];
                        final statusColor = o.status == 'suspended'
                            ? Colors.red
                            : (o.status == 'confirmed' ? Colors.orange : scheme.primary);
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openDetails(o),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 90)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 14),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text('#${o.id}', style: TextStyle(fontWeight: FontWeight.w900, color: statusColor)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(o.customerName ?? '—', style: const TextStyle(fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 4),
                                      Text(
                                        [
                                          if ((o.customerPhone ?? '').isNotEmpty) o.customerPhone,
                                          if ((o.deliveryCityName ?? '').isNotEmpty || (o.deliveryRegionName ?? '').isNotEmpty)
                                            '${o.deliveryCityName ?? '—'} • ${o.deliveryRegionName ?? '—'}',
                                          if ((o.modonStatus ?? '').isNotEmpty) 'مودن: ${o.modonStatus}',
                                        ].whereType<String>().join('  •  '),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${Format.money(o.total)} د.ع', style: TextStyle(fontWeight: FontWeight.w900, color: scheme.primary)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 14),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(o.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: statusColor)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

