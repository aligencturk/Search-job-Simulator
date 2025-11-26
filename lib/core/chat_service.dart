import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';

import '../core/gemini_config.dart';

final logger = Logger();

class ChatService {
  late final GenerativeModel _model;

  ChatService() {
    _model = GenerativeModel(
      model: GeminiConfig.modelName,
      apiKey: GeminiConfig.apiKey,
    );
    logger.i("Gemini AI model başlatıldı: ${GeminiConfig.modelName}");
  }

  Future<String> sendMessage(String userMessage, {String? context}) async {
    try {
      final prompt = context != null 
          ? "Oyun bağlamı: $context\n\nKullanıcı: $userMessage"
          : userMessage;

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      final text = response.text ?? "Yanıt alınamadı.";
      logger.i("AI yanıtı alındı: ${text.substring(0, text.length > 50 ? 50 : text.length)}...");
      
      return text;
    } catch (e) {
      logger.e("Chat hatası: $e");
      return "Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin.";
    }
  }

  Stream<String> sendMessageStream(String userMessage, {String? context}) async* {
    try {
      final prompt = context != null 
          ? "Oyun bağlamı: $context\n\nKullanıcı: $userMessage"
          : userMessage;

      final content = [Content.text(prompt)];
      final response = _model.generateContentStream(content);
      
      await for (final chunk in response) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      logger.e("Chat stream hatası: $e");
      yield "Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin.";
    }
  }
}

