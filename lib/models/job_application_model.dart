import '../models/job_model.dart';

enum ApplicationStatus {
  Applied, // Başvuruldu (Bekliyor)
  Ghosted, // Ses yok (Ghostlandı)
  Interview, // Mülakat daveti geldi (Mülakata Girilmeli)
  InterviewCompleted, // Mülakat yapıldı, sonuç bekleniyor
  Rejected, // Reddedildi
  Accepted, // Kabul edildi (İş Teklifi)
}

class JobApplication {
  final Job job;
  ApplicationStatus status; // Değiştirilebilir olması için final kaldırıldı
  final DateTime appliedDate;
  DateTime lastUpdateDate; // Son güncelleme tarihi
  final String? message;

  JobApplication({
    required this.job,
    required this.status,
    required this.appliedDate,
    required this.lastUpdateDate,
    this.message,
  });

  // Durum güncellemek için yardımcı metod
  void updateStatus(ApplicationStatus newStatus) {
    status = newStatus;
    lastUpdateDate = DateTime.now();
  }
}
