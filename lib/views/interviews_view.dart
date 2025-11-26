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
        title: const Text("Mülakatlarım"),
        backgroundColor: Colors.indigo,
      ),
      body: interviews.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Şu an aktif bir mülakat davetiniz yok.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: interviews.length,
              itemBuilder: (context, index) {
                final app = interviews[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.chat_bubble, color: Colors.white),
                    ),
                    title: Text(
                      app.job.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${app.job.salary} TL - ${app.job.type.name}"),
                    trailing: ElevatedButton(
                      onPressed: () => _startInterview(gameVM, app),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
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
      return const Scaffold(
        body: Center(child: Text("Soru yüklenemedi.")),
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
        title: Text("Mülakat: ${_selectedApplication!.job.title}"),
        backgroundColor: Colors.indigo,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İlerleyiş Çubuğu
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey.shade300,
              color: Colors.indigo,
              minHeight: 10,
            ),
            const SizedBox(height: 24),
            // NPC / Interviewer Avatarı (Basit ikon)
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade200,
                child: const Icon(Icons.person, size: 50, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                "İşe Alım Uzmanı",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),
            // Soru
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
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
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Cevabınız:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      backgroundColor: Colors.indigo.shade50,
                      foregroundColor: Colors.indigo.shade900,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.centerLeft,
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                "Mülakat Tamamlandı",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                "Sorulara verdiğin cevapları not aldık. Değerlendirme sonucunu en kısa sürede bildireceğiz.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Mülakatı sonlandır ve ana ekrana dön
                  vm.completeInterview(_selectedApplication!, _correctAnswers);
                  Navigator.pop(context); // InterviewsView'dan çık
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text("Tamam"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
