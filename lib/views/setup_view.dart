import 'dart:math';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/enums.dart';
import '../models/department_model.dart';
import '../viewmodels/game_view_model.dart';
import 'dashboard_view.dart';

class SetupView extends ConsumerStatefulWidget {
  const SetupView({super.key});

  @override
  ConsumerState<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends ConsumerState<SetupView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();

  Gender _selectedGender = Gender.Female;
  Department? _selectedDepartment;

  // Doğum Tarihi
  int _selectedDay = 1;
  int _selectedMonth = 1;

  final List<String> _months = [
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

  final List<int> _days = List.generate(31, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    if (departments.isNotEmpty) {
      _selectedDepartment = departments.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  void _randomize() {
    final random = Random();

    final maleNames = [
      "Ali",
      "Mehmet",
      "Can",
      "Burak",
      "Emre",
      "Murat",
      "Ahmet",
      "Mustafa",
    ];
    final femaleNames = [
      "Ayşe",
      "Fatma",
      "Zeynep",
      "Elif",
      "Sema",
      "Gamze",
      "Buse",
      "Merve",
    ];
    final surnames = [
      "Yılmaz",
      "Kaya",
      "Demir",
      "Çelik",
      "Şahin",
      "Yıldız",
      "Öztürk",
      "Aydın",
      "Şimşek",
    ];

    final isMale = random.nextBool();
    setState(() {
      _selectedGender = isMale ? Gender.Male : Gender.Female;
      _nameController.text = isMale
          ? maleNames[random.nextInt(maleNames.length)]
          : femaleNames[random.nextInt(femaleNames.length)];
      _surnameController.text = surnames[random.nextInt(surnames.length)];

      _selectedDay = random.nextInt(28) + 1;
      _selectedMonth = random.nextInt(12) + 1;

      if (departments.isNotEmpty) {
        _selectedDepartment = departments[random.nextInt(departments.length)];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade700, // Görseldeki gibi kırmızı arka plan
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: FadeInDown(
            duration: const Duration(milliseconds: 800),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rastgele Oluştur Butonu (Başlık gibi)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _randomize,
                    icon: const Icon(Icons.casino, color: Colors.white),
                    label: const Text(
                      "Rastgele Oluştur",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Form Alanı
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Ad:"),
                    _buildTextField(_nameController, "Sema"),
                    const SizedBox(height: 16),

                    _buildLabel("Soyad:"),
                    _buildTextField(_surnameController, "Şimşek"),
                    const SizedBox(height: 16),

                    _buildLabel("Cinsiyet:"),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGenderButton("Kadın", Gender.Female),
                        ),
                        Expanded(
                          child: _buildGenderButton("Erkek", Gender.Male),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("Doğum Tarihi:"),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown<int>(
                            value: _selectedMonth,
                            items: List.generate(12, (index) => index + 1),
                            displayLabel: (val) => "Ay: ${_months[val - 1]}",
                            onChanged: (val) =>
                                setState(() => _selectedMonth = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown<int>(
                            value: _selectedDay,
                            items: _days,
                            displayLabel: (val) => "Gün: $val",
                            onChanged: (val) =>
                                setState(() => _selectedDay = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("Mezun Olduğun Bölüm:"),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9C4), // Sarımtırak/Krem renk
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.transparent),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Department>(
                          value: _selectedDepartment,
                          isExpanded: true,
                          dropdownColor: const Color(0xFFFFF9C4),
                          items: departments.map((d) {
                            return DropdownMenuItem(
                              value: d,
                              child: Text(
                                d.name,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedDepartment = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Başla Butonu
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = _nameController.text.trim();
                          final surname = _surnameController.text.trim();

                          if (name.isEmpty || surname.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Lütfen ad ve soyad girin"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (_selectedDepartment != null) {
                            ref
                                .read(gameProvider)
                                .startGame(
                                  "$name $surname",
                                  _selectedGender,
                                  _selectedDepartment!,
                                );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DashboardView(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF9C4),
                          foregroundColor: Colors.red.shade800,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          "Başla",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderButton(String label, Gender gender) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF9C4) : Colors.red.shade800,
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white,
          ),
          // Sol/Sağ köşe yuvarlatma mantığı (ilk veya son eleman)
          borderRadius:
              gender ==
                  Gender
                      .Female // Görselde Kadın solda, Erkek sağda varsayımı
              ? const BorderRadius.horizontal(left: Radius.circular(8))
              : const BorderRadius.horizontal(right: Radius.circular(8)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              const Icon(Icons.check, size: 18, color: Colors.red),
            if (isSelected) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.red.shade800 : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) displayLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFFFFF9C4),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                displayLabel(item),
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
