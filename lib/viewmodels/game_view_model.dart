import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../core/department_game_content.dart';
import '../core/enums.dart';
import '../models/cv_model.dart';
import '../models/department_model.dart';
import '../models/job_application_model.dart';
import '../models/job_model.dart';
import '../models/minigame_model.dart';
import '../models/player_model.dart';
import '../models/event_model.dart';
import '../models/story_model.dart';

final logger = Logger();

final gameProvider = ChangeNotifierProvider((ref) => GameViewModel());

class GameViewModel extends ChangeNotifier {
  Player? _player;
  Department? _department;
  List<Job> _availableJobs = [];
  String _lastMessage = "";
  List<CVTask> _completedTasks = [];
  List<CVExperience> _experiences = [];
  List<JobApplication> _applications = [];
  DateTime _currentDate = DateTime.now();
  List<Story> _stories = [];
  bool _livingWithFamily = true;
  static const double _optionalHangoutCost = 100;
  final Random _random = Random();
  FinancialEvent? _pendingFinancialEvent;
  Map<String, dynamic> _gameData = {};
  int _mentalHealth = 100;
  static const int _mentalCrisisThreshold = 30;
  bool _mentalCrisisQueued = false;

  Player? get player => _player;
  Department? get department => _department;
  List<Job> get availableJobs => _availableJobs;
  String get lastMessage => _lastMessage;
  List<CVTask> get completedTasks => _completedTasks;
  List<CVExperience> get experiences => _experiences;
  List<JobApplication> get applications => _applications;
  DateTime get currentDate => _currentDate;
  List<Story> get stories => _stories;
  bool get livingWithFamily => _livingWithFamily;
  double get optionalHangoutCost => _optionalHangoutCost;
  FinancialEvent? get pendingFinancialEvent => _pendingFinancialEvent;
  int get mentalHealth => _mentalHealth;

  // İş bulunup bulunmadığını kontrol et
  bool get hasJob {
    return _applications.any((app) => app.status == ApplicationStatus.Accepted);
  }

  // Tarih formatı (Gün Ay Yıl) - Türkçe
  String get formattedDate {
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
    return '${_currentDate.day} ${months[_currentDate.month - 1]} ${_currentDate.year}';
  }

  // Mülakatlar (Interview status'ü olanlar)
  List<JobApplication> get interviews => _applications
      .where((app) => app.status == ApplicationStatus.Interview)
      .toList();

  // Oyun Verilerini Yükle
  Future<void> loadGameData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/game_data.json',
      );
      _gameData = json.decode(jsonString);
      logger.i("Oyun verileri yüklendi.");
      notifyListeners();
    } catch (e) {
      logger.e("Oyun verileri yüklenirken hata oluştu: $e");
    }
  }

  // Oyun Başlatma / Setup
  void startGame(String name, Gender gender, Department department) {
    loadGameData(); // Verileri yükle

    MilitaryStatus militaryStatus = (gender == Gender.Female)
        ? MilitaryStatus.Exempt
        : MilitaryStatus.NotDone;

    _player = Player(
      name: name,
      gender: gender,
      militaryStatus: militaryStatus,
      skills: ["Temel Bilgisayar"], // Varsayılan yetenek
    );
    _department = department;
    _currentDate = DateTime.now(); // Oyun başladığında bugünün tarihi
    _livingWithFamily = true;
    _pendingFinancialEvent = null;
    _mentalHealth = 100;

    _generateJobs();

    logger.i(
      "Oyun başladı: $name, ${gender.name}, ${department.name}, Askerlik: ${militaryStatus.name}, Tarih: ${formattedDate}",
    );
    notifyListeners();
  }

  // Oyunu Sıfırlama
  void resetGame() {
    _player = null;
    _department = null;
    _availableJobs = [];
    _lastMessage = "";
    _completedTasks = [];
    _experiences = [];
    _applications = [];
    _currentDate = DateTime.now();
    _stories = [];
    _livingWithFamily = true;
    _pendingFinancialEvent = null;
    _mentalHealth = 100;
    logger.i("Oyun sıfırlandı");
    notifyListeners();
  }

  FinancialEvent? consumeFinancialEvent() {
    final event = _pendingFinancialEvent;
    _pendingFinancialEvent = null;
    return event;
  }

  void _changeMentalHealth(int delta, {String? reason}) {
    final newValue = (_mentalHealth + delta).clamp(0, 100);
    if (newValue == _mentalHealth) return;
    _mentalHealth = newValue;
    logger.i("Mental sağlık değişti (${reason ?? 'belirsiz'}): $_mentalHealth");

    if (_mentalHealth < _mentalCrisisThreshold) {
      if (!_mentalCrisisQueued) {
        _mentalCrisisQueued = true;
        _lastMessage = "Mental sağlık kritik seviyede! Bir mola vermelisin.";
      }
    } else {
      _mentalCrisisQueued = false;
    }
  }

  OptionalExpenseResult handleFinancialDecision(bool accepted) {
    if (_player == null) {
      logger.w("Player bulunamadığı için finansal olay işlenemedi");
      return OptionalExpenseResult.declined;
    }

    // Mevcut olayı al (bazen consume edildikten sonra çağrılabilir, UI tarafında event parametre olarak da tutulabilir ama
    // burada son işlenen olay gibi de düşünebiliriz, ama en doğrusu UI'dan ne seçildiğini bilmek.
    // Şimdilik UI zaten event detaylarını biliyor, biz sadece işlemi yapıyoruz.
    // Ancak burada hangi event'e cevap verildiğini bilmemiz lazım.
    // Basitlik adına: consumeFinancialEvent ile UI eventi alır, kullanıcı karar verince buraya parametrelerle gelir.
    // Ama biz sadece accepted bool alıyoruz. Bu yüzden UI tarafında hangi event olduğu biliniyor olmalı.
    // O yüzden bu metodu biraz daha generic yapalım veya UI event detaylarını göndersin.
    // Şimdilik basitçe: UI'dan event detaylarını (amount, isChoice) parametre olarak alalım.
    // Ya da en son pending event'i bir "processing" state'inde tutabiliriz.
    // En temizi: UI, event'i parametre olarak geçsin.
    // Ama mevcut yapıyı çok bozmamak için, handleFinancialDecision sadece "seçimli" olanlar için çalışacak.

    // Burası eski hangout decision'ın yerini alacak ama parametre lazım.
    // O yüzden bu metodu güncelliyorum:
    return OptionalExpenseResult
        .declined; // Placeholder, aşağıda yenisini yazacağım.
  }

  OptionalExpenseResult processFinancialEvent(
    FinancialEvent event,
    bool accepted,
  ) {
    if (_player == null) return OptionalExpenseResult.declined;

    if (!event.isChoice) {
      // Zorunlu olay
      if (event.amount > 0) {
        // Gelir
        _player!.money += event.amount;
        _lastMessage =
            "${event.title}: ${event.amount.toStringAsFixed(0)} TL eklendi.";
        notifyListeners();
        return OptionalExpenseResult
            .paid; // Gelir için de paid dönelim (işlem tamam)
      } else {
        // Gider
        // Zorunlu giderlerde para yetmese de düşebilir (borç) veya 0'a inebilir.
        // Oyun kuralı: Para eksiye düşebilir mi? Şimdilik düşsün.
        _player!.money += event.amount; // amount negatif
        _lastMessage =
            "${event.title}: ${event.amount.abs().toStringAsFixed(0)} TL harcandı.";
        notifyListeners();
        return OptionalExpenseResult.infoConfirmed;
      }
    } else {
      // Seçimli olay
      if (!accepted) {
        _lastMessage = "${event.title}: Reddettiniz, işlem yapılmadı.";
        notifyListeners();
        return OptionalExpenseResult.declined;
      }

      // Kabul edildi
      if (event.amount > 0) {
        // Seçimli gelir? (Şu an yok ama olabilir)
        _player!.money += event.amount;
        notifyListeners();
        return OptionalExpenseResult.paid;
      } else {
        // Seçimli gider
        if (_player!.money >= event.amount.abs()) {
          _player!.money += event.amount; // amount negatif
          _lastMessage =
              "${event.title}: ${event.amount.abs().toStringAsFixed(0)} TL harcandı.";
          notifyListeners();
          return OptionalExpenseResult.paid;
        } else {
          _lastMessage = "${event.title}: Yetersiz bakiye!";
          notifyListeners();
          return OptionalExpenseResult.insufficientFunds;
        }
      }
    }
  }

  String _eventTypeKey(EventType type) {
    switch (type) {
      case EventType.Daily:
        return "daily";
      case EventType.Monthly:
        return "monthly";
      case EventType.Yearly:
        return "yearly";
    }
  }

  Map<String, dynamic>? _getRandomEventFromJson({
    required bool isWorking,
    required EventType type,
  }) {
    if (_gameData.isEmpty || _gameData['events'] == null) return null;

    final eventsRoot = _gameData['events'];
    if (eventsRoot is! Map) return null;

    final employmentKey = isWorking ? 'working' : 'jobless';
    final employmentEvents = eventsRoot[employmentKey];
    if (employmentEvents is! Map) return null;

    final typeKey = _eventTypeKey(type);
    final typeEvents = employmentEvents[typeKey];
    if (typeEvents is! Map) return null;

    final List<Map<String, dynamic>> pool = [];
    final defaultMentalDelta = typeEvents['default_mental_delta'];

    final generalEvents = typeEvents['general'];
    if (generalEvents is List) {
      for (final event in generalEvents) {
        if (event is Map<String, dynamic>) {
          final eventCopy = Map<String, dynamic>.from(event);
          if (eventCopy['mental_delta'] == null && defaultMentalDelta is num) {
            eventCopy['mental_delta'] = defaultMentalDelta;
          }
          pool.add(eventCopy);
        }
      }
    }

    final deptName = _department?.name;
    final departmentsData = typeEvents['departments'];
    if (deptName != null && departmentsData is Map) {
      for (final entry in departmentsData.entries) {
        final key = entry.key.toString();
        final matches =
            key == deptName || deptName.contains(key) || key.contains(deptName);
        if (!matches) continue;

        final deptEvents = entry.value;
        if (deptEvents is List) {
          for (final event in deptEvents) {
            if (event is Map<String, dynamic>) {
              final eventCopy = Map<String, dynamic>.from(event);
              if (eventCopy['mental_delta'] == null &&
                  defaultMentalDelta is num) {
                eventCopy['mental_delta'] = defaultMentalDelta;
              }
              pool.add(eventCopy);
            }
          }
        }
      }
    }

    if (pool.isEmpty) return null;

    return pool[_random.nextInt(pool.length)];
  }

  Map<String, dynamic>? _getMentalCrisisEvent() {
    if (_gameData.isEmpty || _gameData['mental_events'] == null) {
      return {
        "description":
            "Mental sağlığın kritik seviyede. Kendini kapana kısılmış hissediyorsun.",
        "options": [
          "Derin nefes egzersizi yap",
          "Bir arkadaşını ara",
          "Hiçbir şey yapmak istemiyorum",
        ],
        "mental_delta": 8,
      };
    }

    final mentalEvents = _gameData['mental_events'];
    final lowSection = mentalEvents['low_threshold'];
    if (lowSection is! Map) return null;

    final threshold = lowSection['threshold'];
    if (threshold is num && _mentalHealth >= threshold) return null;

    final events = lowSection['events'];
    if (events is! List || events.isEmpty) return null;

    final selected = events[_random.nextInt(events.length)];
    if (selected is Map<String, dynamic>) {
      return Map<String, dynamic>.from(selected);
    }
    return null;
  }

  Event _buildEventFromMap(Map<String, dynamic> eventMap, EventType type) {
    final description =
        (eventMap['description'] ?? eventMap['desc'] ?? "Bir olay gerçekleşti.")
            .toString();
    final optionsRaw = eventMap['options'] ?? eventMap['opts'];
    List<String> options;

    if (optionsRaw is List) {
      options = optionsRaw.map((e) => e.toString()).toList();
    } else {
      options = ["Tamam", "Devam"];
    }

    if (options.isEmpty) {
      options = ["Tamam"];
    }

    final mentalDeltaRaw = eventMap['mental_delta'];
    if (mentalDeltaRaw is num && mentalDeltaRaw != 0) {
      _changeMentalHealth(mentalDeltaRaw.toInt(), reason: description);
    }

    return Event(
      date: _currentDate,
      description: description,
      options: options,
      type: type,
    );
  }

  // Event Üretme (Dialog için)
  Event _generateEvent(EventType type) {
    if (_player == null || _department == null) {
      return Event(
        date: _currentDate,
        description: "Bir olay gerçekleşti.",
        options: ["Tamam", "Anladım", "Devam"],
        type: type,
      );
    }

    if (_mentalCrisisQueued) {
      final crisisEvent = _getMentalCrisisEvent();
      if (crisisEvent != null) {
        final event = _buildEventFromMap(crisisEvent, type);
        _mentalCrisisQueued = _mentalHealth < _mentalCrisisThreshold;
        return event;
      }
    }

    final random = _random;
    final departmentName = _department!.name;

    // İş durumuna göre eventler
    if (hasJob) {
      // İş bulunduysa → İş yerindeki olaylar + günlük olaylar karışık
      return _generateWorkEvent(type, departmentName, random);
    } else {
      // İş bulunmadıysa → İş arama sürecindeki olaylar
      return _generateJobSearchEvent(type, departmentName, random);
    }
  }

  // İş arama sürecindeki eventler
  Event _generateJobSearchEvent(
    EventType type,
    String departmentName,
    Random random,
  ) {
    final jsonEvent = _getRandomEventFromJson(isWorking: false, type: type);
    if (jsonEvent != null) {
      return _buildEventFromMap(jsonEvent, type);
    }

    String description = "";
    List<String> options = [];

    // Bölüme göre eventler
    if (departmentName.contains("Bilgisayar") ||
        departmentName.contains("Yazılım")) {
      switch (type) {
        case EventType.Daily:
          final events = [
            // İş arama olayları
            {
              "desc": "En yakın arkadaşın iş buldu, sen hala işsizsin.",
              "opts": ["Onu tebrik et", "Onunla kutla", "Kıskançlık yap"],
            },
            {
              "desc": "GitHub'da projen star aldı, ama iş hala yok.",
              "opts": ["Sevin", "Paylaş", "Umutsuzluğa kapıl"],
            },
            // Ailesel olaylar
            {
              "desc":
                  "Annen seni ekmek almaya gönderdi, eve gelirken köpek kovaladı, ekmek düştü.",
              "opts": ["Tekrar al", "Ağla", "Küfür et"],
            },
            {
              "desc":
                  "Baban 'ne zaman iş bulacaksın' diye sordu, cevap veremedin.",
              "opts": ["İçinden söv", "...", "..."],
            },
            {
              "desc": "Kardeşin iş buldu, aile onu kutluyor, sen yalnızsın.",
              "opts": ["Kutla", "Kıskan, maaşına çök.", "Üzül"],
            },
            {
              "desc":
                  "Annen kahvaltı yapmadın diye kızdı, 'yine mi yatıyorsun' dedi.",
              "opts": ["Özür dile", "Kabul et", "Kızgın ol"],
            },
            {
              "desc":
                  "Baban cep telefonu faturası geldi diye kızdı, 'para yok' dedin.",
              "opts": ["Özür dile", "Kabul et", "Kızgın ol"],
            },
            {
              "desc":
                  "Annen komşuya gitti, 'oğlum işsiz' diye anlattı, utandın.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            // Çevresel olaylar
            {
              "desc":
                  "Marketten alışveriş yaparken cüzdanı evde unuttun, geri döndün.",
              "opts": ["Tekrar git", "Vazgeç", "Küfür et"],
            },
            {
              "desc":
                  "Otobüs geç kaldı, iş görüşmesi kaçtı, eve döndün yattın.",
              "opts": ["Kabul et", "Üzül", "Küfür et"],
            },
            {
              "desc":
                  "Komşu şikayet etti, 'gece geç saatte gürültü yapıyorsun' dedi.",
              "opts": ["Özür dile", "Kabul et", "Kızgın ol"],
            },
            {
              "desc":
                  "Internet kesildi, iş başvurusu yapamadın, komşudan şifre istedin, vermedi.",
              "opts": ["Kabul et", "Üzül", "Küfür et"],
            },
            {
              "desc": "Su kesilmiş, banyo yapamadın, dışarı çıkamadın.",
              "opts": ["Kabul et", "Şikayet et", "Küfür et"],
            },
            {
              "desc":
                  "Arkadaşların buluştu, sen para yok diye gitmedin, Instagram'da fotoğrafları gördün.",
              "opts": ["Üzül", "Kıskan", "Kabul et"],
            },
            {
              "desc": "Teknik mülakata gittin, algoritma sorusunda takıldın.",
              "opts": ["Çalışmaya devam et", "Üzül", "Vazgeç"],
            },
            {
              "desc": "Freelance iş buldun ama müşteri para vermedi.",
              "opts": ["Dava aç", "Kabul et", "Küfür et"],
            },
            {
              "desc": "Bootcamp'e yazıldın, ilk ders çok zordu.",
              "opts": ["Devam et", "Bırak", "Şikayet et"],
            },
            {
              "desc": "Hackathon'a katıldın, projeni bitiremedin.",
              "opts": ["Tekrar dene", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc": "LinkedIn'de iş ilanı gördün, 5+ yıl tecrübe istiyor.",
              "opts": ["Yine de başvur", "Geç", "Sinirlen"],
            },
            {
              "desc": "Kod yazarken bilgisayarın çöktü, tüm proje gitti.",
              "opts": ["Tekrar yaz", "Ağla", "Küfür et"],
            },
            {
              "desc": "Staj başvurusu yaptın, 'tecrübe yetersiz' dediler.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc": "Online kursa 5000 TL harcadın, hala iş yok.",
              "opts": ["Devam et", "Para israfı", "Şikayet et"],
            },
            // Ailesel olaylar
            {
              "desc":
                  "Annen seni ekmek almaya gönderdi, eve gelirken köpek kovaladı, ekmek düştü.",
              "opts": ["Tekrar al", "Ağla", "Küfür et"],
            },
            {
              "desc":
                  "Baban 'ne zaman iş bulacaksın' diye sordu, cevap veremedin.",
              "opts": ["Özür dile", "Kabul et", "Kızgın ol"],
            },
            {
              "desc": "Kardeşin iş buldu, aile onu kutluyor, sen yalnızsın.",
              "opts": ["Kutla", "Kıskan", "Üzül"],
            },
            {
              "desc":
                  "Annen kahvaltı yapmadın diye kızdı, 'yine mi yatıyorsun' dedi.",
              "opts": ["Özür dile", "Kabul et", "Kızgın ol"],
            },
            // Çevresel olaylar
            {
              "desc":
                  "Marketten alışveriş yaparken cüzdanı evde unuttun, geri döndün.",
              "opts": ["Tekrar git", "Vazgeç", "Küfür et"],
            },
            {
              "desc":
                  "Otobüs geç kaldı, iş görüşmesi kaçtı, eve döndün yattın.",
              "opts": ["Kabul et", "Üzül", "Küfür et"],
            },
            {
              "desc":
                  "Internet kesildi, iş başvurusu yapamadın, komşudan şifre istedin, vermedi.",
              "opts": ["Kabul et", "Üzül", "Küfür et"],
            },
            {
              "desc":
                  "Arkadaşların buluştu, sen para yok diye gitmedin, Instagram'da fotoğrafları gördün.",
              "opts": ["Üzül", "Kıskan", "Kabul et"],
            },
          ];
          final event = events[random.nextInt(events.length)];
          description = event["desc"] as String;
          options = event["opts"] as List<String>;
          break;
        case EventType.Monthly:
          final events = [
            {
              "desc": "Bu ay 10 iş görüşmesine gittin, hepsi reddetti.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc": "Arkadaşların iş buldu, evlendi, sen hala işsizsin.",
              "opts": ["Kutla", "Kıskan", "Üzül"],
            },
            {
              "desc": "Freelance işler yaptın, müşteriler para vermedi.",
              "opts": ["Dava aç", "Kabul et", "Küfür et"],
            },
            {
              "desc": "GitHub'da 20 proje yükledin, kimse star vermedi.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc": "Bootcamp'e 10000 TL harcadın, iş bulamadın.",
              "opts": ["Devam et", "Para israfı", "Şikayet et"],
            },
            {
              "desc": "Hackathon'lara katıldın, hiçbirinde kazanamadın.",
              "opts": ["Tekrar dene", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc":
                  "Online kurslara 15000 TL harcadın, sertifika aldın ama iş yok.",
              "opts": ["Devam et", "Para israfı", "Şikayet et"],
            },
            {
              "desc": "Staj başvuruları yaptın, hepsi reddetti.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc": "Kod yazdın, projeleri bitiremedin, deadline'lar kaçtı.",
              "opts": ["Devam et", "Vazgeç", "Küfür et"],
            },
            {
              "desc": "Aylık bütçe bitti, annenden borç aldın.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            // Ailesel olaylar
            {
              "desc":
                  "Bu ay memlekete gittiniz, baban sana günlerini zehir etti, akrabalar 'ne iş yapıyorsun' diye sordu.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu ay kira ödemedin, ev sahibi kapıya dayandı, annenden borç aldın.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu ay aile toplantısı vardı, herkes iş bulmuş, sen hala işsizsin, utandın.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu ay baban sürekli 'ne zaman iş bulacaksın' diye sordu, sinirlendin.",
              "opts": ["Kabul et", "İtiraz et", "Kızgın ol"],
            },
            // Çevresel olaylar
            {
              "desc":
                  "Bu ay arkadaşların evlendi, düğüne gittin, cebinde para kalmadı.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu ay doğum günün geldi, kimse hatırlamadı, kendin pasta aldın, yalnız yedin.",
              "opts": ["Üzül", "Kabul et", "Kızgın ol"],
            },
          ];
          final event = events[random.nextInt(events.length)];
          description = event["desc"] as String;
          options = event["opts"] as List<String>;
          break;
        case EventType.Yearly:
          final events = [
            {
              "desc": "Bu yıl 100 iş görüşmesine gittin, hepsi reddetti.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc":
                  "Arkadaşların iş buldu, evlendi, araba aldı, sen hala işsizsin.",
              "opts": ["Nasip", "Kıskan", "Üzül"],
            },
            {
              "desc":
                  "Freelance işler yaptın, müşteriler para vermedi, borç birikti.",
              "opts": ["Dava aç", "Bir şey yapma", "Küfür et"],
            },
            {
              "desc": "GitHub'da 100 proje yükledin, kimse star vermedi.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc": "Bootcamp ve kurslara 50000 TL harcadın, iş bulamadın.",
              "opts": ["Devam et", "Para israfı", "Şikayet et"],
            },
            {
              "desc": "Hackathon'lara katıldın, hiçbirinde kazanamadın.",
              "opts": ["Tekrar dene", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc":
                  "Online kurslara 30000 TL harcadın, sertifika aldın ama iş yok.",
              "opts": ["Devam et", "Para israfı", "Şikayet et"],
            },
            {
              "desc": "Staj başvuruları yaptın, hepsi reddetti.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc":
                  "Kod yazdın, projeleri bitiremedin, deadline'lar kaçtı, müşteriler kızdı.",
              "opts": ["Devam et", "Vazgeç", "Küfür et"],
            },
            {
              "desc":
                  "Yıllık bütçe bitti, aile baskısı arttı, 'ne zaman iş bulacaksın' diye sordular.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            // Ailesel olaylar
            {
              "desc":
                  "Bu yıl aile baskısı arttı, 'ne zaman evleneceksin' diye sordular, sen hala işsizsin.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu yıl baban 'seni asker yapamadık, iş de bulamadın' diye sürekli kızdı.",
              "opts": ["Kabul et", "Özür dile", "Kızgın ol"],
            },
            // Çevresel olaylar
            {
              "desc":
                  "Bu yıl arkadaşların evlendi, düğüne gittin, harçlık verdin, borç birikti.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu yıl eski arkadaşlarınla buluştun, herkes iş bulmuş, evlenmiş, sen hala işsizsin.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
          ];
          final event = events[random.nextInt(events.length)];
          description = event["desc"] as String;
          options = event["opts"] as List<String>;
          break;
      }
    } else if (departmentName.contains("Hukuk")) {
      switch (type) {
        case EventType.Daily:
          final events = [
            {
              "desc":
                  "En yakın arkadaşın avukatlık bürosunda iş buldu, sen hala işsizsin.",
              "opts": ["Onu tebrik et", "Onunla kutla", "Kıskançlık yap"],
            },
            {
              "desc": "Dava dosyası hazırladın, hata yaptın, müvekkil kızdı.",
              "opts": ["Düzelt", "Özür dile", "Küfür et"],
            },
            {
              "desc":
                  "Avukatlık bürosuna gittin, staj yeri istedin, 'yer yok' dediler.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc": "Duruşmaya gittin, dava kaybettin, müvekkil kızdı.",
              "opts": ["Kabul et", "Özür dile", "Küfür et"],
            },
            {
              "desc": "Müvekkil görüşmesi yaptın, dava kaybettin.",
              "opts": ["Kabul et", "Özür dile", "Kızgın ol"],
            },
            {
              "desc": "Dava dosyası kayboldu, aradın bulamadın.",
              "opts": ["Tekrar hazırla", "Panik yap", "Küfür et"],
            },
            {
              "desc": "Staj başvurusu yaptın, 'tecrübe yetersiz' dediler.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc": "Kanun kitabı okudun, hiçbir şey anlamadın.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc":
                  "Müvekkil aradı, 'dava kaybettik' dedi, sen hatırlamıyordun.",
              "opts": ["Özür dile", "Kabul et", "Küfür et"],
            },
            {
              "desc":
                  "Avukatlık bürosuna gittin, iş istedin, 'yer yok' dediler.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            // Ailesel olaylar
            {
              "desc":
                  "Annen seni ekmek almaya gönderdi, eve gelirken köpek kovaladı, ekmek düştü.",
              "opts": ["Tekrar al", "Ağla", "Küfür et"],
            },
            {
              "desc":
                  "Baban 'ne zaman iş bulacaksın' diye sordu, cevap veremedin.",
              "opts": ["Özür dile", "Kabul et", "Kızgın ol"],
            },
            {
              "desc": "Kardeşin iş buldu, aile onu kutluyor, sen yalnızsın.",
              "opts": ["Kutla", "Kıskan", "Üzül"],
            },
            {
              "desc":
                  "Annen kahvaltı yapmadın diye kızdı, 'yine mi yatıyorsun' dedi.",
              "opts": ["Özür dile", "Kabul et", "Kızgın ol"],
            },
            // Çevresel olaylar
            {
              "desc":
                  "Marketten alışveriş yaparken cüzdanı evde unuttun, geri döndün.",
              "opts": ["Tekrar git", "Vazgeç", "Küfür et"],
            },
            {
              "desc":
                  "Otobüs geç kaldı, iş görüşmesi kaçtı, eve döndün yattın.",
              "opts": ["Kabul et", "Üzül", "Küfür et"],
            },
            {
              "desc":
                  "Internet kesildi, iş başvurusu yapamadın, komşudan şifre istedin, vermedi.",
              "opts": ["Kabul et", "Üzül", "Küfür et"],
            },
            {
              "desc":
                  "Arkadaşların buluştu, sen para yok diye gitmedin, Instagram'da fotoğrafları gördün.",
              "opts": ["Üzül", "Kıskan", "Kabul et"],
            },
          ];
          final event = events[random.nextInt(events.length)];
          description = event["desc"] as String;
          options = event["opts"] as List<String>;
          break;
        case EventType.Monthly:
          final events = [
            {
              "desc": "Bu ay 10 staj başvurusu yaptın, hepsi reddetti.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc":
                  "Arkadaşların avukatlık bürosunda iş buldu, sen hala işsizsin.",
              "opts": ["Kutla", "Kıskan", "Üzül"],
            },
            {
              "desc":
                  "Dava dosyaları hazırladın, hepsi kayboldu, müvekkiller kızdı.",
              "opts": ["Tekrar hazırla", "Özür dile", "Küfür et"],
            },
            {
              "desc":
                  "Duruşmalara gittin, hepsini kaybettin, müvekkiller kızdı.",
              "opts": ["Kabul et", "Özür dile", "Kızgın ol"],
            },
            {
              "desc": "Müvekkil görüşmeleri yaptın, hepsi dava kaybetti.",
              "opts": ["Kabul et", "Özür dile", "Küfür et"],
            },
            {
              "desc": "Staj yaptın, hiçbir şey öğrenmedin, sadece çay içtin.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc":
                  "Avukatlık bürosuna gittin, iş istedin, 'yer yok' dediler.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc": "Aylık bütçe bitti, annenden borç aldın.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc": "Kanun kitabı okudun, hiçbir şey anlamadın.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc":
                  "Dava dosyaları hazırladın, hepsi hatalıydı, müvekkiller kızdı.",
              "opts": ["Düzelt", "Özür dile", "Küfür et"],
            },
          ];
          final event = events[random.nextInt(events.length)];
          description = event["desc"] as String;
          options = event["opts"] as List<String>;
          break;
        case EventType.Yearly:
          final events = [
            {
              "desc": "Bu yıl 100 staj başvurusu yaptın, hepsi reddetti.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc":
                  "Arkadaşların avukatlık bürosunda iş buldu, evlendi, sen hala işsizsin.",
              "opts": ["Kutla", "Kıskan", "Üzül"],
            },
            {
              "desc":
                  "Dava dosyaları hazırladın, hepsi kayboldu, müvekkiller kızdı.",
              "opts": ["Tekrar hazırla", "Özür dile", "Küfür et"],
            },
            {
              "desc":
                  "Duruşmalara gittin, hepsini kaybettin, müvekkiller kızdı.",
              "opts": ["Kabul et", "Özür dile", "Kızgın ol"],
            },
            {
              "desc": "Müvekkil görüşmeleri yaptın, hepsi dava kaybetti.",
              "opts": ["Kabul et", "Özür dile", "Küfür et"],
            },
            {
              "desc": "Staj yaptın, hiçbir şey öğrenmedin, sadece çay içtin.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc":
                  "Avukatlık bürosuna gittin, iş istedin, 'yer yok' dediler.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc":
                  "Yıllık bütçe bitti, aile baskısı arttı, 'ne zaman iş bulacaksın' diye sordular.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc": "Kanun kitabı okudun, hiçbir şey anlamadın.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc":
                  "Dava dosyaları hazırladın, hepsi hatalıydı, müvekkiller kızdı.",
              "opts": ["Düzelt", "Özür dile", "Küfür et"],
            },
            // Ailesel olaylar
            {
              "desc":
                  "Bu yıl aile baskısı arttı, 'ne zaman evleneceksin' diye sordular, sen hala işsizsin.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu yıl baban 'seni asker yapamadık, iş de bulamadın' diye sürekli kızdı.",
              "opts": ["Kabul et", "Özür dile", "Kızgın ol"],
            },
            // Çevresel olaylar
            {
              "desc":
                  "Bu yıl arkadaşların evlendi, düğüne gittin, harçlık verdin, borç birikti.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu yıl eski arkadaşlarınla buluştun, herkes iş bulmuş, evlenmiş, sen hala işsizsin.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
          ];
          final event = events[random.nextInt(events.length)];
          description = event["desc"] as String;
          options = event["opts"] as List<String>;
          break;
      }
    } else if (departmentName.contains("İşletme") ||
        departmentName.contains("İktisat")) {
      switch (type) {
        case EventType.Daily:
          final events = [
            {
              "desc": "En yakın arkadaşın iş buldu, sen hala işsizsin.",
              "opts": ["Onu tebrik et", "Onunla kutla", "Kıskan"],
            },
            {
              "desc": "İş görüşmesi vardı, 'tecrübe yetersiz' dediler.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc": "Rapor hazırladın, patron beğenmedi, tekrar yaptın.",
              "opts": ["Kabul et", "Özür dile", "Küfür et"],
            },
            {
              "desc":
                  "Müşteri görüşmesi yaptın, satış yapamadın, patron kızdı.",
              "opts": ["Kabul et", "Özür dile", "Kızgın ol"],
            },
            {
              "desc": "Sunum hazırladın, kötü geçti, patron kızdı.",
              "opts": ["Kabul et", "Özür dile", "Küfür et"],
            },
            {
              "desc": "Excel'de formül yazdın, hata verdi, 5 saat uğraştın.",
              "opts": ["Devam et", "Vazgeç", "Küfür et"],
            },
            {
              "desc": "Müşteri aradı, şikayet etti, sen çözemedin.",
              "opts": ["Özür dile", "Kabul et", "Kızgın ol"],
            },
            {
              "desc": "Staj başvurusu yaptın, 'tecrübe yetersiz' dediler.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc": "Rapor hazırladın, kayboldu, patron kızdı.",
              "opts": ["Tekrar hazırla", "Özür dile", "Küfür et"],
            },
            {
              "desc": "İş ilanlarına baktın, hepsi 3+ yıl tecrübe istiyor.",
              "opts": ["Yine de başvur", "Geç", "Sinirlen"],
            },
            // Ailesel olaylar
            {
              "desc":
                  "Annen seni ekmek almaya gönderdi, eve gelirken köpek kovaladı, ekmek düştü.",
              "opts": ["Tekrar al", "Ağla", "Küfür et"],
            },
            {
              "desc":
                  "Baban 'ne zaman iş bulacaksın' diye sordu, cevap veremedin.",
              "opts": ["Özür dile", "Kabul et", "Kızgın ol"],
            },
            {
              "desc": "Kardeşin iş buldu, aile onu kutluyor, sen yalnızsın.",
              "opts": ["Kutla", "Kıskan", "Üzül"],
            },
            // Çevresel olaylar
            {
              "desc":
                  "Marketten alışveriş yaparken cüzdanı evde unuttun, geri döndün.",
              "opts": ["Tekrar git", "Vazgeç", "Küfür et"],
            },
            {
              "desc":
                  "Otobüs geç kaldı, iş görüşmesi kaçtı, eve döndün yattın.",
              "opts": ["Kabul et", "Üzül", "Küfür et"],
            },
            {
              "desc":
                  "Internet kesildi, iş başvurusu yapamadın, komşudan şifre istedin, vermedi.",
              "opts": ["Kabul et", "Üzül", "Küfür et"],
            },
          ];
          final event = events[random.nextInt(events.length)];
          description = event["desc"] as String;
          options = event["opts"] as List<String>;
          break;
        case EventType.Monthly:
          final events = [
            {
              "desc": "Bu ay 10 iş görüşmesine gittin, hepsi reddetti.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc": "Arkadaşların iş buldu, evlendi, sen hala işsizsin.",
              "opts": ["Kutla", "Kıskan", "Üzül"],
            },
            {
              "desc": "Raporlar hazırladın, hepsi beğenilmedi, patron kızdı.",
              "opts": ["Kabul et", "Özür dile", "Küfür et"],
            },
            {
              "desc": "Müşteri görüşmeleri yaptın, hiç satış yapamadın.",
              "opts": ["Kabul et", "Özür dile", "Kızgın ol"],
            },
            {
              "desc": "Sunumlar hazırladın, hepsi kötü geçti, patron kızdı.",
              "opts": ["Kabul et", "Özür dile", "Küfür et"],
            },
            {
              "desc": "Excel kursuna gittin, formül yazmayı öğrenemedin.",
              "opts": ["Devam et", "Para israfı", "Şikayet et"],
            },
            {
              "desc": "Müşteri şikayetleri aldın, hiçbirini çözemedin.",
              "opts": ["Özür dile", "Kabul et", "Kızgın ol"],
            },
            {
              "desc": "Aylık bütçe bitti, annenden borç aldın.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc": "Raporlar hazırladın, hepsi kayboldu, patron kızdı.",
              "opts": ["Tekrar hazırla", "Özür dile", "Küfür et"],
            },
            {
              "desc": "Staj başvuruları yaptın, hepsi reddetti.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            // Ailesel olaylar
            {
              "desc":
                  "Bu ay memlekete gittiniz, baban sana günlerini zehir etti, akrabalar 'ne iş yapıyorsun' diye sordu.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu ay aile toplantısı vardı, herkes iş bulmuş, sen hala işsizsin, utandın.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            // Çevresel olaylar
            {
              "desc":
                  "Bu ay arkadaşların evlendi, düğüne gittin, harçlık verdin, cebinde para kalmadı.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu ay doğum günün geldi, kimse hatırlamadı, kendin pasta aldın, yalnız yedin.",
              "opts": ["Üzül", "Kabul et", "Kızgın ol"],
            },
          ];
          final event = events[random.nextInt(events.length)];
          description = event["desc"] as String;
          options = event["opts"] as List<String>;
          break;
        case EventType.Yearly:
          final events = [
            {
              "desc": "Bu yıl 100 iş görüşmesine gittin, hepsi reddetti.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc":
                  "Arkadaşların iş buldu, evlendi, araba aldı, sen hala işsizsin.",
              "opts": ["Kutla", "Kıskan", "Üzül"],
            },
            {
              "desc": "Raporlar hazırladın, hepsi beğenilmedi, patron kızdı.",
              "opts": ["Kabul et", "Özür dile", "Küfür et"],
            },
            {
              "desc": "Müşteri görüşmeleri yaptın, hiç satış yapamadın.",
              "opts": ["Kabul et", "Özür dile", "Kızgın ol"],
            },
            {
              "desc": "Sunumlar hazırladın, hepsi kötü geçti, patron kızdı.",
              "opts": ["Kabul et", "Özür dile", "Küfür et"],
            },
            {
              "desc":
                  "Excel kursuna gittin, formül yazmayı öğrenemedin, para boşa gitti.",
              "opts": ["Devam et", "Para israfı", "Şikayet et"],
            },
            {
              "desc": "Müşteri şikayetleri aldın, hiçbirini çözemedin.",
              "opts": ["Özür dile", "Kabul et", "Kızgın ol"],
            },
            {
              "desc":
                  "Yıllık bütçe bitti, aile baskısı arttı, 'ne zaman iş bulacaksın' diye sordular.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc": "Raporlar hazırladın, hepsi kayboldu, patron kızdı.",
              "opts": ["Tekrar hazırla", "Özür dile", "Küfür et"],
            },
            {
              "desc": "Staj başvuruları yaptın, hepsi reddetti.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            // Ailesel olaylar
            {
              "desc":
                  "Bu yıl aile baskısı arttı, 'ne zaman evleneceksin' diye sordular, sen hala işsizsin.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu yıl baban 'seni asker yapamadık, iş de bulamadın' diye sürekli kızdı.",
              "opts": ["Kabul et", "Özür dile", "Kızgın ol"],
            },
            // Çevresel olaylar
            {
              "desc":
                  "Bu yıl arkadaşların evlendi, düğüne gittin, harçlık verdin, borç birikti.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu yıl eski arkadaşlarınla buluştun, herkes iş bulmuş, evlenmiş, sen hala işsizsin.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
          ];
          final event = events[random.nextInt(events.length)];
          description = event["desc"] as String;
          options = event["opts"] as List<String>;
          break;
      }
    } else if (departmentName.contains("Tıp")) {
      switch (type) {
        case EventType.Daily:
          final events = [
            {
              "desc":
                  "En yakın arkadaşın hastanede iş buldu, sen hala işsizsin.",
              "opts": ["Onu tebrik et", "Onunla kutla", "Kıskançlık yap"],
            },
            {
              "desc": "Hasta muayene ettin, teşhis koyamadın, hasta kızdı.",
              "opts": ["Özür dile", "Kabul et", "Küfür et"],
            },
            {
              "desc": "Hastaneye gittin, staj yeri istedin, 'yer yok' dediler.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc": "Nöbet tutman gerekiyordu, 24 saat uyumadın.",
              "opts": ["Kabul et", "Şikayet et", "Küfür et"],
            },
            {
              "desc": "Hasta dosyası kayboldu, aradın bulamadın.",
              "opts": ["Tekrar hazırla", "Panik yap", "Küfür et"],
            },
            {
              "desc":
                  "Hasta aradı, 'tedavi işe yaramadı' dedi, sen hatırlamıyordun.",
              "opts": ["Özür dile", "Kabul et", "Küfür et"],
            },
            {
              "desc": "Staj başvurusu yaptın, 'tecrübe yetersiz' dediler.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc": "Anatomi kitabı okudun, hiçbir şey anlamadın.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc": "Hasta muayene ettin, yanlış teşhis koydun, hasta kızdı.",
              "opts": ["Özür dile", "Kabul et", "Küfür et"],
            },
            {
              "desc": "Hastaneye gittin, iş istedin, 'yer yok' dediler.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            // Ailesel olaylar
            {
              "desc":
                  "Annen seni ekmek almaya gönderdi, eve gelirken köpek kovaladı, ekmek düştü.",
              "opts": ["Tekrar al", "Ağla", "Küfür et"],
            },
            {
              "desc":
                  "Baban 'ne zaman iş bulacaksın' diye sordu, cevap veremedin.",
              "opts": ["Özür dile", "Kabul et", "Kızgın ol"],
            },
            {
              "desc": "Kardeşin iş buldu, aile onu kutluyor, sen yalnızsın.",
              "opts": ["Kutla", "Kıskan", "Üzül"],
            },
            // Çevresel olaylar
            {
              "desc":
                  "Marketten alışveriş yaparken cüzdanı evde unuttun, geri döndün.",
              "opts": ["Tekrar git", "Vazgeç", "Küfür et"],
            },
            {
              "desc":
                  "Otobüs geç kaldı, iş görüşmesi kaçtı, eve döndün yattın.",
              "opts": ["Kabul et", "Üzül", "Küfür et"],
            },
            {
              "desc":
                  "Internet kesildi, iş başvurusu yapamadın, komşudan şifre istedin, vermedi.",
              "opts": ["Kabul et", "Üzül", "Küfür et"],
            },
          ];
          final event = events[random.nextInt(events.length)];
          description = event["desc"] as String;
          options = event["opts"] as List<String>;
          break;
        case EventType.Monthly:
          final events = [
            {
              "desc": "Bu ay 10 staj başvurusu yaptın, hepsi reddetti.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc": "Arkadaşların hastanede iş buldu, sen hala işsizsin.",
              "opts": ["Kutla", "Kıskan", "Üzül"],
            },
            {
              "desc":
                  "Hasta muayene ettin, hepsinde teşhis koyamadın, hasta kızdı.",
              "opts": ["Özür dile", "Kabul et", "Küfür et"],
            },
            {
              "desc":
                  "Nöbet tuttu, 24 saat uyumadın, hasta geldi, tedavi edemedin.",
              "opts": ["Kabul et", "Şikayet et", "Küfür et"],
            },
            {
              "desc":
                  "Hasta dosyaları hazırladın, hepsi kayboldu, hasta kızdı.",
              "opts": ["Tekrar hazırla", "Özür dile", "Küfür et"],
            },
            {
              "desc": "Staj yaptın, hiçbir şey öğrenmedin, sadece çay içtin.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc": "Hastaneye gittin, iş istedin, 'yer yok' dediler.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc": "Aylık bütçe bitti, annenden borç aldın.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc": "Anatomi kitabı okudun, hiçbir şey anlamadın.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc": "Hasta muayene ettin, yanlış teşhis koydun, hasta kızdı.",
              "opts": ["Özür dile", "Kabul et", "Küfür et"],
            },
            // Ailesel olaylar
            {
              "desc":
                  "Bu ay memlekete gittiniz, baban sana günlerini zehir etti, akrabalar 'ne iş yapıyorsun' diye sordu.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu ay aile toplantısı vardı, herkes iş bulmuş, sen hala işsizsin, utandın.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            // Çevresel olaylar
            {
              "desc":
                  "Bu ay arkadaşların evlendi, düğüne gittin, harçlık verdin, cebinde para kalmadı.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu ay doğum günün geldi, kimse hatırlamadı, kendin pasta aldın, yalnız yedin.",
              "opts": ["Üzül", "Kabul et", "Kızgın ol"],
            },
          ];
          final event = events[random.nextInt(events.length)];
          description = event["desc"] as String;
          options = event["opts"] as List<String>;
          break;
        case EventType.Yearly:
          final events = [
            {
              "desc": "Bu yıl 100 staj başvurusu yaptın, hepsi reddetti.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc":
                  "Arkadaşların hastanede iş buldu, evlendi, sen hala işsizsin.",
              "opts": ["Kutla", "Kıskan", "Üzül"],
            },
            {
              "desc":
                  "Hasta muayene ettin, hepsinde teşhis koyamadın, hasta kızdı.",
              "opts": ["Özür dile", "Kabul et", "Küfür et"],
            },
            {
              "desc":
                  "Nöbet tuttu, 24 saat uyumadın, hasta geldi, tedavi edemedin.",
              "opts": ["Kabul et", "Şikayet et", "Küfür et"],
            },
            {
              "desc":
                  "Hasta dosyaları hazırladın, hepsi kayboldu, hasta kızdı.",
              "opts": ["Tekrar hazırla", "Özür dile", "Küfür et"],
            },
            {
              "desc": "Staj yaptın, hiçbir şey öğrenmedin, sadece çay içtin.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc": "Hastaneye gittin, iş istedin, 'yer yok' dediler.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc":
                  "Yıllık bütçe bitti, aile baskısı arttı, 'ne zaman iş bulacaksın' diye sordular.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc": "Anatomi kitabı okudun, hiçbir şey anlamadın.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc": "Hasta muayene ettin, yanlış teşhis koydun, hasta kızdı.",
              "opts": ["Özür dile", "Kabul et", "Küfür et"],
            },
            // Ailesel olaylar
            {
              "desc":
                  "Bu yıl aile baskısı arttı, 'ne zaman evleneceksin' diye sordular, sen hala işsizsin.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu yıl baban 'seni asker yapamadık, iş de bulamadın' diye sürekli kızdı.",
              "opts": ["Kabul et", "Özür dile", "Kızgın ol"],
            },
            // Çevresel olaylar
            {
              "desc":
                  "Bu yıl arkadaşların evlendi, düğüne gittin, harçlık verdin, borç birikti.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu yıl eski arkadaşlarınla buluştun, herkes iş bulmuş, evlenmiş, sen hala işsizsin.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
          ];
          final event = events[random.nextInt(events.length)];
          description = event["desc"] as String;
          options = event["opts"] as List<String>;
          break;
      }
    } else {
      // Varsayılan
      switch (type) {
        case EventType.Daily:
          final events = [
            {
              "desc": "En yakın arkadaşın iş buldu, sen hala işsizsin.",
              "opts": ["Onu tebrik et", "Onunla kutla", "Kıskançlık yap"],
            },
            {
              "desc": "İş görüşmesi vardı, 'tecrübe yetersiz' dediler.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc": "İş ilanlarına baktın, hepsi 3+ yıl tecrübe istiyor.",
              "opts": ["Yine de başvur", "Geç", "Sinirlen"],
            },
            {
              "desc": "Staj başvurusu yaptın, 'tecrübe yetersiz' dediler.",
              "opts": ["Devam et", "Vazgeç", "Kızgın ol"],
            },
            {
              "desc": "Aylık bütçe bitti, annenden borç aldın.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            // Ailesel olaylar
            {
              "desc":
                  "Annen seni ekmek almaya gönderdi, eve gelirken köpek kovaladı, ekmek düştü.",
              "opts": ["Tekrar al", "Ağla", "Küfür et"],
            },
            {
              "desc":
                  "Baban 'ne zaman iş bulacaksın' diye sordu, cevap veremedin.",
              "opts": ["Özür dile", "Kabul et", "Kızgın ol"],
            },
            {
              "desc": "Kardeşin iş buldu, aile onu kutluyor, sen yalnızsın.",
              "opts": ["Kutla", "Kıskan", "Üzül"],
            },
            // Çevresel olaylar
            {
              "desc":
                  "Marketten alışveriş yaparken cüzdanı evde unuttun, geri döndün.",
              "opts": ["Tekrar git", "Vazgeç", "Küfür et"],
            },
            {
              "desc":
                  "Otobüs geç kaldı, iş görüşmesi kaçtı, eve döndün yattın.",
              "opts": ["Kabul et", "Üzül", "Küfür et"],
            },
            {
              "desc":
                  "Internet kesildi, iş başvurusu yapamadın, komşudan şifre istedin, vermedi.",
              "opts": ["Kabul et", "Üzül", "Küfür et"],
            },
          ];
          final event = events[random.nextInt(events.length)];
          description = event["desc"] as String;
          options = event["opts"] as List<String>;
          break;
        case EventType.Monthly:
          final events = [
            {
              "desc": "Bu ay 10 iş görüşmesine gittin, hepsi reddetti.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc": "Arkadaşların iş buldu, evlendi, sen hala işsizsin.",
              "opts": ["Kutla", "Kıskan", "Üzül"],
            },
            {
              "desc": "Aylık bütçe bitti, annenden borç aldın.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            // Ailesel olaylar
            {
              "desc":
                  "Bu ay memlekete gittiniz, baban sana günlerini zehir etti, akrabalar 'ne iş yapıyorsun' diye sordu.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu ay aile toplantısı vardı, herkes iş bulmuş, sen hala işsizsin, utandın.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            // Çevresel olaylar
            {
              "desc":
                  "Bu ay arkadaşların evlendi, düğüne gittin, harçlık verdin, cebinde para kalmadı.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu ay doğum günün geldi, kimse hatırlamadı, kendin pasta aldın, yalnız yedin.",
              "opts": ["Üzül", "Kabul et", "Kızgın ol"],
            },
          ];
          final event = events[random.nextInt(events.length)];
          description = event["desc"] as String;
          options = event["opts"] as List<String>;
          break;
        case EventType.Yearly:
          final events = [
            {
              "desc": "Bu yıl 100 iş görüşmesine gittin, hepsi reddetti.",
              "opts": ["Devam et", "Vazgeç", "Sinirlen"],
            },
            {
              "desc":
                  "Arkadaşların iş buldu, evlendi, araba aldı, sen hala işsizsin.",
              "opts": ["Kutla", "Kıskan", "Üzül"],
            },
            {
              "desc":
                  "Yıllık bütçe bitti, aile baskısı arttı, 'ne zaman iş bulacaksın' diye sordular.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            // Ailesel olaylar
            {
              "desc":
                  "Bu yıl aile baskısı arttı, 'ne zaman evleneceksin' diye sordular, sen hala işsizsin.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu yıl baban 'seni asker yapamadık, iş de bulamadın' diye sürekli kızdı.",
              "opts": ["Kabul et", "Özür dile", "Kızgın ol"],
            },
            // Çevresel olaylar
            {
              "desc":
                  "Bu yıl arkadaşların evlendi, düğüne gittin, harçlık verdin, borç birikti.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
            {
              "desc":
                  "Bu yıl eski arkadaşlarınla buluştun, herkes iş bulmuş, evlenmiş, sen hala işsizsin.",
              "opts": ["Kabul et", "Utandın", "Kızgın ol"],
            },
          ];
          final event = events[random.nextInt(events.length)];
          description = event["desc"] as String;
          options = event["opts"] as List<String>;
          break;
      }
    }

    _changeMentalHealth(-1, reason: description);

    return Event(
      date: _currentDate,
      description: description,
      options: options,
      type: type,
    );
  }

  // İş yerindeki eventler (iş bulunduysa)
  Event _generateWorkEvent(
    EventType type,
    String departmentName,
    Random random,
  ) {
    final jsonEvent = _getRandomEventFromJson(isWorking: true, type: type);
    if (jsonEvent != null) {
      return _buildEventFromMap(jsonEvent, type);
    }

    String description = "";
    List<String> options = [];

    // Günlük olaylar için iş yerindeki olaylar
    if (type == EventType.Daily) {
      final workEvents = [
        {
          "desc": "Sabah işe geç kaldın, patron kızdı.",
          "opts": ["Özür dile", "Mazeret uydur", "Kabul et"],
        },
        {
          "desc":
              "Toplantıda patronun fikri değişti, tüm projeyi baştan yaptın.",
          "opts": ["Kabul et", "İtiraz et", "Küfür et"],
        },
        {
          "desc": "Müşteri aradı, şikayet etti, sen çözemedin.",
          "opts": ["Özür dile", "Yöneticiye sor", "Kabul et"],
        },
        {
          "desc": "Öğle yemeğinde patron masana geldi, iş konuştu.",
          "opts": ["Dinle", "Kaç", "Kabul et"],
        },
        {
          "desc": "Akşam mesai saatinde çıkmak istedin, patron izin vermedi.",
          "opts": ["Kabul et", "İtiraz et", "Küfür et"],
        },
        {
          "desc": "Haftalık rapor hazırladın, patron beğenmedi, tekrar yaptın.",
          "opts": ["Kabul et", "Özür dile", "Küfür et"],
        },
        {
          "desc": "Yeni bir proje verildi, deadline çok kısa.",
          "opts": ["Kabul et", "İtiraz et", "Şikayet et"],
        },
        {
          "desc": "Maaş gecikti, patron 'biraz bekleyin' dedi.",
          "opts": ["Kabul et", "İtiraz et", "Kızgın ol"],
        },
        {
          "desc": "İş arkadaşın izin aldı, senin işini de yapman gerekiyor.",
          "opts": ["Kabul et", "İtiraz et", "Kızgın ol"],
        },
        {
          "desc": "Patron seni yanına çağırdı, 'performansın düşük' dedi.",
          "opts": ["Özür dile", "İtiraz et", "Kabul et"],
        },
      ];
      final event = workEvents[random.nextInt(workEvents.length)];
      description = event["desc"] as String;
      options = event["opts"] as List<String>;
    } else if (type == EventType.Monthly) {
      final workEvents = [
        {
          "desc": "Bu ay fazla mesai yaptın, ekstra para vermediler.",
          "opts": ["Kabul et", "İtiraz et", "Kızgın ol"],
        },
        {
          "desc":
              "Bu ay patron senden memnun kaldı, zam yok ama teşekkür etti.",
          "opts": ["Sevin", "Kabul et", "Kızgın ol"],
        },
        {
          "desc": "Bu ay iş arkadaşlarınla anlaşamadın, ortam gergin.",
          "opts": ["Kabul et", "İtiraz et", "Kızgın ol"],
        },
        {
          "desc": "Bu ay projeleri yetiştiremedin, patron kızdı.",
          "opts": ["Özür dile", "Kabul et", "Küfür et"],
        },
        {
          "desc": "Bu ay maaş gecikti, borç birikti.",
          "opts": ["Kabul et", "İtiraz et", "Kızgın ol"],
        },
        {
          "desc": "Bu ay yeni bir proje başladı, çok zor.",
          "opts": ["Kabul et", "İtiraz et", "Şikayet et"],
        },
        {
          "desc": "Bu ay patron senden memnun kaldı, övgü aldın.",
          "opts": ["Sevin", "Kabul et", "Umursama"],
        },
        {
          "desc": "Bu ay iş arkadaşın işten ayrıldı, iş yükün arttı.",
          "opts": ["Kabul et", "İtiraz et", "Kızgın ol"],
        },
        {
          "desc": "Bu ay toplantılarda sürekli eleştirildin.",
          "opts": ["Kabul et", "İtiraz et", "Kızgın ol"],
        },
        {
          "desc": "Bu ay iş yerinde yangın çıktı, tüm dosyalar gitti.",
          "opts": ["Panik yap", "Kabul et", "Küfür et"],
        },
      ];
      final event = workEvents[random.nextInt(workEvents.length)];
      description = event["desc"] as String;
      options = event["opts"] as List<String>;
    } else if (type == EventType.Yearly) {
      final workEvents = [
        {
          "desc": "Bu yıl işte çok çalıştın, zam alamadın.",
          "opts": ["Kabul et", "İtiraz et", "Kızgın ol"],
        },
        {
          "desc": "Bu yıl patron senden memnun kaldı, küçük bir zam aldın.",
          "opts": ["Sevin", "Kabul et", "Yetersiz bul"],
        },
        {
          "desc": "Bu yıl iş arkadaşların terfi aldı, sen alamadın.",
          "opts": ["Kabul et", "Kıskan", "Kızgın ol"],
        },
        {
          "desc": "Bu yıl projeleri yetiştiremedin, performans düşük görüldü.",
          "opts": ["Kabul et", "İtiraz et", "Küfür et"],
        },
        {
          "desc": "Bu yıl iş yerinde çok stres yaşadın, sağlığın bozuldu.",
          "opts": ["Kabul et", "İtiraz et", "Kızgın ol"],
        },
        {
          "desc": "Bu yıl yeni bir departmana geçtin, uyum sağlayamadın.",
          "opts": ["Kabul et", "İtiraz et", "Kızgın ol"],
        },
        {
          "desc": "Bu yıl patron senden memnun kaldı, terfi aldın.",
          "opts": ["Sevin", "Kabul et", "Umursama"],
        },
        {
          "desc": "Bu yıl iş yerinde çok çalıştın, sosyal hayatın bitti.",
          "opts": ["Kabul et", "İtiraz et", "Kızgın ol"],
        },
        {
          "desc": "Bu yıl maaş gecikmeleri arttı, borç birikti.",
          "opts": ["Kabul et", "İtiraz et", "Kızgın ol"],
        },
        {
          "desc":
              "Bu yıl iş yerinde yangın çıktı, tüm dosyalar gitti, sıfırdan başladın.",
          "opts": ["Panik yap", "Kabul et", "Küfür et"],
        },
      ];
      final event = workEvents[random.nextInt(workEvents.length)];
      description = event["desc"] as String;
      options = event["opts"] as List<String>;
    }

    return Event(
      date: _currentDate,
      description: description,
      options: options,
      type: type,
    );
  }

  // Sonraki Gün
  Event nextDay() {
    _currentDate = _currentDate.add(const Duration(days: 1));
    _lastMessage = "Yeni bir gün başladı: ${formattedDate}";
    logger.i("Gün ilerletildi: ${formattedDate}");

    // Bayram Kontrolü (Yaklaşık tarihler)
    // Yılda 2 kez, arası 2 ay.
    // 1. Bayram: Nisan 10-12 (Ramazan Bayramı simülasyonu)
    // 2. Bayram: Haziran 15-18 (Kurban Bayramı simülasyonu)
    bool isHoliday = false;

    if (_currentDate.month == 4 && _currentDate.day == 10) {
      // Ramazan Bayramı
      isHoliday = true;
      if (_random.nextBool()) {
        _pendingFinancialEvent = FinancialEvent(
          title: "Ramazan Bayramı",
          description: "Deden bayram harçlığı verdi! (+500 TL)",
          amount: 500,
          isChoice: false,
        );
      } else {
        _pendingFinancialEvent = FinancialEvent(
          title: "Ramazan Bayramı",
          description: "Bayramda el öptün ama harçlık veren olmadı.",
          amount: 0,
          isChoice: false,
        );
      }
    } else if (_currentDate.month == 6 && _currentDate.day == 15) {
      // Kurban Bayramı
      isHoliday = true;
      if (_random.nextBool()) {
        _pendingFinancialEvent = FinancialEvent(
          title: "Kurban Bayramı",
          description: "Kurban bayramında harçlık topladın! (+500 TL)",
          amount: 500,
          isChoice: false,
        );
      } else {
        _pendingFinancialEvent = FinancialEvent(
          title: "Kurban Bayramı",
          description: "Bu bayram harçlık çıkmadı, sadece et yedin.",
          amount: 0,
          isChoice: false,
        );
      }
    } else {
      // Bayram değilse rastgele finansal olay (daha düşük ihtimalle)
      // Sadece aile evindeyse ve bayram değilse
      if (_livingWithFamily && !isHoliday && _random.nextDouble() < 0.15) {
        // İhtimali %15'e düşürdüm (nadiren)

        final randomValue = _random.nextDouble();
        if (randomValue < 0.3) {
          // %30 ihtimalle Ekmek/Market (Zorunlu -15)
          _pendingFinancialEvent = FinancialEvent(
            title: "Ev İhtiyacı",
            description: "Evde ekmek bitmiş, sen aldın. (-15 TL)",
            amount: -15,
            isChoice: false,
          );
        } else if (randomValue < 0.6) {
          // %30 ihtimalle Kardeş (Seçimli -50)
          _pendingFinancialEvent = FinancialEvent(
            title: "Kardeşin Para İstedi",
            description:
                "Kardeşin dışarı çıkacak, senden borç istiyor. (-50 TL)",
            amount: -50,
            isChoice: true,
            choiceYesText: "Ver",
            choiceNoText: "Verme",
          );
        } else {
          // %40 ihtimalle Arkadaş Daveti (Seçimli -100)
          _pendingFinancialEvent = FinancialEvent(
            title: "Arkadaş Daveti",
            description: "Arkadaşların dışarı çağırıyor. (-100 TL)",
            amount: -100,
            isChoice: true,
            choiceYesText: "Git",
            choiceNoText: "Evde Kal",
          );
        }
      } else {
        _pendingFinancialEvent = null;
      }
    }

    // Event üret
    final event = _generateEvent(EventType.Daily);

    // Event'in description'ını hikaye olarak kaydet
    _stories.add(
      Story(
        date: _currentDate,
        content: event.description,
        type: StoryType.Daily,
      ),
    );

    // Başvuruları kontrol et
    _processApplications();

    notifyListeners();
    return event;
  }

  // Sonraki Ay
  Event nextMonth() {
    // Ay sonuna git, sonra bir ay ekle
    final nextMonth = _currentDate.month + 1;
    final nextYear = _currentDate.year;
    _currentDate = DateTime(nextYear, nextMonth, 1);
    _lastMessage = "Yeni bir ay başladı: ${formattedDate}";
    logger.i("Ay ilerletildi: ${formattedDate}");

    // Event üret
    final event = _generateEvent(EventType.Monthly);

    // Event'in description'ını hikaye olarak kaydet
    _stories.add(
      Story(
        date: _currentDate,
        content: event.description,
        type: StoryType.Monthly,
      ),
    );

    // Maaş Ödemesi
    if (_player != null) {
      // Kabul edilmiş işleri bul
      final acceptedJobs = _applications
          .where((app) => app.status == ApplicationStatus.Accepted)
          .toList();

      if (acceptedJobs.isNotEmpty) {
        // Birden fazla iş olmamalı ama yine de toplayalım
        double totalSalary = 0;
        for (var jobApp in acceptedJobs) {
          totalSalary += jobApp.job.salary;
        }

        _player!.money += totalSalary;
        _lastMessage = "Maaş yattı! +${totalSalary.toStringAsFixed(0)} TL";
        logger.i("Aylık maaş ödendi: $totalSalary");

        // Maaş bilgisini hikayeye ekle (isteğe bağlı)
        // _stories.add(Story(date: _currentDate, content: "Maaş günü: +$totalSalary TL", type: StoryType.Monthly));
      }
    }

    notifyListeners();
    return event;
  }

  // Sonraki Yıl
  Event nextYear() {
    // Yıl sonuna git, sonra bir yıl ekle
    final nextYear = _currentDate.year + 1;
    _currentDate = DateTime(nextYear, 1, 1);
    _lastMessage = "Yeni bir yıl başladı: ${formattedDate}";
    logger.i("Yıl ilerletildi: ${formattedDate}");

    // Event üret
    final event = _generateEvent(EventType.Yearly);

    // Event'in description'ını hikaye olarak kaydet
    _stories.add(
      Story(
        date: _currentDate,
        content: event.description,
        type: StoryType.Yearly,
      ),
    );

    notifyListeners();
    return event;
  }

  // Cinsiyet Seçimi (Setup aşamasında yardımcı olabilir, ama startGame'de hallettik)
  // Yine de UI'da dinamik değişim istenirse diye ayrı tutulabilir ama şu an startGame yeterli.

  // Askerlik Yapma
  void doMilitaryService(bool isPaid) {
    if (_player == null) return;

    if (isPaid) {
      // Bedelli
      if (_player!.money >= 50000) {
        _player!.money -= 50000;
        _player!.militaryStatus = MilitaryStatus.Done;
        _lastMessage = "Bedelli askerlik yapıldı. 50.000 TL ödendi.";
        logger.i("Bedelli askerlik yapıldı. Kalan para: ${_player!.money}");

        // Görev ekle
        _completedTasks.add(
          CVTask(
            title: "Askerlik Hizmeti (Bedelli)",
            description: "Bedelli askerlik hizmeti tamamlandı",
            completedDate: DateTime.now(),
          ),
        );
      } else {
        _lastMessage = "Yetersiz bakiye! Bedelli için 50.000 TL lazım.";
        logger.w("Bedelli için para yetersiz.");
      }
    } else {
      // 6 Ay (Mini oyun placeholder)
      // Burada normalde zaman geçmeli veya mini oyun oynanmalı.
      // Şimdilik direkt yapıldı sayıyoruz.
      _player!.militaryStatus = MilitaryStatus.Done;
      _lastMessage = "6 ay askerlik yapıldı. Vatan borcu ödendi.";
      logger.i("6 ay askerlik tamamlandı.");

      // Görev ekle
      _completedTasks.add(
        CVTask(
          title: "Askerlik Hizmeti",
          description: "6 ay askerlik hizmeti tamamlandı",
          completedDate: DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  // Mülakat Soruları
  List<Map<String, dynamic>> getInterviewQuestions() {
    if (_department == null) return [];

    // JSON verisinden soruları çek
    if (_gameData.isNotEmpty && _gameData['interview_questions'] != null) {
      final questionsData = _gameData['interview_questions'];
      final deptName = _department!.name;

      // Bölüme özel sorular varsa döndür
      if (questionsData[deptName] != null) {
        List<Map<String, dynamic>> questions = [];
        for (var q in questionsData[deptName]) {
          var questionMap = Map<String, dynamic>.from(q);
          // JSON'da correct_index kullanılıyor, kodda 'correct' veya 'correct_index'
          // Kodun geri kalanı ile uyum için 'correct' keyini de ekleyelim
          if (questionMap.containsKey('correct_index')) {
            questionMap['correct'] = questionMap['correct_index'];
          }
          questions.add(questionMap);
        }
        return questions;
      }
    }

    // Fallback (Varsayılan)
    return [
      {
        "question": "Neden bizimle çalışmak istiyorsunuz?",
        "options": [
          "Para lazım.",
          "Şirketinizin vizyonu ile hedeflerim uyuşuyor.",
          "Başka iş bulamadım.",
        ],
        "correct": 1,
      },
      {
        "question": "Zor bir durumla nasıl başa çıkarsınız?",
        "options": [
          "Hemen pes ederim.",
          "Sakin kalır ve çözüm üretmeye çalışırım.",
          "Başkalarını suçlarım.",
        ],
        "correct": 1,
      },
    ];
  }

  // Mülakatı Başlat (Simülasyon)
  void startInterview(JobApplication application) {
    // Mülakat durumunu güncellemeye gerek yok, UI'da soru ekranına gidecek.
    // Ancak mülakatın başladığını loglayabiliriz.
    logger.i("Mülakat başladı: ${application.job.title}");
  }

  // Mülakatı Tamamla
  void completeInterview(JobApplication application, int correctAnswers) {
    // Başarı şansı: Doğru cevap sayısı arttıkça şans artar
    // 3 soru varsa, 3 doğru %80 şans, 2 doğru %50, 1 doğru %20, 0 doğru %0
    // Basit bir mantık kuralım.

    application.updateStatus(ApplicationStatus.InterviewCompleted);
    _lastMessage = "Mülakat tamamlandı. Sonuç bekleniyor...";
    notifyListeners();
  }

  // İş Başvurusu
  void applyToJob(Job job) {
    if (_player == null) return;

    // Erkek ve Askerlik Yapılmadıysa ve İş Kurumsal ise
    if (_player!.gender == Gender.Male &&
        _player!.militaryStatus == MilitaryStatus.NotDone &&
        job.type == JobType.Corporate) {
      _lastMessage =
          "Kurumsal firmalar askerlik yapmamış erkek adayları reddediyor.";
      logger.w("Başvuru reddedildi: Askerlik yapılmamış.");
      notifyListeners();
      return;
    }

    // Başvuruyu listeye ekle
    _applications.add(
      JobApplication(
        job: job,
        status: ApplicationStatus.Applied, // Başlangıç statüsü: Bekliyor
        appliedDate: _currentDate,
        lastUpdateDate: _currentDate,
        message: "Başvuru alındı, değerlendiriliyor.",
      ),
    );

    _lastMessage = "Başvurunuz alındı. Yanıt bekleniyor.";

    // Başvuru yapıldı görevi ekle
    _completedTasks.add(
      CVTask(
        title: "İş Başvurusu: ${job.title}",
        description: "Başvuru yapıldı",
        completedDate: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  // Başvuru Aşaması Red Nedenleri
  List<String> get _applicationRejectionReasons {
    if (_gameData.isEmpty || _gameData['rejection_reasons'] == null) {
      return [
        "Başvuru reddedildi: 'Tecrübeniz yetersiz, ama stajyer olarak alabiliriz (maaş yok)'.",
        "Başvuru reddedildi: 'CV'niz çok güzel ama bizim aradığımız süper kahraman siz değilsiniz'.",
      ];
    }

    List<String> reasons = [];
    final reasonsData = _gameData['rejection_reasons']['application'];

    // Genel nedenler
    if (reasonsData['general'] != null) {
      reasons.addAll(List<String>.from(reasonsData['general']));
    }

    // Bölüme özel nedenler
    if (_department != null &&
        reasonsData['departments'] != null &&
        reasonsData['departments'][_department!.name] != null) {
      reasons.addAll(
        List<String>.from(reasonsData['departments'][_department!.name]),
      );
    }

    if (reasons.isEmpty) return ["Başvurunuz reddedildi."];
    return reasons;
  }

  // Mülakat Sonrası Red Nedenleri
  List<String> get _interviewRejectionReasons {
    if (_gameData.isEmpty || _gameData['rejection_reasons'] == null) {
      return [
        "Mülakat sonucu olumsuz: 'Teknik bilginiz iyi ama kültürümüze uymazsınız (çok soru soruyorsunuz)'.",
        "Mülakat sonucu olumsuz: 'Patron sizi sevmedi, elektrik alamamış'.",
      ];
    }

    List<String> reasons = [];
    final reasonsData = _gameData['rejection_reasons']['interview'];

    // Genel nedenler
    if (reasonsData['general'] != null) {
      reasons.addAll(List<String>.from(reasonsData['general']));
    }

    // Bölüme özel nedenler
    if (_department != null &&
        reasonsData['departments'] != null &&
        reasonsData['departments'][_department!.name] != null) {
      reasons.addAll(
        List<String>.from(reasonsData['departments'][_department!.name]),
      );
    }

    if (reasons.isEmpty) return ["Mülakat sonucu olumsuz."];
    return reasons;
  }

  // Başvuruları Kontrol Et (Günlük Çalışır)
  void _processApplications() {
    final random = Random();
    List<String> notifications = [];

    for (var app in _applications) {
      // Son güncellemeden geçen gün sayısı
      final daysPassed = _currentDate.difference(app.lastUpdateDate).inDays;

      if (app.status == ApplicationStatus.Applied) {
        // Bekleyen başvurular
        if (daysPassed > 2) {
          // En az 2 gün geçmeli
          // %20 ihtimalle bir gelişme olur
          if (random.nextDouble() < 0.2) {
            // Ghosting Şansı (İş türüne göre)
            if (random.nextDouble() < app.job.ghostingChance) {
              app.updateStatus(ApplicationStatus.Ghosted);
              _changeMentalHealth(-1, reason: "${app.job.title} ghostladı");
              // Ghosting sessiz olur, bildirim gitmez genelde ama oyunda anlaşılması için:
              // notifications.add("${app.job.title}: Ses seda yok...");
            } else {
              // Mülakat veya Red
              // %40 Mülakat, %60 Red
              if (random.nextDouble() < 0.4) {
                app.updateStatus(ApplicationStatus.Interview);
                notifications.add("MÜLAKAT DAVETİ: ${app.job.title}");
              } else {
                app.updateStatus(ApplicationStatus.Rejected);
                _changeMentalHealth(-1, reason: "${app.job.title} reddi");
                // Başvuru aşaması red nedeni
                final reason =
                    _applicationRejectionReasons[random.nextInt(
                      _applicationRejectionReasons.length,
                    )];
                notifications.add("${app.job.title}: $reason");
              }
            }
          }
        }
      } else if (app.status == ApplicationStatus.InterviewCompleted) {
        // Mülakat yapıldı, sonuç bekleniyor
        // Bekleme süresi random (3-10 gün arası olsun mesela)
        // Basitlik için her gün %15 şansla dönüş olsun
        if (random.nextDouble() < 0.15) {
          // Kabul veya Red
          // %30 Kabul, %70 Red (Zor olsun biraz)
          if (random.nextDouble() < 0.3) {
            app.updateStatus(ApplicationStatus.Accepted);
            notifications.add("TEBRİKLER! İŞ TEKLİFİ: ${app.job.title}");
            _player!.money += app.job.salary; // İlk maaş bonusu gibi veya avans
            _changeMentalHealth(5, reason: "${app.job.title} kabul edildi");
            // İş bulma başarısı logla veya başka şeyler yap
          } else {
            app.updateStatus(ApplicationStatus.Rejected);
            _changeMentalHealth(-1, reason: "${app.job.title} mülakat reddi");
            // Mülakat sonrası red nedeni
            final reason =
                _interviewRejectionReasons[random.nextInt(
                  _interviewRejectionReasons.length,
                )];
            notifications.add("${app.job.title}: $reason");
          }
        }
      }
    }

    // Bildirimleri son mesaja ekle (Eğer varsa)
    if (notifications.isNotEmpty) {
      _lastMessage = notifications.join("\n");
    }
  }

  void _generateJobs() {
    _availableJobs = [
      Job(
        title: "Junior Flutter Geliştirici",
        salary: 15000,
        ghostingChance: 0.4,
        type: JobType.Startup,
      ),
      Job(
        title: "Kurumsal Java Geliştirici",
        salary: 25000,
        ghostingChance: 0.6,
        type: JobType.Corporate,
      ),
      Job(
        title: "Devlet Memuru (Bilişim)",
        salary: 30000,
        ghostingChance: 0.1,
        type: JobType.Government,
      ),
      Job(
        title: "Stajyer",
        salary: 5000,
        ghostingChance: 0.8,
        type: JobType.Startup,
      ),
    ];
  }

  // Yetenek Ekleme
  void addSkill(String skill, double cost) {
    if (_player == null) return;
    if (_player!.money < cost) {
      _lastMessage =
          "Yetersiz bakiye! $skill için ${cost.toStringAsFixed(0)} TL gerekiyor.";
      logger.w("Yetersiz bakiye: $skill");
      notifyListeners();
      return;
    }
    if (_player!.skills.contains(skill)) {
      _lastMessage = "Bu yeteneği zaten biliyorsunuz!";
      notifyListeners();
      return;
    }

    _player!.money -= cost;
    _player!.skills.add(skill);
    _lastMessage = "$skill yeteneği eklendi!";
    logger.i("Yetenek eklendi: $skill, Kalan para: ${_player!.money}");
    notifyListeners();
  }

  // Mini Oyun Tamamlandı
  void completeMinigame(MiniGame game, bool success) {
    if (!success) {
      _lastMessage = "${game.name} başarısız oldu. Tekrar dene!";
      notifyListeners();
      return;
    }

    if (_player == null) return;

    // Timing oyunu için özel durum: Askerlik
    if (game.type == GameType.Timing &&
        _player!.militaryStatus == MilitaryStatus.NotDone) {
      _player!.militaryStatus = MilitaryStatus.Done;
      _lastMessage = "Askerlik görevi başarıyla tamamlandı!";

      _completedTasks.add(
        CVTask(
          title: "Askerlik Hizmeti",
          description: "Askerlik hizmeti üstün başarıyla tamamlandı",
          completedDate: DateTime.now(),
        ),
      );
      notifyListeners();
      return;
    }

    // Bölüme göre oyunun kazandırdığı yetenekleri al
    final skillsForGame = DepartmentGameContent.getSkillsForGame(
      game.type,
      _department?.name,
    );

    // Henüz öğrenilmemiş yetenekleri ekle
    List<String> newSkills = [];
    for (var skill in skillsForGame) {
      if (!_player!.skills.contains(skill)) {
        _player!.skills.add(skill);
        newSkills.add(skill);
      }
    }

    if (newSkills.isNotEmpty) {
      _lastMessage =
          "${newSkills.join(", ")} ${newSkills.length == 1 ? "yetenek" : "yetenekler"} kazanıldı!";
      logger.i("Yetenekler eklendi: ${newSkills.join(", ")}");
    } else {
      // Tüm yetenekler zaten varsa para ödülü ver
      int reward = 500;
      switch (game.type) {
        case GameType.Reflex:
          reward = 500;
          break;
        case GameType.Timing:
          reward = 1000;
          break;
        case GameType.Memory:
          reward = 750;
          break;
        case GameType.Dilemma:
          reward = 600;
          break;
        case GameType.Grind:
          reward = 400;
          break;
      }
      _player!.money += reward;
      _lastMessage = "${game.name} tamamlandı! $reward TL ödül kazandınız.";
    }

    notifyListeners();
  }

  // CV Oluşturma
  CV generateCV() {
    if (_player == null || _department == null) {
      throw Exception("Oyun başlatılmamış!");
    }

    return CV(
      name: _player!.name,
      gender: _player!.gender,
      militaryStatus: _player!.militaryStatus,
      department: _department!.name,
      skills: List.from(_player!.skills),
      experiences: List.from(_experiences),
      completedTasks: List.from(_completedTasks),
      money: _player!.money,
    );
  }
}

class FinancialEvent {
  final String title;
  final String description;
  final double amount; // Pozitif: Gelir, Negatif: Gider
  final bool isChoice; // true: Seçim (Evet/Hayır), false: Zorunlu/Bilgi
  final String? choiceYesText;
  final String? choiceNoText;

  FinancialEvent({
    required this.title,
    required this.description,
    required this.amount,
    this.isChoice = false,
    this.choiceYesText,
    this.choiceNoText,
  });
}

enum OptionalExpenseResult { paid, declined, insufficientFunds, infoConfirmed }
