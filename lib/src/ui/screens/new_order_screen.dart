import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../state/cart_provider.dart';
import '../../state/catalog_provider.dart';
import '../../state/order_provider.dart';
import '../../state/modon_locations_provider.dart';
import '../widgets/modon_search_sheet.dart';
import '../format.dart';

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final _productCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _merchantNotesCtrl = TextEditingController();
  int _modonCityId = 0;
  int _modonRegionId = 0;
  String? _phoneError;

  Timer? _debounceProducts;
  final _scrollCtrl = ScrollController();

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
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, _) => ModonCitySearchSheet(
          items: loc.cities,
          modalContext: ctx,
        ),
      ),
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
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, _) => ModonRegionSearchSheet(
          items: items,
          modalContext: ctx,
        ),
      ),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    _productCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _merchantNotesCtrl.dispose();
    super.dispose();
  }

  void _onProductChanged(String v) {
    _debounceProducts?.cancel();
    _debounceProducts = Timer(const Duration(milliseconds: 250), () {
      context.read<CatalogProvider>().search(q: v);
    });
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

  Future<void> _openCart() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => const _CartSheet(),
    );
  }

  Future<void> _submit() async {
    final cart = context.read<CartProvider>();
    final orders = context.read<OrderProvider>();
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
      final id = await orders.submitPosOrder(
        cart: cart,
        customerName: name,
        customerPhone: phone,
        deliveryCityId: _modonCityId,
        deliveryRegionId: _modonRegionId,
        addressText: address,
        merchantNotes: merchantNotes.isEmpty ? null : merchantNotes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(id != null ? 'تم إنشاء الطلب رقم #$id' : 'تم إنشاء الطلب')),
      );
      _addressCtrl.clear();
      _merchantNotesCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final cart = context.watch<CartProvider>();
    final orders = context.watch<OrderProvider>();
    final modon = context.watch<ModonLocationsProvider>();
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    const actionBarHeight = 76.0;
    final actionBarBottom = 10.0 + bottomPad;
    final sliverBottomPad = actionBarHeight + actionBarBottom + 16;

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب جديد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: catalog.loading ? null : () => catalog.refresh(),
            tooltip: 'تحديث المنتجات',
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => catalog.refresh(),
              child: CustomScrollView(
                controller: _scrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
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
                                  child: Icon(Icons.person_pin_circle_outlined, color: scheme.onPrimaryContainer),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'بيانات الزبون',
                                        style: (t.titleMedium ?? const TextStyle()).copyWith(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'أدخل البيانات ثم اختر المنتجات',
                                        style: (t.bodySmall ?? const TextStyle()).copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _nameCtrl,
                                    textInputAction: TextInputAction.next,
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
                                    textInputAction: TextInputAction.next,
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
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 120)),
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    onTap: modon.loadingCities ? null : _pickModonCity,
                                    leading: Icon(Icons.location_city_outlined, color: scheme.primary),
                                    title: Text(
                                      'مدينة مودن *',
                                      style: (t.titleSmall ?? const TextStyle()).copyWith(fontWeight: FontWeight.w900),
                                    ),
                                    subtitle: Text(
                                      modon.loadingCities ? 'جاري التحميل...' : _modonCityName(modon),
                                      style: (t.bodySmall ?? const TextStyle()).copyWith(color: scheme.onSurfaceVariant),
                                    ),
                                    trailing: Icon(Icons.chevron_left, color: scheme.onSurfaceVariant),
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    onTap: (modon.loadingRegions || _modonCityId <= 0) ? null : _pickModonRegion,
                                    leading: Icon(Icons.map_outlined, color: scheme.primary),
                                    title: Text(
                                      'منطقة مودن *',
                                      style: (t.titleSmall ?? const TextStyle()).copyWith(fontWeight: FontWeight.w900),
                                    ),
                                    subtitle: Text(
                                      _modonCityId <= 0
                                          ? 'اختر المدينة أولاً'
                                          : (modon.loadingRegions ? 'جاري التحميل...' : _modonRegionName(modon)),
                                      style: (t.bodySmall ?? const TextStyle()).copyWith(color: scheme.onSurfaceVariant),
                                    ),
                                    trailing: Icon(Icons.chevron_left, color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _addressCtrl,
                              minLines: 2,
                              maxLines: 4,
                              textInputAction: TextInputAction.newline,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.location_on_outlined),
                                labelText: 'العنوان / أقرب نقطة دالة *',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _merchantNotesCtrl,
                              minLines: 1,
                              maxLines: 2,
                              textInputAction: TextInputAction.newline,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.local_shipping_outlined),
                                labelText: 'ملاحظات للمندوب (اختياري)',
                                hintText: 'مثال: توصيل صباحاً / ظهراً / بعد باجر...',
                              ),
                            ),
                            const SizedBox(height: 8),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (catalog.loading)
                  const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2)),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, sliverBottomPad),
                  sliver: catalog.products.isEmpty
                      ? const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text('لا توجد منتجات')),
                        )
                      : SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.78,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _ProductCard(product: catalog.products[i]),
                            childCount: catalog.products.length,
                          ),
                        ),
                ),
                if (catalog.loadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: actionBarBottom,
              child: Material(
                color: scheme.surface,
                elevation: 12,
                borderRadius: BorderRadius.circular(18),
                shadowColor: Colors.black.withValues(alpha: 36),
                child: Container(
                  height: actionBarHeight,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 90)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: OutlinedButton.icon(
                          onPressed: cart.lines.isEmpty ? null : _openCart,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.shopping_cart_outlined),
                              if (cart.lines.isNotEmpty)
                                Positioned(
                                  top: -6,
                                  right: -10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: scheme.primary,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${cart.lines.length}',
                                      style: TextStyle(
                                        color: scheme.onPrimary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          label: Text(
                            'السلة',
                            style: (t.titleSmall ?? const TextStyle()).copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 6,
                        child: FilledButton.icon(
                          onPressed: orders.submitting || cart.lines.isEmpty ? null : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          icon: orders.submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            orders.submitting
                                ? 'جاري الإنشاء...'
                                : 'إنشاء الطلب  •  ${Format.money(cart.total)} د.ع',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: (t.titleSmall ?? const TextStyle()).copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
      if (product.addWithoutVariantSelection) {
        final v = product.variants.isNotEmpty ? product.variants.first : null;
        cart.add(product, variant: v);
        return;
      }
      final selected = await showModalBottomSheet<ProductVariant>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => ListView(
          children: [
            const ListTile(
              title: Text('اختر الخاصية/النوع', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            ...product.variants.map((v) {
              final label = v.label ?? v.sku ?? 'خيار #${v.id}';
              return ListTile(
                title: Text(label),
                subtitle: Text('السعر: ${Format.money(v.price)} د.ع   •   المتوفر: ${v.stock ?? '-'}'),
                onTap: () => Navigator.of(ctx).pop(v),
              );
            }),
          ],
        ),
      );
      if (selected != null) cart.add(product, variant: selected);
    }

    final scheme = Theme.of(context).colorScheme;
    final inStock = product.stock > 0;
    // Agency products can be added even with 0 stock (fulfilled by agency)
    final canAdd = inStock || product.isAgencyProduct;

    const ok = Color(0xFF16A34A); // green-600
    const bad = Color(0xFFB91C1C); // red-700
    final badgeBg = (inStock ? ok : bad).withValues(alpha: 230);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: !canAdd ? null : add,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: product.image == null || product.image!.isEmpty
                        ? Container(
                            color: scheme.surfaceContainerHighest,
                            child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant.withValues(alpha: 140)),
                          )
                        : CachedNetworkImage(
                            imageUrl: product.image!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                            ),
                            errorWidget: (context, url, error) => Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'المتوفر: ${product.stock}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (product.isAgencyProduct) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'من الوكالة',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 120),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${Format.money(product.displayPrice)} د.ع',
                          style: TextStyle(fontWeight: FontWeight.w900, color: scheme.primary),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: !canAdd ? null : add,
                        icon: Icon(product.addWithoutVariantSelection ? Icons.add : Icons.tune),
                        tooltip: product.addWithoutVariantSelection ? 'إضافة' : 'اختيار نوع',
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

class _CartSheet extends StatelessWidget {
  const _CartSheet();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.shopping_cart_outlined, color: scheme.primary),
            title: Text(
              'السلة',
              style: (t.titleMedium ?? const TextStyle()).copyWith(fontWeight: FontWeight.w900),
            ),
            trailing: cart.lines.isEmpty
                ? null
                : TextButton(
                    onPressed: cart.clear,
                    child: const Text('تفريغ'),
                  ),
          ),
          if (cart.lines.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('السلة فارغة'),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: cart.lines.length,
                itemBuilder: (context, i) {
                  final l = cart.lines[i];
                  return ListTile(
                    title: Text(l.product.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: (l.variant?.label ?? l.variant?.sku ?? '').isEmpty
                        ? null
                        : Text(l.variant?.label ?? l.variant?.sku ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => cart.setQty(l, l.quantity - 1),
                          icon: const Icon(Icons.remove),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('${l.quantity}', style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => cart.setQty(l, l.quantity + 1),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const Divider(),
          Row(
            children: [
              const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(
                '${Format.money(cart.total)} د.ع',
                style: TextStyle(fontWeight: FontWeight.w900, color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

