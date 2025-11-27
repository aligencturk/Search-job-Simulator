import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_model.dart';
import '../viewmodels/game_view_model.dart';
import 'applications_view.dart';
import 'cv_view.dart';
import 'interviews_view.dart';
import 'jobs_view.dart';
import 'market_view.dart';
import 'self_improvement_view.dart';
import 'setup_view.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameVM = ref.watch(gameProvider);
    final player = gameVM.player;

    // Bildirimleri dinle
    ref.listen(gameProvider, (previous, next) {
      if (next.lastMessage != previous?.lastMessage &&
          next.lastMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.lastMessage),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(label: 'Tamam', onPressed: () {}),
          ),
        );
      }
    });

    if (player == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Bir TC Simülasyonu",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          // Mağaza butonu
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Text(
                  "Mağaza",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MarketView(),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.shopping_basket,
                        color: Colors.amber,
                        size: 32,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, ref, player),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: Column(
          children: [
            // Üst Bilgi Alanı
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF5F5F5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bebek ikonu (Statik görsel amaçlı)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.child_care,
                      size: 40,
                      color: Colors.brown.shade300,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // İsim ve Bölüm
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          gameVM.department?.name ?? "Bölüm Yok",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bakiye
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Bakiye",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${player.money.toStringAsFixed(0)} TL",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Hikaye Alanı - Timeline Şeklinde
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                color: const Color(0xFFF5F5F5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tarih: ${gameVM.formattedDate}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: gameVM.stories.isEmpty
                          ? const Center(
                              child: Text(
                                "Hayatın henüz başında...",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: gameVM.stories.length,
                              itemBuilder: (context, index) {
                                final story = gameVM.stories[index];
                                final months = [
                                  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
                                  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
                                ];
                                final dateStr = '${story.date.day} ${months[story.date.month - 1]} ${story.date.year}';
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        story.content,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Alt Butonlar ve Mental Sağlık
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 5'li Buton Grubu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MenuButton(
                        icon: Icons.work,
                        label: "İş İlanları",
                        color: Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JobsView(),
                            ),
                          );
                        },
                      ),
                      _MenuButton(
                        icon: Icons.person, // Kişisel yerine şimdilik profil/cv
                        label: "CV",
                        color: Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CVView(),
                            ),
                          );
                        },
                      ),
                      // Ortadaki Büyük + Butonu (Yeni Gün)
                      GestureDetector(
                        onTap: () => _handleNextDay(context, ref),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add, color: Colors.white, size: 36),
                              Text(
                                "Yeni Gün",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _MenuButton(
                        icon: Icons.shopping_bag, // İlişki yerine Market
                        label: "Market",
                        color: Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MarketView(),
                            ),
                          );
                        },
                      ),
                      _MenuButton(
                        icon: Icons.school, // Aktivite yerine Kendini Geliştir
                        label: "Gelişim",
                        color: Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SelfImprovementView(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Mental Sağlık Barı
                  _MentalHealthBar(mentalHealth: gameVM.mentalHealth),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... Drawer ve diğer helper metodlar aynı kalabilir veya sadeleştirilebilir ...
  // Drawer'ı şimdilik tutuyorum ama ana ekrana taşındı çoğu şey.
  Widget _buildDrawer(BuildContext context, WidgetRef ref, player) {
    // final gameVM = ref.watch(gameProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.red),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    player.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  player.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text("Başvurularım"),
            onTap: () {
              Navigator.pop(context); // Drawer'ı kapat
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApplicationsView(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text("Mülakatlarım"),
            onTap: () {
              Navigator.pop(context); // Drawer'ı kapat
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InterviewsView()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text("Oyunu Sıfırla"),
            onTap: () => _showResetDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Oyunu Sıfırla"),
        content: const Text(
          "Tüm ilerlemeniz silinecek ve başlangıç ekranına döneceksiniz. Emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(gameProvider).resetGame();
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SetupView()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Sıfırla"),
          ),
        ],
      ),
    );
  }

  static void _handleNextDay(BuildContext context, WidgetRef ref) {
    final event = ref.read(gameProvider).nextDay();
    _showEventDialog(
      context,
      ref,
      event,
      onDialogClosed: () => _maybeShowFinancialEventDialog(context, ref),
    );
  }

  static void _maybeShowFinancialEventDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    final vm = ref.read(gameProvider);
    final event = vm.consumeFinancialEvent();
    if (event == null) return;
    _showFinancialEventDialog(context, ref, event);
  }

  static void _showFinancialEventDialog(
    BuildContext context,
    WidgetRef ref,
    FinancialEvent event,
  ) {
    final gameVM = ref.read(gameProvider);
    final isExpense = event.amount < 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isExpense ? Icons.money_off : Icons.attach_money,
              color: isExpense ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(event.title, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Text(event.description),
        actions: [
          if (event.isChoice) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final result = gameVM.processFinancialEvent(event, false);
                _handleFinancialEventResult(context, result);
              },
              child: Text(event.choiceNoText ?? "Hayır"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                final result = gameVM.processFinancialEvent(event, true);
                _handleFinancialEventResult(context, result);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isExpense ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(event.choiceYesText ?? "Evet"),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                final result = gameVM.processFinancialEvent(event, true);
                _handleFinancialEventResult(context, result);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("Tamam"),
            ),
          ],
        ],
      ),
    );
  }

  static void _handleFinancialEventResult(
    BuildContext context,
    OptionalExpenseResult result,
  ) {
    late final String message;
    switch (result) {
      case OptionalExpenseResult.paid:
        message = "İşlem onaylandı. Bakiye güncellendi.";
        break;
      case OptionalExpenseResult.declined:
        message = "İşlem reddedildi.";
        break;
      case OptionalExpenseResult.insufficientFunds:
        message = "Bakiye yetersiz!";
        break;
      case OptionalExpenseResult.infoConfirmed:
        message = "Bilgi alındı.";
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  static void _showEventDialog(
    BuildContext context,
    WidgetRef ref,
    Event event, {
    VoidCallback? onDialogClosed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.today, color: Colors.blue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text("Günlük Olay", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                "Ne yapmak istersin?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              ...event.options.asMap().entries.map((entry) {
                final option = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        final outcome = ref
                            .read(gameProvider)
                            .processEventChoice(option);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(outcome),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        if (onDialogClosed != null) {
                          Future.microtask(onDialogClosed);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(option),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _MentalHealthBar extends StatelessWidget {
  const _MentalHealthBar({required this.mentalHealth});

  final int mentalHealth;

  @override
  Widget build(BuildContext context) {
    final double value = mentalHealth.clamp(0, 100).toDouble() / 100;
    // final Color barColor =
    //     mentalHealth >= 70
    //         ? Colors.green
    //         : mentalHealth >= 40
    //         ? Colors.orange
    //         : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Text(
            "Sağlık",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.favorite, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 20,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade400),
                backgroundColor: Colors.red.shade100,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Yükselt",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
