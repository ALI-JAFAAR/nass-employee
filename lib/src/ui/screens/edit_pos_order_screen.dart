import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../state/cart_provider.dart';
import '../../state/catalog_provider.dart';
import '../../state/modon_locations_provider.dart';
import '../../state/order_provider.dart';
import '../format.dart';

class EditPosOrderScreen extends StatefulWidget {
  final int orderId;
  const EditPosOrderScreen({super.key, required this.orderId});

  @override
  State<EditPosOrderScreen> createState() => _EditPosOrderScreenState();
}

class _EditPosOrderScreenState extends State<EditPosOrderScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _merchantNotesCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  int _modonCityId = 0;
  int _modonRegionId = 0;
  String? _phoneError;

  Timer? _debounceProducts;
  final _scrollCtrl = ScrollController();

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _load();
      if (!mounted) return;
      final catalog = context.read<CatalogProvider>();
      catalog.loadFilters();
      catalog.search(q: '');
      context.read<ModonLocationsProvider>().loadCities();
    });
    _scrollCtrl.addListener(() {
      final pos = _scrollCtrl.position;
      if (pos.maxScrollExtent - pos.pixels < 700) {
        context.read<CatalogProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounceProducts?.cancel();
    _scrollCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _merchantNotesCtrl.dispose();
    _productCtrl.dispose();
    super.dispose();
  }

  void _onProductChanged(String v) {
    _debounceProducts?.cancel();
    _debounceProducts = Timer(const Duration(milliseconds: 250), () {
      context.read<CatalogProvider>().search(q: v);
    });
  }

  String _brandName(CatalogProvider catalog) {
    final id = catalog.brandId;
    if (id == null) return 'كل البراندات';
    for (final b in catalog.brands) {
      if (b.id == id) return b.name;
    }
    return 'براند #$id';
  }

  String _categoryName(CatalogProvider catalog) {
    final id = catalog.categoryId;
    if (id == null) return 'كل الأقسام';
    for (final c in catalog.categories) {
      if (c.id == id) return c.name;
    }
    return 'قسم #$id';
  }

  Future<void> _pickModonCity() async {
    final loc = context.read<ModonLocationsProvider>();
    if (loc.cities.isEmpty) await loc.loadCities();
    if (!mounted) return;

    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final all = loc.cities;
        String searchQ = '';
        return StatefulBuilder(
          builder: (ctx2, setSt) {
            final items = searchQ.trim().isEmpty
                ? all
                : all.where((c) => c.name.toLowerCase().contains(searchQ.trim().toLowerCase())).toList();
            return Column(
              children: [
                const SizedBox(height: 6),
                const ListTile(
                  title: Text('اختر مدينة مودن', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'بحث...',
                    ),
                    onChanged: (v) => setSt(() => searchQ = v),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (cctx, i) {
                      final c = items[i];
                      return ListTile(
                        leading: const Icon(Icons.location_city_outlined),
                        title: Text(c.name),
                        onTap: () => Navigator.pop(ctx, c.id),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (picked != null && picked > 0) {
      setState(() {
        _modonCityId = picked;
        _modonRegionId = 0;
      });
      await context.read<ModonLocationsProvider>().loadRegions(_modonCityId);
    }
  }

  Future<void> _pickModonRegion() async {
    if (_modonCityId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر مدينة مودن أولاً')));
      return;
    }
    final loc = context.read<ModonLocationsProvider>();
    await loc.loadRegions(_modonCityId);
    if (!mounted) return;

    final items = loc.regionsForCity(_modonCityId);
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final all = items;
        String regionSearchQ = '';
        return StatefulBuilder(
          builder: (ctx2, setSt) {
            final filtered = regionSearchQ.trim().isEmpty
                ? all
                : all.where((r) => r.name.toLowerCase().contains(regionSearchQ.trim().toLowerCase())).toList();
            return Column(
              children: [
                const SizedBox(height: 6),
                const ListTile(
                  title: Text('اختر منطقة مودن', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'بحث...',
                    ),
                    onChanged: (v) => setSt(() => regionSearchQ = v),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (cctx, i) {
                      final r = filtered[i];
                      return ListTile(
                        leading: const Icon(Icons.map_outlined),
                        title: Text(r.name),
                        onTap: () => Navigator.pop(ctx, r.id),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted) return;
    if (picked != null && picked > 0) {
      setState(() => _modonRegionId = picked);
    }
  }

  String _modonCityName(ModonLocationsProvider loc) {
    if (_modonCityId <= 0) return 'اختر مدينة مودن *';
    for (final c in loc.cities) {
      if (c.id == _modonCityId) return c.name;
    }
    return 'مدينة #$_modonCityId';
  }

  String _modonRegionName(ModonLocationsProvider loc) {
    if (_modonRegionId <= 0) return 'اختر منطقة مودن *';
    final list = loc.regionsForCity(_modonCityId);
    for (final r in list) {
      if (r.id == _modonRegionId) return r.name;
    }
    return 'منطقة #$_modonRegionId';
  }

  Future<void> _pickBrand() async {
    final catalog = context.read<CatalogProvider>();
    if (catalog.brands.isEmpty) await catalog.loadFilters();
    if (!mounted) return;

    final picked = await showModalBottomSheet<int?>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final items = catalog.brands;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const ListTile(
              title: Text('اختر البراند', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('الكل'),
              onTap: () => Navigator.pop(ctx, null),
            ),
            const Divider(height: 1),
            ...items.map((b) => ListTile(
                  leading: const Icon(Icons.local_offer_outlined),
                  title: Text(b.name),
                  onTap: () => Navigator.pop(ctx, b.id),
                )),
          ],
        );
      },
    );

    if (!mounted) return;
    context.read<CatalogProvider>().setBrand(picked);
  }

  Future<void> _pickCategory() async {
    final catalog = context.read<CatalogProvider>();
    if (catalog.categories.isEmpty) await catalog.loadFilters();
    if (!mounted) return;

    final picked = await showModalBottomSheet<int?>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final items = catalog.categories;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const ListTile(
              title: Text('اختر القسم', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('الكل'),
              onTap: () => Navigator.pop(ctx, null),
            ),
            const Divider(height: 1),
            ...items.map((c) => ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(c.name),
                  onTap: () => Navigator.pop(ctx, c.id),
                )),
          ],
        );
      },
    );

    if (!mounted) return;
    context.read<CatalogProvider>().setCategory(picked);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final op = context.read<OrderProvider>();
      final res = await op.fetchPosOrder(widget.orderId);
      if (!mounted) return;

      final customer = (res['customer'] as Map?)?.cast<String, dynamic>() ?? {};
      _nameCtrl.text = (customer['name'] as String?) ?? '';
      _phoneCtrl.text = (customer['phone'] as String?) ?? '';
      _addressCtrl.text = (res['address_text'] as String?) ?? '';
      _merchantNotesCtrl.text = (res['merchant_notes'] as String?) ?? '';

      _modonCityId = (res['delivery_city_id'] as num?)?.toInt() ?? 0;
      _modonRegionId = (res['delivery_region_id'] as num?)?.toInt() ?? 0;
      if (_modonCityId > 0) {
        try {
          await context.read<ModonLocationsProvider>().loadRegions(_modonCityId);
        } catch (_) {}
      }

      final items = (res['items'] as List?) ?? const [];
      final lines = <CartLine>[];
      for (final raw in items) {
        if (raw is! Map) continue;
        final it = raw.cast<String, dynamic>();
        final productJson = (it['product'] as Map?)?.cast<String, dynamic>() ?? {};
        final pid = (productJson['id'] as num?)?.toInt() ?? (it['product_id'] as num).toInt();
        final pname = (productJson['name'] as String?) ?? ((it['meta'] as Map?)?['name'] as String?) ?? '—';
        final unitPrice = (it['unit_price'] as num?)?.toDouble() ?? 0;
        final qty = (it['quantity'] as num?)?.toInt() ?? 1;
        final variantId = (it['variant_id'] as num?)?.toInt();

        final product = Product(
          id: pid,
          name: pname,
          price: unitPrice,
          stock: 999999,
          image: null,
          variants: const [],
        );

        ProductVariant? variant;
        if (variantId != null) {
          variant = ProductVariant(
            id: variantId,
            price: unitPrice,
            label: ((it['meta'] as Map?)?['sku'] as String?) ?? 'خيار #$variantId',
          );
        }

        lines.add(CartLine(product: product, variant: variant, quantity: qty));
      }

      if (!mounted) return;
      context.read<CartProvider>().setLines(lines);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final phone = Format.digitsOnly(_phoneCtrl.text.trim());
    final address = _addressCtrl.text.trim();
    final merchantNotes = _merchantNotesCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال الاسم والهاتف والعنوان')),
      );
      return;
    }
    if (_modonCityId <= 0 || _modonRegionId <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار مدينة مودن والمنطقة')),
        );
        return;
      }

    final phoneErr = Format.validateIraqiPhone(phone);
    if (phoneErr != null) {
      setState(() => _phoneError = phoneErr);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(phoneErr)));
      return;
    }

    try {
      await context.read<OrderProvider>().updatePosOrder(
            orderId: widget.orderId,
            cart: context.read<CartProvider>(),
            customerName: name,
            customerPhone: phone,
            deliveryCityId: _modonCityId,
            deliveryRegionId: _modonRegionId,
            addressText: address,
            merchantNotes: merchantNotes.isEmpty ? null : merchantNotes,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التعديلات')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orders = context.watch<OrderProvider>();
    final catalog = context.watch<CatalogProvider>();
    final modon = context.watch<ModonLocationsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('تعديل الطلب #${widget.orderId}')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : ListView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline),
                                labelText: 'اسم الزبون *',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                              ],
                              onChanged: (_) => setState(
                                () => _phoneError = Format.validateIraqiPhone(_phoneCtrl.text),
                              ),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.phone_outlined),
                                labelText: 'هاتف الزبون *',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_phoneError != null) ...[
                        const SizedBox(height: 6),
                        Text(_phoneError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x11000000)),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              onTap: modon.loadingCities ? null : _pickModonCity,
                              leading: const Icon(Icons.location_city_outlined, color: Colors.blue),
                              title: const Text('مدينة مودن *', style: TextStyle(fontWeight: FontWeight.w900)),
                              subtitle: Text(modon.loadingCities ? 'جاري التحميل...' : _modonCityName(modon)),
                              trailing: const Icon(Icons.chevron_left),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              onTap: (modon.loadingRegions || _modonCityId <= 0) ? null : _pickModonRegion,
                              leading: const Icon(Icons.map_outlined, color: Colors.blue),
                              title: const Text('منطقة مودن *', style: TextStyle(fontWeight: FontWeight.w900)),
                              subtitle: Text(
                                _modonCityId <= 0
                                    ? 'اختر المدينة أولاً'
                                    : (modon.loadingRegions ? 'جاري التحميل...' : _modonRegionName(modon)),
                              ),
                              trailing: const Icon(Icons.chevron_left),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _addressCtrl,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.location_on_outlined),
                          labelText: 'العنوان / أقرب نقطة دالة *',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _merchantNotesCtrl,
                        minLines: 1,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.local_shipping_outlined),
                          labelText: 'ملاحظات للمندوب (اختياري)',
                          hintText: 'مثال: توصيل صباحاً / ظهراً / بعد باجر...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('السلة', style: TextStyle(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 10),
                              if (cart.lines.isEmpty)
                                const Text('السلة فارغة')
                              else
                                ...cart.lines.map((l) {
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(l.product.name),
                                    subtitle: Text(l.variant?.label ?? ''),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'نقص',
                                          onPressed: () => cart.setQty(l, l.quantity - 1),
                                          icon: const Icon(Icons.remove_circle_outline),
                                        ),
                                        Text('${l.quantity}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                        IconButton(
                                          tooltip: 'زيادة',
                                          onPressed: () => cart.setQty(l, l.quantity + 1),
                                          icon: const Icon(Icons.add_circle_outline),
                                        ),
                                        IconButton(
                                          tooltip: 'حذف',
                                          onPressed: () => cart.setQty(l, 0),
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              const Divider(),
                              Row(
                                children: [
                                  const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.w900)),
                                  const Spacer(),
                                  Text('${Format.money(cart.total)} د.ع'),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('إضافة منتجات', style: TextStyle(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _productCtrl,
                                onChanged: _onProductChanged,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.search),
                                  labelText: 'ابحث عن منتج...',
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: catalog.loadingFilters ? null : _pickBrand,
                                      icon: const Icon(Icons.local_offer_outlined),
                                      label: Text(
                                        _brandName(catalog),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: catalog.loadingFilters ? null : _pickCategory,
                                      icon: const Icon(Icons.category_outlined),
                                      label: Text(
                                        _categoryName(catalog),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  PopupMenuButton<String>(
                                    tooltip: 'ترتيب',
                                    initialValue: catalog.sort,
                                    onSelected: (v) => context.read<CatalogProvider>().setSort(v),
                                    itemBuilder: (ctx) => const [
                                      PopupMenuItem(value: 'newest', child: Text('الأحدث')),
                                      PopupMenuItem(value: 'name', child: Text('حسب الاسم')),
                                      PopupMenuItem(value: 'brand', child: Text('حسب البراند')),
                                    ],
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      child: Icon(Icons.sort),
                                    ),
                                  ),
                                ],
                              ),
                              if (catalog.loading) const Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                              const SizedBox(height: 10),
                              if (catalog.products.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('لا توجد منتجات'),
                                )
                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 0.78,
                                  ),
                                  itemCount: catalog.products.length,
                                  itemBuilder: (context, i) => _ProductCard(product: catalog.products[i]),
                                ),
                              if (catalog.loadingMore)
                                const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: orders.submitting || cart.lines.isEmpty ? null : _save,
            child: Text(orders.submitting ? 'جاري الحفظ...' : 'حفظ التعديلات'),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    Future<void> add() async {
      if (product.variants.isEmpty) {
        cart.add(product);
        return;
      }
      final selected = await showModalBottomSheet<ProductVariant>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => ListView(
          children: [
            const ListTile(
              title: Text('اختر الخاصية/النوع', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            ...product.variants.map((v) {
              final label = v.label ?? v.sku ?? 'Variant #${v.id}';
              return ListTile(
                title: Text(label),
                subtitle: Text('السعر: ${Format.money(v.price)}  •  المتوفر: ${v.stock ?? '-'}'),
                onTap: () => Navigator.of(ctx).pop(v),
              );
            }),
          ],
        ),
      );
      if (selected != null) cart.add(product, variant: selected);
    }

    return InkWell(
      onTap: product.stock <= 0 ? null : add,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x11000000)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: product.image == null || product.image!.isEmpty
                    ? Container(
                        color: const Color(0x11000000),
                        child: const Icon(Icons.image_not_supported_outlined),
                      )
                    : CachedNetworkImage(
                        imageUrl: product.image!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${Format.money(product.displayPrice)} د.ع',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: product.stock <= 0 ? null : add,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
