import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/market_item.dart';
import '../viewmodels/game_view_model.dart';

class MarketView extends ConsumerWidget {
  const MarketView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(gameProvider);
    final grouped = _groupByCategory(vm.marketItems);
    final ownedIds = vm.ownedItems.map((item) => item.id).toSet();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Market",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (ownedIds.isNotEmpty) ...[
            Text(
              "Sahip oldukların",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vm.ownedItems
                  .map(
                    (item) => Chip(
                      label: Text(item.name),
                      avatar: const Icon(Icons.check, size: 16, color: Colors.white),
                      backgroundColor: Colors.green,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          ...grouped.entries.map((entry) {
            return _CategorySection(
              title: entry.key,
              items: entry.value,
              ownedIds: ownedIds,
            );
          }),
        ],
      ),
    );
  }

  Map<String, List<MarketItem>> _groupByCategory(List<MarketItem> items) {
    final map = <String, List<MarketItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({
    required this.title,
    required this.items,
    required this.ownedIds,
  });

  final String title;
  final List<MarketItem> items;
  final Set<String> ownedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(gameProvider); // Use read for actions

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        ...items.map((item) {
          final isOwned = ownedIds.contains(item.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İkon eklenebilir, şimdilik basit tutuyoruz veya kategoriye göre ikon
                Container(
                   padding: const EdgeInsets.all(10),
                   decoration: BoxDecoration(
                     color: Colors.red.shade50,
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: Icon(Icons.shopping_bag_outlined, color: Colors.red.shade700),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${item.price.toStringAsFixed(0)} TL",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: isOwned
                      ? null
                      : () {
                          vm.purchaseItem(item);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(isOwned ? "Alındı" : "Satın Al"),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
