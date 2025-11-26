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
  Gender _selectedGender = Gender.Male;
  Department? _selectedDepartment;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: FadeInDown(
            duration: const Duration(milliseconds: 800),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Karakter Oluştur",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                    const SizedBox(height: 24),
                    // İsim Girişi
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "İsim",
                        hintText: "Adınızı girin",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Cinsiyet Seçimi
                    DropdownButtonFormField<Gender>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: "Cinsiyet",
                        border: OutlineInputBorder(),
                      ),
                      items: Gender.values.map((g) {
                        return DropdownMenuItem(
                          value: g,
                          child: Text(g == Gender.Male ? "Erkek" : "Kadın"),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedGender = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Bölüm Seçimi
                    DropdownButtonFormField<Department>(
                      value: _selectedDepartment,
                      decoration: const InputDecoration(
                        labelText: "Bölüm",
                        border: OutlineInputBorder(),
                      ),
                      items: departments.map((d) {
                        return DropdownMenuItem(value: d, child: Text(d.name));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedDepartment = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = _nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Lütfen isminizi girin"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (_selectedDepartment != null) {
                            ref
                                .read(gameProvider)
                                .startGame(
                                  name,
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Simülasyona Başla"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
