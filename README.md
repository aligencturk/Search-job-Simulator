# İş Arama Simülatörü - TR 🇹🇷

Türkiye'de iş arama sürecinin zorluklarını, absürtlüklerini ve trajikomik yanlarını ele alan mizahi bir simülasyon oyunu.

## 🎮 Oyun Hakkında

Bu simülatörde, yeni mezun bir gencin iş bulma mücadelesine tanık olacaksınız. Amacınız, hem akıl sağlığınızı korumak hem de cebinizdeki son kuruş bitmeden bir işe girmek!

### 🌟 Özellikler

*   **4 Farklı Kariyer Yolu:**
    *   💻 **Bilgisayar Mühendisliği:** GitHub starlarınız, yeni çıkan frameworkler ve "Junior ama 10 yıl tecrübeli" ilanlarıyla boğuşun.
    *   ⚖️ **Hukuk:** Staj yeri ararken baronun havuzuna düşme tehlikesi ve müvekkil kaprisleri.
    *   mbA **İşletme:** Networking yalanları, beyaz yaka dertleri ve "CEO olacağım" hayalleri.
    *   ⚕️ **Tıp:** TUS belası, nöbetler ve akrabaların bitmek bilmeyen sağlık soruları.

*   **Gerçekçi (ve Acımasız) Oynanış:**
    *   **CV Hazırlama:** Yeteneklerinizi abartın, ama mülakatta yakalanmamaya çalışın.
    *   **İş Başvuruları:** "Biz size döneriz" cevabını duymaya hazır olun.
    *   **Mülakatlar:** Teknik sorulara ve İK'nın garip sorularına ("Bir meyve olsanız ne olurdunuz?") cevap verin.

*   **Hayatta Kalma Mekanikleri:**
    *   🧠 **Akıl Sağlığı (Mental):** Reddedildikçe düşer, arkadaşlarınız iş buldukça dibe vurur.
    *   💰 **Para:** Yol parası, kıyafet masrafı derken cüzdanınızdaki delik büyür.

*   **Rastgele Olaylar:**
    *   Günlük ve aylık sürprizler.
    *   İnternet kesintileri, otobüs kaçırmalar, düğün dernek masrafları.

## 🛠️ Teknolojiler ve Paketler

Bu proje **Flutter** ile geliştirilmiştir ve aşağıdaki paketleri kullanır:

*   **State Management:** `flutter_riverpod` - Uygulama durumu yönetimi için.
*   **UI/UX:**
    *   `animate_do` - Animasyonlar için.
    *   `percent_indicator` - İlerleme çubukları (Mental/Para durumu) için.
    *   `google_fonts` - Özel fontlar için.
    *   `cupertino_icons` - iOS tarzı ikonlar için.
*   **Veri ve Yardımcılar:**
    *   `shared_preferences` - Yerel veri saklama.
    *   `intl` - Tarih ve saat formatlama.
    *   `logger` - Gelişmiş loglama.
    *   `google_generative_ai` - (Opsiyonel) Yapay zeka entegrasyonu.
*   **Diğer:** `audioplayers`, `vibration`.

## 🚀 Kurulum ve Başlangıç

Bu projeyi yerel ortamınızda çalıştırmak için aşağıdaki adımları izleyin:

1.  **Projeyi Klonlayın:**
    ```bash
    git clone https://github.com/kullaniciadi/jobSearchSimulator.git
    cd jobSearchSimulator
    ```

2.  **Bağımlılıkları Yükleyin:**
    ```bash
    flutter pub get
    ```

3.  **Uygulamayı Başlatın:**
    ```bash
    flutter run
    ```

## 🤝 Katkıda Bulunma

Pull request'ler kabul edilir. Büyük değişiklikler için önce tartışmak üzere bir issue açınız.

---
*Not: Bu oyun tamamen hayal ürünüdür, ancak yaşanan acılar gerçektir.* 🥲
