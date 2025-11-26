import '../models/minigame_model.dart';

class DepartmentGameContent {
  // Hafıza Oyunu için buton etiketleri
  static List<String> getMemoryButtons(String? departmentName) {
    if (departmentName == null) {
      return ["Veri Girişi", "Rapor Onayı", "Geri Bildirim", "Revize"];
    } else if (departmentName.contains("Bilgisayar") || departmentName.contains("Yazılım")) {
      return ["Kod Yaz", "Test Et", "Commit", "Deploy"];
    } else if (departmentName.contains("Hukuk")) {
      return ["Dosya İncele", "Dava Hazırla", "Müvekkil Görüş", "Duruşma"];
    } else if (departmentName.contains("İşletme") || departmentName.contains("İktisat")) {
      return ["Rapor Hazırla", "Sunum Yap", "Müşteri Görüş", "Onay Al"];
    } else if (departmentName.contains("Tıp")) {
      return ["Muayene Et", "Teşhis Koy", "Tedavi Planla", "Rapor Yaz"];
    }
    return ["Veri Girişi", "Rapor Onayı", "Geri Bildirim", "Revize"];
  }

  // Hafıza Oyunu için şaşırtmaca mesajı
  static String getDistractionMessage(String? departmentName) {
    if (departmentName == null) {
      return "PATRONUN FİKRİ DEĞİŞTİ!";
    } else if (departmentName.contains("Bilgisayar") || departmentName.contains("Yazılım")) {
      return "PRODUCT OWNER FİKRİ DEĞİŞTİ!";
    } else if (departmentName.contains("Hukuk")) {
      return "MÜVEKKİL FİKRİ DEĞİŞTİ!";
    } else if (departmentName.contains("İşletme") || departmentName.contains("İktisat")) {
      return "MÜDÜR FİKRİ DEĞİŞTİ!";
    } else if (departmentName.contains("Tıp")) {
      return "BAŞHEKİM FİKRİ DEĞİŞTİ!";
    }
    return "PATRONUN FİKRİ DEĞİŞTİ!";
  }

  // İkilem Oyunu için senaryolar
  static List<Map<String, dynamic>> getDilemmaScenarios(String? departmentName) {
    if (departmentName == null) {
      return _getDefaultScenarios();
    } else if (departmentName.contains("Bilgisayar") || departmentName.contains("Yazılım")) {
      return _getSoftwareScenarios();
    } else if (departmentName.contains("Hukuk")) {
      return _getLawScenarios();
    } else if (departmentName.contains("İşletme") || departmentName.contains("İktisat")) {
      return _getBusinessScenarios();
    } else if (departmentName.contains("Tıp")) {
      return _getMedicineScenarios();
    }
    return _getDefaultScenarios();
  }

  static List<Map<String, dynamic>> _getDefaultScenarios() {
    return [
      {
        "question": "Müşteri çok sinirli ve hakaret ediyor. Tepkiniz?",
        "options": [
          {"text": "Siz de bağırın", "score": 0, "isCorrect": false},
          {"text": "Sakinleştirip dinleyin", "score": 10, "isCorrect": true},
          {"text": "Telefonu yüzüne kapatın", "score": 2, "isCorrect": false},
        ]
      },
      {
        "question": "Müdürünüz, iş arkadaşınızın projesini kendi yapmış gibi sunmanızı istedi.",
        "options": [
          {"text": "Kabul et ve sun", "score": 2, "isCorrect": false},
          {"text": "Reddet ve arkadaşını savun", "score": 10, "isCorrect": true},
          {"text": "Sessiz kal ve yapma", "score": 5, "isCorrect": false},
        ]
      },
      {
        "question": "Zor bir durumda kaldınız. Ne yaparsınız?",
        "options": [
          {"text": "Yardım iste", "score": 10, "isCorrect": true},
          {"text": "Kendi başına çöz", "score": 5, "isCorrect": false},
          {"text": "Görmezden gel", "score": 0, "isCorrect": false},
        ]
      },
    ];
  }

  static List<Map<String, dynamic>> _getSoftwareScenarios() {
    return [
      {
        "question": "Product Owner, teknik olarak imkansız bir özellik istiyor ve 'Yapılabilir' diyorsunuz. Ne yaparsınız?",
        "options": [
          {"text": "Teknik açıklama yap, alternatif öner", "score": 10, "isCorrect": true},
          {"text": "Kabul et, sonra sorun çıksın", "score": 2, "isCorrect": false},
          {"text": "Direkt reddet", "score": 5, "isCorrect": false},
        ]
      },
      {
        "question": "Kod review'da arkadaşınızın kodu çok kötü. Ne yaparsınız?",
        "options": [
          {"text": "Yapıcı geri bildirim ver", "score": 10, "isCorrect": true},
          {"text": "Direkt reddet", "score": 3, "isCorrect": false},
          {"text": "Onayla, sorun çıkarsa o sorumlu", "score": 0, "isCorrect": false},
        ]
      },
      {
        "question": "Deadline'a 1 gün kala kritik bir bug buldunuz. Ne yaparsınız?",
        "options": [
          {"text": "Hemen bildir, çözüm öner", "score": 10, "isCorrect": true},
          {"text": "Sessizce düzelt, kimse bilmesin", "score": 5, "isCorrect": false},
          {"text": "Sonra hallederiz de", "score": 0, "isCorrect": false},
        ]
      },
    ];
  }

  static List<Map<String, dynamic>> _getLawScenarios() {
    return [
      {
        "question": "Müvekkiliniz, kanuna aykırı bir talepte bulundu. Ne yaparsınız?",
        "options": [
          {"text": "Kanunu hatırlatıp reddet", "score": 10, "isCorrect": true},
          {"text": "Pazarlık et", "score": 5, "isCorrect": false},
          {"text": "Hemen kabul et", "score": 0, "isCorrect": false},
        ]
      },
      {
        "question": "Duruşmada karşı tarafın avukatı size hakaret etti. Tepkiniz?",
        "options": [
          {"text": "Sakin kal, hakime bildir", "score": 10, "isCorrect": true},
          {"text": "Siz de hakaret et", "score": 0, "isCorrect": false},
          {"text": "Duruşmayı terk et", "score": 2, "isCorrect": false},
        ]
      },
      {
        "question": "Müvekkiliniz size yalan söylediğini fark ettiniz. Ne yaparsınız?",
        "options": [
          {"text": "Açıkça konuş, gerçeği söylemesini iste", "score": 10, "isCorrect": true},
          {"text": "Görmezden gel", "score": 2, "isCorrect": false},
          {"text": "Dosyayı bırak", "score": 5, "isCorrect": false},
        ]
      },
    ];
  }

  static List<Map<String, dynamic>> _getBusinessScenarios() {
    return [
      {
        "question": "Müdürünüz, raporunuzu kendi adıyla sunmanızı istedi. Ne yaparsınız?",
        "options": [
          {"text": "Kendi adınızla sunmayı talep et", "score": 10, "isCorrect": true},
          {"text": "Kabul et, işi bitir", "score": 3, "isCorrect": false},
          {"text": "Sessiz kal", "score": 5, "isCorrect": false},
        ]
      },
      {
        "question": "Müşteri, fiyatı çok düşük buldu ve şüphelendi. Ne yaparsınız?",
        "options": [
          {"text": "Şeffaf ol, değer açıkla", "score": 10, "isCorrect": true},
          {"text": "Fiyatı yükselt", "score": 5, "isCorrect": false},
          {"text": "Baskı yap, hemen karar ver", "score": 0, "isCorrect": false},
        ]
      },
      {
        "question": "Rakip firma, size çok iyi bir teklif yaptı. Mevcut işinizde kalır mısınız?",
        "options": [
          {"text": "Mevcut işverenle konuş, şans ver", "score": 10, "isCorrect": true},
          {"text": "Hemen ayrıl", "score": 3, "isCorrect": false},
          {"text": "İkisini de yürüt", "score": 0, "isCorrect": false},
        ]
      },
    ];
  }

  static List<Map<String, dynamic>> _getMedicineScenarios() {
    return [
      {
        "question": "Hasta, tedaviyi reddediyor ama hayati risk var. Ne yaparsınız?",
        "options": [
          {"text": "Açıkla, onay al, gerekirse aileye danış", "score": 10, "isCorrect": true},
          {"text": "Zorla uygula", "score": 0, "isCorrect": false},
          {"text": "Vazgeç, sorumluluk almayayım", "score": 2, "isCorrect": false},
        ]
      },
      {
        "question": "Yorgunluktan bir ilaç dozunu yanlış yazdınız. Ne yaparsınız?",
        "options": [
          {"text": "Hemen düzelt, hatayı bildir", "score": 10, "isCorrect": true},
          {"text": "Kimse fark etmez, bırak", "score": 0, "isCorrect": false},
          {"text": "Başkasına sor, o düzeltsin", "score": 3, "isCorrect": false},
        ]
      },
      {
        "question": "Hasta yakını, size rüşvet teklif etti. Ne yaparsınız?",
        "options": [
          {"text": "Reddet, etik kuralları hatırlat", "score": 10, "isCorrect": true},
          {"text": "Kabul et", "score": 0, "isCorrect": false},
          {"text": "Sessiz kal", "score": 2, "isCorrect": false},
        ]
      },
    ];
  }

  // Bölümlere göre öğrenilebilecek yetenekler (azaltılmış ve genel)
  static List<String> getAvailableSkills(String? departmentName) {
    if (departmentName == null) {
      return ["Temel Bilgisayar", "Ofis Programları", "İletişim", "Sunum", "Raporlama"];
    } else if (departmentName.contains("Bilgisayar") || departmentName.contains("Yazılım")) {
      return [
        "Programlama",
        "Veritabanı Yönetimi",
        "Proje Yönetimi",
        "Test Yazılımı",
        "UI/UX Tasarım",
        "Git Versiyon Kontrolü",
        "Algoritma ve Veri Yapıları",
      ];
    } else if (departmentName.contains("Hukuk")) {
      return [
        "Hukuk Metinleri",
        "Dava Takibi",
        "Sözleşme Hazırlama",
        "Müzakere",
        "Araştırma",
        "Sunum Teknikleri",
        "Etik",
      ];
    } else if (departmentName.contains("İşletme") || departmentName.contains("İktisat")) {
      return [
        "Muhasebe",
        "Finansal Analiz",
        "Pazarlama",
        "Satış",
        "Proje Yönetimi",
        "Excel (İleri Seviye)",
        "Raporlama",
      ];
    } else if (departmentName.contains("Tıp")) {
      return [
        "Teşhis Koyma",
        "Tedavi Planlama",
        "Hasta İletişimi",
        "Tıbbi Raporlama",
        "Acil Müdahale",
        "Etik",
        "Dokümantasyon",
      ];
    }
    return ["Temel Bilgisayar", "Ofis Programları", "İletişim", "Sunum", "Raporlama"];
  }

  // Oyun türüne ve bölüme göre kazanılabilecek yetenekler
  static List<String> getSkillsForGame(GameType gameType, String? departmentName) {
    switch (gameType) {
      case GameType.Reflex:
        // Refleks oyunu - hızlı işlem gerektiren yetenekler
        if (departmentName?.contains("Bilgisayar") == true || departmentName?.contains("Yazılım") == true) {
          return ["Programlama", "Test Yazılımı"];
        } else if (departmentName?.contains("İşletme") == true || departmentName?.contains("İktisat") == true) {
          return ["Excel (İleri Seviye)", "Raporlama"];
        } else if (departmentName?.contains("Hukuk") == true) {
          return ["Hukuk Metinleri", "Araştırma"];
        } else if (departmentName?.contains("Tıp") == true) {
          return ["Teşhis Koyma", "Acil Müdahale"];
        }
        return ["Temel Bilgisayar"];

      case GameType.Timing:
        // Zamanlama oyunu - sabır ve dayanıklılık gerektiren yetenekler
        // Tüm bölümler için genel yetenekler (getAvailableSkills'de yok, özel durum)
        if (departmentName?.contains("Bilgisayar") == true || departmentName?.contains("Yazılım") == true) {
          return ["Proje Yönetimi", "Test Yazılımı"];
        } else if (departmentName?.contains("İşletme") == true || departmentName?.contains("İktisat") == true) {
          return ["Muhasebe", "Raporlama"];
        } else if (departmentName?.contains("Hukuk") == true) {
          return ["Araştırma", "Sunum Teknikleri"];
        } else if (departmentName?.contains("Tıp") == true) {
          return ["Tedavi Planlama", "Acil Müdahale"];
        }
        return ["Raporlama"];

      case GameType.Memory:
        // Hafıza oyunu - dokümantasyon ve sıralama gerektiren yetenekler
        if (departmentName?.contains("Bilgisayar") == true || departmentName?.contains("Yazılım") == true) {
          return ["Git Versiyon Kontrolü", "Proje Yönetimi"];
        } else if (departmentName?.contains("İşletme") == true || departmentName?.contains("İktisat") == true) {
          return ["Muhasebe", "Raporlama"];
        } else if (departmentName?.contains("Hukuk") == true) {
          return ["Dava Takibi", "Araştırma"];
        } else if (departmentName?.contains("Tıp") == true) {
          return ["Dokümantasyon", "Tıbbi Raporlama"];
        }
        return ["Raporlama"];

      case GameType.Dilemma:
        // İkilem oyunu - iletişim ve etik gerektiren yetenekler
        if (departmentName?.contains("Bilgisayar") == true || departmentName?.contains("Yazılım") == true) {
          return ["Proje Yönetimi", "UI/UX Tasarım"];
        } else if (departmentName?.contains("İşletme") == true || departmentName?.contains("İktisat") == true) {
          return ["Satış", "Pazarlama"];
        } else if (departmentName?.contains("Hukuk") == true) {
          return ["Müzakere", "Etik"];
        } else if (departmentName?.contains("Tıp") == true) {
          return ["Hasta İletişimi", "Etik"];
        }
        return ["İletişim"];

      case GameType.Grind:
        // Tıklama oyunu - tekrarlayan işler ve bürokrasi
        if (departmentName?.contains("Bilgisayar") == true || departmentName?.contains("Yazılım") == true) {
          return ["Veritabanı Yönetimi", "Test Yazılımı"];
        } else if (departmentName?.contains("İşletme") == true || departmentName?.contains("İktisat") == true) {
          return ["Muhasebe", "Raporlama"];
        } else if (departmentName?.contains("Hukuk") == true) {
          return ["Sözleşme Hazırlama", "Hukuk Metinleri"];
        } else if (departmentName?.contains("Tıp") == true) {
          return ["Tıbbi Raporlama", "Dokümantasyon"];
        }
        return ["Raporlama"];
    }
  }

  // Bir yeteneğin hangi oyunla kazanılabileceğini bul
  static GameType? getGameTypeForSkill(String skill, String? departmentName) {
    // Tüm oyun türlerini kontrol et
    for (var gameType in GameType.values) {
      final skillsForGame = getSkillsForGame(gameType, departmentName);
      if (skillsForGame.contains(skill)) {
        return gameType;
      }
    }
    return null; // Yetenek hiçbir oyunla eşleşmiyorsa null döndür
  }
}

