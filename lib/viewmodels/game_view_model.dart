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
import '../models/market_item.dart';
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
  final List<MarketItem> _marketItems = _generateMarketItems();
  final List<String> _ownedItemIds = [];

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
  List<MarketItem> get marketItems => _marketItems;
  List<MarketItem> get ownedItems => _ownedItemIds
      .map((id) => _marketItems.firstWhere((item) => item.id == id))
      .toList();

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
    _ownedItemIds.clear();
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
    return OptionalExpenseResult.declined;
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
        return OptionalExpenseResult.paid;
      } else {
        // Gider
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

  bool purchaseItem(MarketItem item) {
    if (_player == null) return false;
    if (_ownedItemIds.contains(item.id)) {
      _lastMessage = "${item.name} zaten satın alındı.";
      notifyListeners();
      return false;
    }
    if (_player!.money < item.price) {
      _lastMessage = "${item.name} için yeterli bakiyeniz yok.";
      notifyListeners();
      return false;
    }
    _player!.money -= item.price;
    _ownedItemIds.add(item.id);
    _lastMessage = "${item.name} satın alındı!";
    _applyItemBonus(item);
    notifyListeners();
    return true;
  }

  void applyPeriodicBonuses() {
    for (final itemId in _ownedItemIds) {
      final item = _marketItems.firstWhere((element) => element.id == itemId);
      if (item.mentalBonus <= 0) continue;
      if (item.bonusType == "daily") {
        _changeMentalHealth(item.mentalBonus, reason: "${item.name} (Günlük)");
      }
    }
  }

  void applyMonthlyBonuses() {
    for (final itemId in _ownedItemIds) {
      final item = _marketItems.firstWhere((element) => element.id == itemId);
      if (item.mentalBonus <= 0) continue;
      if (item.bonusType == "monthly") {
        _changeMentalHealth(item.mentalBonus, reason: "${item.name} (Aylık)");
      }
    }
  }

  void applyYearlyBonuses() {
    for (final itemId in _ownedItemIds) {
      final item = _marketItems.firstWhere((element) => element.id == itemId);
      if (item.mentalBonus <= 0) continue;
      if (item.bonusType == "yearly") {
        _changeMentalHealth(item.mentalBonus, reason: "${item.name} (Yıllık)");
      }
    }
  }

  void _applyItemBonus(MarketItem item) {
    if (item.mentalBonus <= 0) return;

    if (item.bonusType == "single") {
      _changeMentalHealth(item.mentalBonus, reason: item.name);
      return;
    }
    // periodic items handled by periodic bonus functions
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

    // Bölüme göre eventler (Kısaltılmış fallback logic)
    // JSON varsa buraya düşmez, o yüzden burayı sade bırakıyorum.
    // Sadece günlük fallback:
    final events = [
      {
        "desc": "Sıradan bir gün, iş aramaya devam.",
        "opts": ["Devam et"],
      },
    ];
    final event = events[random.nextInt(events.length)];
    description = event["desc"] as String;
    options = event["opts"] as List<String>;

    // Mental sağlık düşüşünü sadece JSON'dan gelenlere bıraktık veya burada manuel ekleyebiliriz.
    // _changeMentalHealth(-1, reason: description);

    return Event(
      date: _currentDate,
      description: description,
      options: options,
      type: type,
    );
  }

  static List<MarketItem> _generateMarketItems() {
    return [
      MarketItem(
        id: "phone_basic",
        name: "Akıllı Telefon",
        category: "Teknoloji",
        price: 20000,
        description:
            "Güncel iş ilanlarını takip etmek için modern bir telefon.",
        mentalBonus: 5,
        bonusType: "single",
      ),
      MarketItem(
        id: "laptop_pro",
        name: "Dizüstü Bilgisayar",
        category: "Teknoloji",
        price: 35000,
        description: "Code yazarken hız kazandıran yüksek performanslı laptop.",
        mentalBonus: 5,
        bonusType: "single",
      ),
      MarketItem(
        id: "tablet_note",
        name: "Tablet",
        category: "Teknoloji",
        price: 15000,
        description: "Not ve çizim tutmak için şık tablet.",
        mentalBonus: 5,
        bonusType: "single",
      ),
      MarketItem(
        id: "home_rent",
        name: "Küçük Ev",
        category: "Yaşam",
        price: 1200000,
        description: "Kendi alanına sahip olman için mütevazı bir ev.",
        mentalBonus: 2,
        bonusType: "daily",
      ),
      MarketItem(
        id: "car_basic",
        name: "Şehir İçi Araç",
        category: "Yaşam",
        price: 800000,
        description: "Mülakatlara yetişmek için ekonomik otomobil.",
        mentalBonus: 2,
        bonusType: "daily",
      ),
      MarketItem(
        id: "ment_support",
        name: "Profesyonel Mental Destek",
        category: "Sağlık",
        price: 5000,
        description: "Terapi paketi ile mental sağlığını koru.",
        mentalBonus: 30,
        bonusType: "single",
      ),
      MarketItem(
        id: "course_frontend",
        name: "Frontend Bootcamp",
        category: "Eğitim",
        price: 7000,
        description: "Yeni yetenekler kazanacağın yoğun eğitim.",
        mentalBonus: 5,
        bonusType: "single",
      ),
      MarketItem(
        id: "course_language",
        name: "İleri Seviye İngilizce",
        category: "Eğitim",
        price: 6000,
        description: "Uluslararası mülakatlara hazırlık.",
        mentalBonus: 5,
        bonusType: "single",
      ),
      MarketItem(
        id: "cowork",
        name: "Coworking Üyeliği",
        category: "Yaşam",
        price: 3000,
        description: "Motivasyon için paylaşımlı ofis ortamı.",
        mentalBonus: 5,
        bonusType: "single",
      ),
    ];
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

    // JSON yoksa fallback
    return Event(
      date: _currentDate,
      description: "İş yerinde sıradan bir gün.",
      options: ["Çalışmaya devam"],
      type: type,
    );
  }

  // Sonraki Gün
  Event nextDay() {
    final previousDate = _currentDate;
    _currentDate = _currentDate.add(const Duration(days: 1));
    logger.i("Gün ilerletildi: ${formattedDate}");

    // Bayram Kontrolü (Yaklaşık tarihler)
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
        final randomValue = _random.nextDouble();
        if (randomValue < 0.3) {
          _pendingFinancialEvent = FinancialEvent(
            title: "Ev İhtiyacı",
            description: "Evde ekmek bitmiş, sen aldın. (-15 TL)",
            amount: -15,
            isChoice: false,
          );
        } else if (randomValue < 0.6) {
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

    Event event;
    // Yıl değişimi kontrolü
    if (_currentDate.year != previousDate.year) {
      _lastMessage = "Yeni bir yıl başladı: ${formattedDate}";
      event = _generateEvent(EventType.Yearly);
      applyYearlyBonuses();
    }
    // Ay değişimi kontrolü
    else if (_currentDate.month != previousDate.month) {
      _lastMessage = "Yeni bir ay başladı: ${formattedDate}";
      event = _generateEvent(EventType.Monthly);
      applyMonthlyBonuses();

      // Maaş Ödemesi (Ay başında)
      if (_player != null) {
        final acceptedJobs = _applications
            .where((app) => app.status == ApplicationStatus.Accepted)
            .toList();

        if (acceptedJobs.isNotEmpty) {
          double totalSalary = 0;
          for (var jobApp in acceptedJobs) {
            totalSalary += jobApp.job.salary;
          }
          _player!.money += totalSalary;
          _lastMessage = "Maaş yattı! +${totalSalary.toStringAsFixed(0)} TL";
          logger.i("Aylık maaş ödendi: $totalSalary");
        }
      }
    } else {
      // Günlük olay
      _lastMessage = "Yeni bir gün başladı: ${formattedDate}";
      event = _generateEvent(EventType.Daily);
      applyPeriodicBonuses();
    }

    // Event'in description'ını hikaye olarak kaydet
    _stories.add(
      Story(
        date: _currentDate,
        content: event.description,
        type: event.type == EventType.Daily
            ? StoryType.Daily
            : event.type == EventType.Monthly
            ? StoryType.Monthly
            : StoryType.Yearly,
      ),
    );

    // Başvuruları kontrol et
    _processApplications();

    notifyListeners();
    return event;
  }

  // Sonraki Ay (Silindi - artık nextDay içinde otomatik)
  // Sonraki Yıl (Silindi - artık nextDay içinde otomatik)

  // Cinsiyet Seçimi
  // ... (Kalan metodlar aynı)

  void doMilitaryService(bool isPaid) {
    if (_player == null) return;

    if (isPaid) {
      // Bedelli
      if (_player!.money >= 50000) {
        _player!.money -= 50000;
        _player!.militaryStatus = MilitaryStatus.Done;
        _lastMessage = "Bedelli askerlik yapıldı. 50.000 TL ödendi.";
        logger.i("Bedelli askerlik yapıldı. Kalan para: ${_player!.money}");

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
      _player!.militaryStatus = MilitaryStatus.Done;
      _lastMessage = "6 ay askerlik yapıldı. Vatan borcu ödendi.";
      logger.i("6 ay askerlik tamamlandı.");

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

  List<Map<String, dynamic>> getInterviewQuestions() {
    if (_department == null) return [];

    if (_gameData.isNotEmpty && _gameData['interview_questions'] != null) {
      final questionsData = _gameData['interview_questions'];
      final deptName = _department!.name;

      if (questionsData[deptName] != null) {
        List<Map<String, dynamic>> questions = [];
        for (var q in questionsData[deptName]) {
          var questionMap = Map<String, dynamic>.from(q);
          if (questionMap.containsKey('correct_index')) {
            questionMap['correct'] = questionMap['correct_index'];
          }
          questions.add(questionMap);
        }
        return questions;
      }
    }

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

  void startInterview(JobApplication application) {
    logger.i("Mülakat başladı: ${application.job.title}");
  }

  void completeInterview(JobApplication application, int correctAnswers) {
    application.updateStatus(ApplicationStatus.InterviewCompleted);
    _lastMessage = "Mülakat tamamlandı. Sonuç bekleniyor...";
    notifyListeners();
  }

  void applyToJob(Job job) {
    if (_player == null) return;

    if (_player!.gender == Gender.Male &&
        _player!.militaryStatus == MilitaryStatus.NotDone &&
        job.type == JobType.Corporate) {
      _lastMessage =
          "Kurumsal firmalar askerlik yapmamış erkek adayları reddediyor.";
      logger.w("Başvuru reddedildi: Askerlik yapılmamış.");
      notifyListeners();
      return;
    }

    _applications.add(
      JobApplication(
        job: job,
        status: ApplicationStatus.Applied,
        appliedDate: _currentDate,
        lastUpdateDate: _currentDate,
        message: "Başvuru alındı, değerlendiriliyor.",
      ),
    );

    _lastMessage = "Başvurunuz alındı. Yanıt bekleniyor.";

    _completedTasks.add(
      CVTask(
        title: "İş Başvurusu: ${job.title}",
        description: "Başvuru yapıldı",
        completedDate: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  List<String> get _applicationRejectionReasons {
    if (_gameData.isEmpty || _gameData['rejection_reasons'] == null) {
      return [
        "Başvuru reddedildi: 'Tecrübeniz yetersiz, ama stajyer olarak alabiliriz (maaş yok)'.",
        "Başvuru reddedildi: 'CV'niz çok güzel ama bizim aradığımız süper kahraman siz değilsiniz'.",
      ];
    }

    List<String> reasons = [];
    final reasonsData = _gameData['rejection_reasons']['application'];

    if (reasonsData['general'] != null) {
      reasons.addAll(List<String>.from(reasonsData['general']));
    }

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

  List<String> get _interviewRejectionReasons {
    if (_gameData.isEmpty || _gameData['rejection_reasons'] == null) {
      return [
        "Mülakat sonucu olumsuz: 'Teknik bilginiz iyi ama kültürümüze uymazsınız (çok soru soruyorsunuz)'.",
        "Mülakat sonucu olumsuz: 'Patron sizi sevmedi, elektrik alamamış'.",
      ];
    }

    List<String> reasons = [];
    final reasonsData = _gameData['rejection_reasons']['interview'];

    if (reasonsData['general'] != null) {
      reasons.addAll(List<String>.from(reasonsData['general']));
    }

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

  void _processApplications() {
    final random = Random();
    List<String> notifications = [];

    for (var app in _applications) {
      final daysPassed = _currentDate.difference(app.lastUpdateDate).inDays;

      if (app.status == ApplicationStatus.Applied) {
        if (daysPassed > 2) {
          if (random.nextDouble() < 0.2) {
            if (random.nextDouble() < app.job.ghostingChance) {
              app.updateStatus(ApplicationStatus.Ghosted);
              _changeMentalHealth(-10, reason: "${app.job.title} ghostladı");
            } else {
              if (random.nextDouble() < 0.4) {
                app.updateStatus(ApplicationStatus.Interview);
                notifications.add("MÜLAKAT DAVETİ: ${app.job.title}");
              } else {
                app.updateStatus(ApplicationStatus.Rejected);
                _changeMentalHealth(-10, reason: "${app.job.title} reddi");
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
        if (random.nextDouble() < 0.15) {
          if (random.nextDouble() < 0.3) {
            app.updateStatus(ApplicationStatus.Accepted);
            notifications.add("TEBRİKLER! İŞ TEKLİFİ: ${app.job.title}");
            _player!.money += app.job.salary;
            _changeMentalHealth(5, reason: "${app.job.title} kabul edildi");
          } else {
            app.updateStatus(ApplicationStatus.Rejected);
            _changeMentalHealth(-10, reason: "${app.job.title} mülakat reddi");
            final reason =
                _interviewRejectionReasons[random.nextInt(
                  _interviewRejectionReasons.length,
                )];
            notifications.add("${app.job.title}: $reason");
          }
        }
      }
    }

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

  void completeMinigame(MiniGame game, bool success) {
    if (!success) {
      _lastMessage = "${game.name} başarısız oldu. Tekrar dene!";
      notifyListeners();
      return;
    }

    if (_player == null) return;

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

    final skillsForGame = DepartmentGameContent.getSkillsForGame(
      game.type,
      _department?.name,
    );

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
