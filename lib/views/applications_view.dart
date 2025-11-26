import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/enums.dart';
import '../viewmodels/game_view_model.dart';
import '../models/job_application_model.dart';
import 'interviews_view.dart'; // Mülakat sayfasına yönlendirme için

class ApplicationsView extends ConsumerWidget {
  const ApplicationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameVM = ref.watch(gameProvider);
    final applications = gameVM.applications;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Başvurularım",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: applications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "Henüz bir iş başvurusu yapmadınız.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final app = applications[index];
                return _buildApplicationCard(context, app, ref);
              },
            ),
    );
  }

  Widget _buildApplicationCard(
      BuildContext context, JobApplication app, WidgetRef ref) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    bool canNavigateToInterview = false;

    switch (app.status) {
      case ApplicationStatus.Applied:
        statusColor = Colors.orange;
        statusText = "Değerlendiriliyor";
        statusIcon = Icons.hourglass_empty;
        break;
      case ApplicationStatus.Interview:
        statusColor = Colors.blue;
        statusText = "Mülakat Daveti";
        statusIcon = Icons.chat;
        canNavigateToInterview = true;
        break;
      case ApplicationStatus.InterviewCompleted:
        statusColor = Colors.purple;
        statusText = "Sonuç Bekleniyor";
        statusIcon = Icons.checklist;
        break;
      case ApplicationStatus.Accepted:
        statusColor = Colors.green;
        statusText = "Kabul Edildi";
        statusIcon = Icons.check_circle;
        break;
      case ApplicationStatus.Rejected:
        statusColor = Colors.red;
        statusText = "Reddedildi";
        statusIcon = Icons.cancel;
        break;
      case ApplicationStatus.Ghosted:
        statusColor = Colors.grey;
        statusText = "Ses Yok (Ghost)";
        statusIcon = Icons.question_mark;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    app.job.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Maaş: ${app.job.salary.toStringAsFixed(0)} TL",
              style: TextStyle(color: Colors.grey.shade700),
            ),
            Text(
              "Şirket Türü: ${_getJobTypeText(app.job.type)}",
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (app.message != null) ...[
              const SizedBox(height: 8),
              Text(
                "Durum: ${app.message}",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
            if (canNavigateToInterview) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InterviewsView(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Mülakata Git"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  String _getJobTypeText(JobType type) {
    switch (type) {
      case JobType.Corporate:
        return "Kurumsal";
      case JobType.Startup:
        return "Startup";
      case JobType.Government:
        return "Kamu";
    }
  }
}
