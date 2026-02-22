import 'package:flutter/material.dart';
import '../../models/modon_location.dart';

/// Searchable modal sheet for Modon cities - uses StatefulWidget + TextEditingController
/// so search state persists on real devices when keyboard opens.
class ModonCitySearchSheet extends StatefulWidget {
  final List<ModonCity> items;
  final BuildContext modalContext;

  const ModonCitySearchSheet({
    super.key,
    required this.items,
    required this.modalContext,
  });

  @override
  State<ModonCitySearchSheet> createState() => _ModonCitySearchSheetState();
}

class _ModonCitySearchSheetState extends State<ModonCitySearchSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _controller.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.items
        : widget.items
            .where((c) => c.name.toLowerCase().contains(q))
            .toList();

    return Column(
      children: [
        const SizedBox(height: 6),
        const ListTile(
          title: Text('اختر مدينة مودن', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'بحث...',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final c = filtered[i];
              return ListTile(
                leading: const Icon(Icons.location_city_outlined),
                title: Text(c.name),
                onTap: () => Navigator.pop(widget.modalContext, c.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Searchable modal sheet for Modon regions.
class ModonRegionSearchSheet extends StatefulWidget {
  final List<ModonRegion> items;
  final BuildContext modalContext;

  const ModonRegionSearchSheet({
    super.key,
    required this.items,
    required this.modalContext,
  });

  @override
  State<ModonRegionSearchSheet> createState() => _ModonRegionSearchSheetState();
}

class _ModonRegionSearchSheetState extends State<ModonRegionSearchSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _controller.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.items
        : widget.items
            .where((r) => r.name.toLowerCase().contains(q))
            .toList();

    return Column(
      children: [
        const SizedBox(height: 6),
        const ListTile(
          title: Text('اختر منطقة مودن', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'بحث...',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final r = filtered[i];
              return ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text(r.name),
                onTap: () => Navigator.pop(widget.modalContext, r.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
