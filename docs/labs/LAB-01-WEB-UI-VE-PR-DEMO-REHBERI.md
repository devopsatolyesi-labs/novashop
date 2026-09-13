# LAB-01 — Web Arayüzü (GitHub UI) ve Terminal Canlı Demo Rehberi

Bu rehber, **LAB-01 (Git & GitHub Foundations)** laboratuvarını uygularken veya sınıfa anlatırken, **sol ekranda Terminal (CLI)**, **sağ ekranda GitHub Web Arayüzü** ile eşzamanlı bir canlı demo sunmanız için hazırlanmıştır.

Tüm komutlar, dosya değişiklikleri ve web arayüzünde tıklanacak butonlar kronolojik sırayla verilmiştir.

---

## 🖥️ Canlı Sahne Düzeni (Split Screen Tavsiyesi)

- **Sol Yarım Ekran:** Ubuntu Terminal (veya Cockpit Web Terminal)
- **Sağ Yarım Ekran:** Tarayıcıda GitHub Deponuz (`https://github.com/<GITHUB_USERNAME>/novashop`)

---

## 🎬 1. Aşama: Depoyu Başlatma ve İlk Push

### 1.1 Terminalde Çalıştırın:
```bash
cd ~/novashop
rm -rf .git
git init -b main
git config --local user.name "<STUDENT_NAME>"
git config --local user.email "<STUDENT_EMAIL>"

git add .
git commit -m "feat: initial novashop starter repository with branding"

# Kendi GitHub reponuzu bağlayın:
git remote add origin https://github.com/<GITHUB_USERNAME>/novashop.git
git push -u origin main
```

### 1.2 🌐 Web Arayüzünde Gösterin:
1. Tarayıcıda `https://github.com/<GITHUB_USERNAME>/novashop` sayfasını yenileyin (F5).
2. **Öğrenciye Vurgulayın:**
   - Dosyaların ve klasörlerin anında listelendiğini gösterin.
   - Sağ üstteki **"1 commit"** bağlantısına tıklayarak commit mesajını (`feat: initial...`) ve yazar kimliğini gösterin.
   - Dalın varsayılan olarak **`main`** geldiğini gösterin.

---

## 🎬 2. Aşama: Feature Branch ve Pull Request (PR) Açma

### 2.1 Terminalde Çalıştırın:
```bash
# 1. Yeni dal açın
git checkout -b feature/update-mug-product

# 2. Ürün fiyatını 45'ten 55'e çekin
sed -i 's/"price": 45/"price": 55/' src/ui/src/main/resources/data/products.json

# 3. Değişikliği doğrulayın ve commit edin
git diff src/ui/src/main/resources/data/products.json
git add src/ui/src/main/resources/data/products.json
git commit -m "feat(catalog): update kubernetes mug price to 55"

# 4. Feature branch'i GitHub'a push edin
git push -u origin feature/update-mug-product
```

### 2.2 🌐 Web Arayüzünde Gösterin:
1. GitHub reponuzun ana sayfasına dönün. Sayfayı yenileyin.
2. **Sarı Bildirim Çubuğu (Aha-Moment 1):**  
   GitHub en tepede otomatik olarak şu sarı kutuyu gösterecektir:  
   👉 **`feature/update-mug-product had recent pushes less than a minute ago`**  
   Yanındaki yeşil **`Compare & pull request`** butonuna tıklayın.
3. **Pull Request Oluşturma Ekranı:**
   - Başlık: `feat(catalog): update kubernetes mug price to 55`
   - Açıklama (Description) kısmına:  
     `Bu PR ile Kubernetes Cluster Mug fiyatı enflasyon güncellemesi gereği 55 olarak revize edilmiştir.`
   - Aşağı kaydırıp **Files changed (1)** sekmesini gösterin:
     - Kırmızı satır: `-"price": 45,`
     - Yeşil satır: `+"price": 55,`
   - **Öğrenciye Vurgulayın:** *"Code Review işte burada yapılır! Ekip arkadaşınız tek bir satır dahi değiştirse burada renkli diff olarak görürsünüz."*
4. Yeşil **`Create pull request`** butonuna tıklayın.
5. ⚠️ **DİKKAT:** Henüz `Merge pull request` butonuna **TIKLAMAYIN!** PR açık kalsın.

---

## 🎬 3. Aşama: Canlıda Merge Conflict Üretme (Büyük Çatışma)

Şimdi senaryo gereği bir ekip arkadaşınızın `main` dalında aynı ürünün fiyatını acil olarak `50` yaptığını simüle edeceğiz.

### 3.1 Terminalde Çalıştırın:
```bash
# 1. Ana dala dönün (burada fiyat hala 45'tir!)
git checkout main

# 2. Main dalında fiyatı 50 yapıp acil commit atın
sed -i 's/"price": 45/"price": 50/' src/ui/src/main/resources/data/products.json
git commit -am "fix(pricing): adjust kubernetes mug price to 50 on main"

# 3. Bu acil düzeltmeyi GitHub main dalına da gönderin!
git push origin main
```

### 3.2 🌐 Web Arayüzünde Gösterin (Aha-Moment 2 - Çatışmanın Patlaması!):
1. Tarayıcıda açık bıraktığınız **Pull Request** sekmesine geri dönün ve sayfayı yenileyin (**F5**).
2. **Ekrana Dikkat:**
   - Yeşil olan `Merge pull request` butonu anında kaybolur veya grileşir!
   - Kırmızı/Gri uyarı kutusu belirir:  
     ⚠️ **`This branch has conflicts that must be resolved`**  
     *(Conflicting files: `src/ui/src/main/resources/data/products.json`)*
3. **Öğrenciye Vurgulayın:**  
   *"Bakın arkadaşlar! GitHub sistemi korudu ve merge butonunu kilitledi. Çünkü arkada `main` dalı değişti ve iki dal aynı satırda çelişiyor!"*
4. İsterseniz GitHub arayüzündeki **`Resolve conflicts`** butonuna tıklayıp web arayüzündeki conflict editörünü gösterin:
   ```json
   <<<<<<< feature/update-mug-product
       "price": 55,
   =======
       "price": 50,
   >>>>>>> main
   ```
   *"Web arayüzünde de çözebiliriz ama profesyonel mühendisler bu işlemi daima kendi yerel terminallerinde çözer ve test eder!"* diyerek terminale geri dönün.

---

## 🎬 4. Aşama: Çakışmayı Terminalde Çözme ve PR'ın Otomatik Yeşile Dönmesi

### 4.1 Terminalde Çalıştırın:
```bash
# 1. Terminalde birleştirmeyi deneyin (conflict oluşsun)
git merge feature/update-mug-product

# 2. Conflict işaretçilerini inceleyin
git status
git diff src/ui/src/main/resources/data/products.json

# 3. Fiyatı 55 olarak belirleyip işaretçileri temizleyin (nano ile veya sed ile):
sed -i '/<<<<<<< HEAD/d' src/ui/src/main/resources/data/products.json
sed -i '/"price": 50,/d' src/ui/src/main/resources/data/products.json
sed -i '/=======/d' src/ui/src/main/resources/data/products.json
sed -i '/>>>>>>> feature\/update-mug-product/d' src/ui/src/main/resources/data/products.json

# 4. JSON geçerliliğini doğrulayın
jq . src/ui/src/main/resources/data/products.json > /dev/null && echo "✅ JSON GEÇERLİ"

# 5. Çözümü sahneye alın ve commit edin
git add src/ui/src/main/resources/data/products.json
git commit -m "merge: resolve pricing conflict on kubernetes mug (set to 55)"

# 6. Dal geçmişine bakın (Dalların birleştiğini gösterin!)
git log --graph --oneline --decorate -n 6

# 7. Çözülen main dalını GitHub'a gönderin
git push origin main
```

### 4.2 🌐 Web Arayüzünde Gösterin (Aha-Moment 3 - Mutlu Son!):
1. GitHub'daki PR sayfasına dönüp sayfayı yenileyin (**F5**).
2. **Sonuç:**
   - Kırmızı conflict uyarısı kendiliğinden yok olur!
   - Yerini neşeli yeşil bir kutu alır:  
     ✅ **`This branch has no conflicts with the base branch`**
   - Yeşil **`Merge pull request`** butonu yeniden aktif hale gelir!
3. Artık yeşil **`Merge pull request`** -> **`Confirm merge`** butonuna basarak PR'ı tamamlayabilir ve mor renkli **`Merged`** rozetini öğrencilere gösterebilirsiniz!

---

## 📋 Özet Hızlı Komut Tablosu

| Sıra | Ne Yapılıyor? | Terminal Komutu | Web Arayüzündeki Karşılığı |
|:---:|:---|:---|:---|
| **1** | Sıfır repo başlatma | `git init -b main` | Boş GitHub repo sayfası |
| **2** | İlk aktarım | `git push -u origin main` | Kodların ve commit'in ana sayfada belirmesi |
| **3** | Feature dalı açma | `git checkout -b feature/...` | Yeni dal |
| **4** | Değişiklik push etme | `git push -u origin feature/...` | **"Compare & pull request"** sarı bildirim butonu |
| **5** | PR oluşturma | — | Web'de **"Create pull request"** butonuna basma |
| **6** | Main'de rakip değişiklik | `git commit -am "..." && git push` | PR sayfasında **"Conflicts must be resolved"** uyarısı |
| **7** | Çakışmayı çözme | `git merge` + dosyayı düzeltme + `git commit` | Terminalde merge commit atılması |
| **8** | Çözümü gönderme | `git push origin main` | PR sayfasında uyarının kalkması ve yeşil **Merge** butonu |
