import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/enums.dart';
import '../models/cv_model.dart';
import '../viewmodels/game_view_model.dart';

class CVView extends ConsumerWidget {
  const CVView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameVM = ref.watch(gameProvider);
    CV cv;

    try {
      cv = gameVM.generateCV();
    } catch (e) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text("CV", style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: Text("Oyun başlatılmamış!")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Özgeçmiş (CV)",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Paylaşma özelliği yakında!")),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık (Profil)
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20.0),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cv.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cv.department,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Cinsiyet: ${cv.gender == Gender.Male ? "Erkek" : "Kadın"}",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Askerlik Durumu
            _buildSection(
              context,
              "Askerlik Durumu",
              Icons.military_tech,
              _getMilitaryStatusText(cv.militaryStatus),
            ),

            const SizedBox(height: 16),

            // Yetenekler
            _buildSection(
              context,
              "Yetenekler",
              Icons.stars,
              cv.skills.isEmpty
                  ? "Henüz yetenek eklenmedi"
                  : cv.skills.join(", "),
            ),

            const SizedBox(height: 16),

            // Para Durumu
            _buildSection(
              context,
              "Finansal Durum",
              Icons.account_balance_wallet,
              "${cv.money.toStringAsFixed(0)} TL",
            ),

            const SizedBox(height: 24),

            // Tamamlanan Görevler
            Text(
              "Tamamlanan Görevler",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            if (cv.completedTasks.isNotEmpty)
              ...cv.completedTasks.map(
                (task) => FadeInLeft(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
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
                    child: ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text(task.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task.description.isNotEmpty)
                            Text(task.description),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd.MM.yyyy').format(task.completedDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
               Container(
                 padding: const EdgeInsets.all(16.0),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Row(
                   children: [
                     Icon(Icons.info_outline, color: Colors.grey.shade600),
                     const SizedBox(width: 12),
                     Text(
                       "Henüz görev tamamlanmadı",
                       style: TextStyle(color: Colors.grey.shade600),
                     ),
                   ],
                 ),
               ),

            const SizedBox(height: 24),

            // Deneyimler
            if (cv.experiences.isNotEmpty) ...[
              Text(
                "Deneyimler",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ...cv.experiences.map(
                (exp) => FadeInRight(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
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
                    child: ListTile(
                      leading: const Icon(Icons.work, color: Colors.blue),
                      title: Text(exp.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exp.company),
                          if (exp.description != null) Text(exp.description!),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    String content,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
          Icon(icon, color: Colors.red.shade700),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(content, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMilitaryStatusText(MilitaryStatus status) {
    switch (status) {
      case MilitaryStatus.Exempt:
        return "Muaf";
      case MilitaryStatus.NotDone:
        return "Yapılmadı";
      case MilitaryStatus.Done:
        return "Tamamlandı";
    }
  }
}
