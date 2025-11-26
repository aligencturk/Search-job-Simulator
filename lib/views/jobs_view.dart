import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/enums.dart';
import '../models/job_model.dart';
import '../viewmodels/game_view_model.dart';

class JobsView extends ConsumerWidget {
  const JobsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameVM = ref.watch(gameProvider);
    final jobs = gameVM.availableJobs;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "İş İlanları",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: jobs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "Henüz iş ilanı yok",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return FadeInUp(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  child: _buildJobCard(context, ref, job),
                );
              },
            ),
    );
  }

  Widget _buildJobCard(BuildContext context, WidgetRef ref, Job job) {
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
                CircleAvatar(
                  backgroundColor: _getJobColor(job.type).withOpacity(0.1),
                  child: Icon(_getJobIcon(job.type), color: _getJobColor(job.type)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${job.salary.toStringAsFixed(0)} TL - ${_getJobTypeText(job.type)}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (job.requiredSkills.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: job.requiredSkills.map((skill) {
                  return Chip(
                    label: Text(skill),
                    labelStyle: const TextStyle(fontSize: 12, color: Colors.black87),
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(gameProvider).applyToJob(job);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${job.title} için başvuru yapıldı"),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text("Başvur"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getJobColor(JobType type) {
    switch (type) {
      case JobType.Corporate:
        return Colors.indigo;
      case JobType.Startup:
        return Colors.orange;
      case JobType.Government:
        return Colors.green;
    }
  }

  IconData _getJobIcon(JobType type) {
    switch (type) {
      case JobType.Corporate:
        return Icons.business;
      case JobType.Startup:
        return Icons.rocket_launch;
      case JobType.Government:
        return Icons.account_balance;
    }
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
