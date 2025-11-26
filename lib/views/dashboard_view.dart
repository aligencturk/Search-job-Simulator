import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_model.dart';
import '../models/job_application_model.dart';
import '../models/story_model.dart';
import '../viewmodels/game_view_model.dart';
import 'applications_view.dart';
import 'chat_view.dart';
import 'cv_view.dart';
import 'interviews_view.dart';
import 'jobs_view.dart';
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
      drawer: _buildDrawer(context, ref, player),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("İş Arama Simülatörü"),
        actions: [
          // Sıfırla Butonu (Geliştirme)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _showResetDialog(context, ref),
            tooltip: "Oyunu Sıfırla",
            color: Colors.white,
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade200,
        child: Column(
          children: [
            // Üst kısım - Tarih ve Zaman İlerletme Butonları
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Column(
                children: [
                  // Tarih
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        gameVM.formattedDate,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Zaman İlerletme Butonları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Sonraki Gün Butonu
                      ElevatedButton.icon(
                        onPressed: () => _handleNextDay(context, ref),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text("Sonraki Gün"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      // Sonraki Ay Butonu
                      ElevatedButton.icon(
                        onPressed: () {
                          final event = ref.read(gameProvider).nextMonth();
                          _showEventDialog(context, event);
                        },
                        icon: const Icon(Icons.calendar_month, size: 18),
                        label: const Text("Sonraki Ay"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      // Sonraki Yıl Butonu
                      ElevatedButton.icon(
                        onPressed: () {
                          final event = ref.read(gameProvider).nextYear();
                          _showEventDialog(context, event);
                        },
                        icon: const Icon(Icons.event, size: 18),
                        label: const Text("Sonraki Yıl"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Ana içerik
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Üst kısım - Kullanıcı Bilgileri
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sol tarafta Avatar
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            player.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Orta kısım - İsim ve Bölüm
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // İsim Soyisim
                              Text(
                                player.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Mezun Olunan Bölüm
                              Text(
                                gameVM.department?.name ?? "Bölüm seçilmedi",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Sağ tarafta - Bakiye
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Bakiye",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.account_balance_wallet,
                                  size: 16,
                                  color: Colors.amber.shade700,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${player.money.toStringAsFixed(0)} TL",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.home, size: 18),
                            label: Text(
                              gameVM.livingWithFamily
                                  ? "Aile Evi - Temel gider yok"
                                  : "Kendi Evi",
                            ),
                            backgroundColor: Colors.green.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          Chip(
                            avatar: const Icon(Icons.groups, size: 18),
                            label: Text(
                              "Arkadaşlarla çıkmak: ${gameVM.optionalHangoutCost.toStringAsFixed(0)} TL",
                            ),
                            backgroundColor: Colors.blue.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _MentalHealthBar(mentalHealth: gameVM.mentalHealth),
                    const SizedBox(height: 24),
                    // Hikayeler Listesi
                    if (gameVM.stories.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.book, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            "Hikayeler",
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...gameVM.stories.reversed.map((story) {
                        final months = [
                          'Ocak',
                          'Şubat',
                          'Mart',
                          'Nisan',
                          'Mayıs',
                          'Haziran',
                          'Temmuz',
                          'Ağustos',
                          'Eylül',
                          'Ekim',
                          'Kasım',
                          'Aralık',
                        ];
                        final dateStr =
                            "${story.date.day} ${months[story.date.month - 1]} ${story.date.year}";
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      story.type == StoryType.Daily
                                          ? Icons.today
                                          : story.type == StoryType.Monthly
                                          ? Icons.calendar_month
                                          : Icons.event,
                                      size: 18,
                                      color: story.type == StoryType.Daily
                                          ? Colors.blue
                                          : story.type == StoryType.Monthly
                                          ? Colors.orange
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  story.content,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ] else ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.book_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Henüz hikaye yok",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Zaman ilerletmek için butonları kullanın",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatView()),
          );
        },
        icon: const Icon(Icons.chat),
        label: const Text("AI Asistan"),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref, player) {
    final gameVM = ref.watch(gameProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    player.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
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
                Text(
                  gameVM.department?.name ?? "",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text("İş İlanları"),
            trailing: gameVM.availableJobs.isNotEmpty
                ? Chip(
                    label: Text("${gameVM.availableJobs.length}"),
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const JobsView()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text("Başvurularım"),
            trailing:
                gameVM.applications
                    .where((a) => a.status == ApplicationStatus.Applied)
                    .isNotEmpty
                ? Chip(
                    label: Text(
                      "${gameVM.applications.where((a) => a.status == ApplicationStatus.Applied).length}",
                    ),
                    backgroundColor: Colors.orange,
                    labelStyle: const TextStyle(color: Colors.white),
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApplicationsView(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text("Mülakatlarım"),
            trailing: gameVM.interviews.isNotEmpty
                ? Chip(
                    label: Text("${gameVM.interviews.length}"),
                    backgroundColor: Colors.green,
                    labelStyle: const TextStyle(color: Colors.white),
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InterviewsView()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text("Kendini Geliştir"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SelfImprovementView(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text("CV'm"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CVView()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text("AI Asistan"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatView()),
              );
            },
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
            // Seçimli Olay
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
            // Zorunlu Olay
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
              Icon(
                event.type == EventType.Daily
                    ? Icons.today
                    : event.type == EventType.Monthly
                    ? Icons.calendar_month
                    : Icons.event,
                color: event.type == EventType.Daily
                    ? Colors.blue
                    : event.type == EventType.Monthly
                    ? Colors.orange
                    : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.type == EventType.Daily
                      ? "Günlük Olay"
                      : event.type == EventType.Monthly
                      ? "Aylık Olay"
                      : "Yıllık Olay",
                  style: const TextStyle(fontSize: 18),
                ),
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
                final index = entry.key;
                final option = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("$option seçildi"),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                        if (onDialogClosed != null) {
                          Future.microtask(onDialogClosed);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: index == 0
                            ? Colors.green
                            : index == 1
                            ? Colors.blue
                            : Colors.red,
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

class _MentalHealthBar extends StatelessWidget {
  const _MentalHealthBar({required this.mentalHealth});

  final int mentalHealth;

  @override
  Widget build(BuildContext context) {
    final double value = mentalHealth.clamp(0, 100).toDouble() / 100;
    final Color barColor = mentalHealth >= 70
        ? Colors.green
        : mentalHealth >= 40
        ? Colors.orange
        : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: barColor),
                const SizedBox(width: 8),
                Text(
                  "Mental Sağlık",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  "$mentalHealth / 100",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: barColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 12,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mentalHealth >= 70
                  ? "Moralin yüksek!"
                  : mentalHealth >= 40
                  ? "Biraz dinlenmeye ihtiyacın var."
                  : "Kendine zaman ayır, moral toparla.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
