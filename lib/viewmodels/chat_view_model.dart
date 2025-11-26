import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../core/chat_service.dart';
import '../core/enums.dart';
import '../viewmodels/game_view_model.dart';

final logger = Logger();

final chatServiceProvider = Provider((ref) => ChatService());

final chatViewModelProvider = ChangeNotifierProvider((ref) => ChatViewModel(ref));

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatViewModel extends ChangeNotifier {
  final Ref _ref;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  ChatViewModel(this._ref);

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  String _getGameContext() {
    final gameVM = _ref.read(gameProvider);
    final player = gameVM.player;
    final dept = gameVM.department;

    if (player == null || dept == null) {
      return "Oyun henüz başlamadı.";
    }

    return """
Karakter Bilgileri:
- Cinsiyet: ${player.gender == Gender.Male ? "Erkek" : "Kadın"}
- Askerlik Durumu: ${_getMilitaryStatusText(player.militaryStatus)}
- Para: ${player.money.toStringAsFixed(0)} TL
- Bölüm: ${dept.name}
- Yetenekler: ${player.skills.join(", ")}
""";
  }

  String _getMilitaryStatusText(MilitaryStatus status) {
    switch (status) {
      case MilitaryStatus.Exempt:
        return "Muaf";
      case MilitaryStatus.NotDone:
        return "Yapılmadı";
      case MilitaryStatus.Done:
        return "Yapıldı";
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    // Kullanıcı mesajını ekle
    _messages.add(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    try {
      final chatService = _ref.read(chatServiceProvider);
      final context = _getGameContext();
      
      // Stream kullanarak yanıtı al
      String fullResponse = "";
      await for (final chunk in chatService.sendMessageStream(text, context: context)) {
        fullResponse += chunk;
        // Son mesajı güncelle veya yeni oluştur
        if (_messages.isNotEmpty && !_messages.last.isUser) {
          _messages.last = ChatMessage(
            text: fullResponse,
            isUser: false,
            timestamp: _messages.last.timestamp,
          );
        } else {
          _messages.add(ChatMessage(
            text: fullResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        }
        notifyListeners();
      }
    } catch (e) {
      logger.e("Mesaj gönderme hatası: $e");
      _messages.add(ChatMessage(
        text: "Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin.",
        isUser: false,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}

