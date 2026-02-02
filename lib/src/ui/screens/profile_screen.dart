import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/employee_auth_provider.dart';
import '../../state/order_provider.dart';
import '../format.dart';
import 'edit_pos_order_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Widget _kvRow(String k, String v) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: (t.bodyMedium ?? const TextStyle()).copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            v,
            style: (t.bodyMedium ?? const TextStyle()).copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadMyPendingPosOrders();
      context.read<OrderProvider>().loadMyMonthSummary();
    });
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final auth = context.read<EmployeeAuthProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('خروج')),
        ],
      ),
    );
    if (ok == true) {
      await auth.logout();
    }
  }

  Future<void> _editMeDialog(BuildContext context) async {
    final auth = context.read<EmployeeAuthProvider>();
    final u = auth.user;
    final nameCtrl = TextEditingController(text: u?.name ?? '');
    final userCtrl = TextEditingController(text: u?.username ?? '');
    final emailCtrl = TextEditingController(text: u?.email ?? '');
    final passCtrl = TextEditingController();
    final pass2Ctrl = TextEditingController();
    bool showPass = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: const Text('تعديل بياناتي'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'الاسم'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: userCtrl,
                      decoration: const InputDecoration(labelText: 'اسم المستخدم'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'البريد (اختياري)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passCtrl,
                      obscureText: !showPass,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور (اتركها فارغة إذا لا تريد تغييرها)',
                        suffixIcon: IconButton(
                          onPressed: () => setS(() => showPass = !showPass),
                          icon: Icon(showPass ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: pass2Ctrl,
                      obscureText: !showPass,
                      decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              FilledButton(
                onPressed: auth.loading
                    ? null
                    : () async {
                        try {
                          await auth.updateMe(
                            name: nameCtrl.text,
                            username: userCtrl.text,
                            email: emailCtrl.text,
                            password: passCtrl.text.isEmpty ? null : passCtrl.text,
                            passwordConfirmation: pass2Ctrl.text.isEmpty ? null : pass2Ctrl.text,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم تحديث البيانات')),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                          );
                        }
                      },
                child: Text(auth.loading ? 'جاري الحفظ...' : 'حفظ'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<EmployeeAuthProvider>();
    final u = auth.user;
    final orders = context.watch<OrderProvider>();
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            onPressed: orders.loadingPending ? null : () => orders.loadMyPendingPosOrders(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: scheme.primary,
                      child: Icon(Icons.person, color: scheme.onPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u?.name?.isNotEmpty == true ? u!.name! : (u?.username ?? '—'),
                            style: (t.titleMedium ?? const TextStyle()).copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'الدور: ${u?.role ?? '—'}  •  المتجر: ${u?.vendorId ?? '—'}',
                            style: (t.bodySmall ?? const TextStyle()).copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => _editMeDialog(context),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'تعديل بياناتي',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, color: scheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'ملخص هذا الشهر',
                          style: (t.titleSmall ?? const TextStyle()).copyWith(fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        if (orders.loadingMonthSummary)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _kvRow('عدد الطلبات (هذا الشهر)', '${orders.monthOrdersCount}'),
                    _kvRow('مستحقاتي (هذا الشهر)', '${Format.money(orders.monthEarned)} د.ع'),
                    _kvRow('رصيد المحفظة', '${Format.money(orders.walletBalance)} د.ع'),
                    const SizedBox(height: 6),
                    Text(
                      orders.commissionType == 'percent'
                          ? 'عمولتي: ${orders.commissionValue ?? 0}% من قيمة المنتجات'
                          : (orders.commissionType == 'fixed'
                              ? 'عمولتي: ${Format.money(orders.commissionValue ?? 0)} د.ع لكل طلب'
                              : 'لا توجد عمولة مسجلة لهذا الحساب'),
                      style: (t.bodySmall ?? const TextStyle()).copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('تعديل بياناتي'),
                    subtitle: const Text('الاسم / اسم المستخدم / البريد / كلمة المرور'),
                    onTap: () => _editMeDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.pending_actions, color: scheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'طلبات غير مؤكدة',
                          style: (t.titleSmall ?? const TextStyle()).copyWith(fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        if (orders.loadingPending)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!orders.loadingPending && orders.pendingPosOrders.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 120)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: scheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'لا توجد طلبات معلّقة',
                                style: (t.bodyMedium ?? const TextStyle()).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...orders.pendingPosOrders.map((o) {
                        final title = (o.customerName?.isNotEmpty == true)
                            ? o.customerName!
                            : (o.customerPhone ?? 'طلب');

                        final sub = [
                          if (o.customerPhone?.isNotEmpty == true) o.customerPhone,
                          if (o.governorateName?.isNotEmpty == true) o.governorateName,
                          if ((o.deliveryCityName?.isNotEmpty == true) || (o.deliveryRegionName?.isNotEmpty == true))
                            '${o.deliveryCityName ?? '—'} • ${o.deliveryRegionName ?? '—'}',
                          if (o.addressText?.isNotEmpty == true) o.addressText,
                        ].whereType<String>().join(' • ');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 120)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: scheme.primaryContainer,
                              foregroundColor: scheme.onPrimaryContainer,
                              child: Text(
                                '#${o.id}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                              ),
                            ),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                            subtitle: Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: Text(
                              '${Format.money(o.total)} د.ع',
                              style: TextStyle(fontWeight: FontWeight.w900, color: scheme.primary),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => EditPosOrderScreen(orderId: o.id)),
                              ).then((_) => orders.loadMyPendingPosOrders());
                            },
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.errorContainer,
                foregroundColor: scheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

