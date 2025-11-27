import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/game_view_model.dart';

class PersonalLifeView extends ConsumerWidget {
  const PersonalLifeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameVM = ref.watch(gameProvider);
    final isLivingWithFamily = gameVM.livingWithFamily;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kişisel Hayat"),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Durum Kartı
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      isLivingWithFamily ? Icons.home : Icons.apartment,
                      size: 64,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isLivingWithFamily ? "Aile Evi" : "Kiralık Ev",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLivingWithFamily
                          ? "Şu an ailenle yaşıyorsun. Kira derdin yok, sıcak çorba garanti."
                          : "Kendi evinde özgürsün ama ay sonunda faturalar kapını çalar.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Giderler Kartı
            if (!isLivingWithFamily)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt_long, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            "Aylık Giderler",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildExpenseRow("Kira", gameVM.rentCost),
                      _buildExpenseRow("Faturalar", gameVM.billsCost),
                      _buildExpenseRow("Mutfak & Market", gameVM.groceryCost),
                      const Divider(height: 24),
                      _buildExpenseRow(
                        "Toplam",
                        gameVM.totalMonthlyExpenses,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Aksiyon Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (isLivingWithFamily) {
                    _showMoveOutDialog(context, ref);
                  } else {
                    gameVM.returnToFamily();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLivingWithFamily ? Colors.red.shade700 : Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  isLivingWithFamily ? "Ayrı Eve Çık" : "Aile Evine Dön",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            if (isLivingWithFamily)
               Padding(
                 padding: const EdgeInsets.only(top: 12),
                 child: Row(
                   children: [
                     Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                     const SizedBox(width: 6),
                     Expanded(
                       child: Text(
                         "Ayrı eve çıkmak için en az 30.000 TL nakit gerekir. (Depozito + İlk Kira)",
                         style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                       ),
                     ),
                   ],
                 ),
               ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 15,
              color: isTotal ? Colors.black : Colors.black87,
            ),
          ),
          Text(
            "-${amount.toStringAsFixed(0)} TL",
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 15,
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showMoveOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Ayrı Eve Çık", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          "Kendi evine çıkmak üzeresin. Bu büyük bir sorumluluk!\n\n"
          "• Başlangıç Ödemesi: 30.000 TL (Hemen düşer)\n"
          "• Aylık Sabit Gider: 23.500 TL (Her ay düşer)\n\n"
          "Devam etmek istiyor musun?",
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Vazgeç", style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(gameProvider).moveToRental();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Onayla"),
          ),
        ],
      ),
    );
  }
}

