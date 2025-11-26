enum GameType {
  Reflex, // Hız ve Refleks (Coding, Excel vb.)
  Timing, // Sabır ve Zamanlama (Askerlik, Sabır vb.)
  Memory, // Hafıza ve Sıra Takibi
  Dilemma, // İkilem ve Karar Verme
  Grind, // Tıklama ve Tekrarlama (Endurance)
}

class MiniGame {
  final String name;
  final String description;
  final GameType type;
  final List<String> relatedSkills;
  final String instructions;

  MiniGame({
    required this.name,
    required this.description,
    required this.type,
    required this.relatedSkills,
    required this.instructions,
  });
}

final List<MiniGame> miniGames = [
  MiniGame(
    name: "Refleks Oyunu",
    description: "Hızla yanıp sönen hedeflere dokun!",
    type: GameType.Reflex,
    relatedSkills: ["Hızlı Kodlama", "Excel", "İngilizce"],
    instructions:
        "Ekranda 4 kare belirecek. Yanıp sönen kareye en hızlı şekilde dokunmalısın. Yanlış kareye dokunursan puan kaybedersin.",
  ),
  MiniGame(
    name: "Zamanlama Oyunu",
    description: "Göstergeyi tam zamanında durdur!",
    type: GameType.Timing,
    relatedSkills: ["Sabır", "Dayanıklılık", "Askerlik"],
    instructions:
        "Gösterge çubuğu ileri geri hareket edecek. Tam yeşil alana geldiğinde ekrana dokunarak durdurmalısın.",
  ),
  MiniGame(
    name: "Hafıza ve Sıra Oyunu",
    description: "İşlem sırasını hatırla ve tekrarla!",
    type: GameType.Memory,
    relatedSkills: ["Dokümantasyon", "Etik Karar Verme", "Müşteri İlişkileri"],
    instructions:
        "Butonlar belirli bir sırayla yanacak. Bu sırayı aklında tut ve tekrar et. Dikkat et, patron fikrini değiştirebilir!",
  ),
  MiniGame(
    name: "İkilem ve Karar Oyunu",
    description: "Zor durumlarda en doğru kararı ver!",
    type: GameType.Dilemma,
    relatedSkills: ["Kurumsal İletişim", "Müşteri İlişkileri", "Etik"],
    instructions:
        "Karşına bir senaryo çıkacak. Süre bitmeden en mantıklı seçeneği işaretle.",
  ),
  MiniGame(
    name: "Veri Girişi Oyunu",
    description: "Sisteme veri girmek için olabildiğince hızlı tıkla!",
    type: GameType.Grind,
    relatedSkills: ["Veri Girişi", "Bürokrasi", "Raporlama"],
    instructions: "Butona sürekli tıkla. Sistem hatası verirse bekle!",
  ),
];
