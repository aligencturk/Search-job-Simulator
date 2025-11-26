import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/game_view_model.dart';
import '../models/job_application_model.dart';

class InterviewsView extends ConsumerStatefulWidget {
  const InterviewsView({super.key});

  @override
  ConsumerState<InterviewsView> createState() => _InterviewsViewState();
}

class _InterviewsViewState extends ConsumerState<InterviewsView> {
  // Hangi başvuru seçili?
  JobApplication? _selectedApplication;

  // Mülakat durumu
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  bool _interviewStarted = false;
  List<Map<String, dynamic>> _questions = [];

  @override
  Widget build(BuildContext context) {
    final gameVM = ref.watch(gameProvider);
    final interviews = gameVM.interviews;

    // Eğer bir mülakat seçiliyse mülakat ekranını göster
    if (_selectedApplication != null && _interviewStarted) {
      return _buildActiveInterviewScreen(gameVM);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Mülakatlarım",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: interviews.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "Şu an aktif bir mülakat davetiniz yok.",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: interviews.length,
              itemBuilder: (context, index) {
                final app = interviews[index];
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.chat_bubble, color: Colors.blue),
                    ),
                    title: Text(
                      app.job.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      "${app.job.salary.toStringAsFixed(0)} TL - ${app.job.type.name}",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _startInterview(gameVM, app),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Katıl"),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _startInterview(GameViewModel vm, JobApplication app) {
    setState(() {
      _selectedApplication = app;
      _interviewStarted = true;
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
      _questions = vm.getInterviewQuestions();
    });
    vm.startInterview(app);
  }

  Widget _buildActiveInterviewScreen(GameViewModel vm) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Hata")),
        body: const Center(child: Text("Soru yüklenemedi.")),
      );
    }

    // Tüm sorular bitti mi?
    if (_currentQuestionIndex >= _questions.length) {
      return _buildInterviewResultScreen(vm);
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final options = currentQuestion["options"] as List<String>;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Mülakat: ${_selectedApplication!.job.title}",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İlerleyiş Çubuğu
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _questions.length,
                backgroundColor: Colors.grey.shade300,
                color: Colors.red,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 24),
            // NPC / Interviewer Avatarı (Basit ikon)
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50, color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                "İşe Alım Uzmanı",
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 24),
            // Soru
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                currentQuestion["question"] as String,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Cevabınız:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            // Şıklar
            Expanded(
              child: ListView.separated(
                itemCount: options.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return ElevatedButton(
                    onPressed: () => _answerQuestion(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.centerLeft,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "${index + 1}. ${options[index]}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _answerQuestion(int selectedIndex) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final correctIndex = currentQuestion["correct"] as int;

    if (selectedIndex == correctIndex) {
      _correctAnswers++;
    }

    setState(() {
      _currentQuestionIndex++;
    });
  }

  Widget _buildInterviewResultScreen(GameViewModel vm) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                "Mülakat Tamamlandı",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              Text(
                "Sorulara verdiğin cevapları not aldık. Değerlendirme sonucunu en kısa sürede bildireceğiz.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Mülakatı sonlandır ve ana ekrana dön
                  vm.completeInterview(_selectedApplication!, _correctAnswers);
                  Navigator.pop(context); // InterviewsView'dan çık
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Tamam", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
