class Department {
  final String name;
  final double difficulty; // 0.0 - 1.0, etkileyebilir belki
  
  Department({required this.name, required this.difficulty});
}

final List<Department> departments = [
  Department(name: "Bilgisayar/Yazılım Mühendisliği", difficulty: 0.8),
  Department(name: "Hukuk Fakültesi", difficulty: 0.7),
  Department(name: "İşletme / İktisat", difficulty: 0.5),
  Department(name: "Tıp Fakültesi", difficulty: 0.9),
];

