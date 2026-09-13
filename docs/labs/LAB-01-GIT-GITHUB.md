# LAB-01 — Git Temelleri, GitHub ve Kontrollü Merge Conflict Çözümü

## Amaç

Ubuntu sunucu ortamında Git sürüm kontrol sistemini sıfırdan başlatmak, GitHub üzerinde kişisel bir uzak depo oluşturup projeyi push etmek, bir feature branch açıp Pull Request (PR) süreci işletmek ve `products.json` üzerinde kasıtlı oluşturulmuş bir merge conflict'i hem komut satırında hem de GitHub web arayüzünde gözlemleyip çözmek.

---

## Kazanımlar

1. Linux komut satırında `git init`, `.gitignore`, `git status`, `git add` (staging) ve anlamlı commit pratiklerini kazanmak.
2. GitHub üzerinde Personal Access Token (PAT) oluşturup terminalden uzak depoya ilk push işlemini gerçekleştirmek.
3. Feature branch yaşam döngüsünü (`git checkout -b`, değişiklik, commit, push, Pull Request) uygulamak.
4. İki farklı branch'te aynı satır değiştirildiğinde ortaya çıkan merge conflict yapısını (`<<<<<<<`, `=======`, `>>>>>>>`) hem terminalde hem de GitHub web arayüzünde incelemek ve çözmek.
5. `git log --graph --oneline` ile dal geçmişini terminalde görselleştirmek.

---

## 🛠️ Ön Koşullar

Laboratuvara başlamadan önce aşağıdaki hazırlıkları tamamlayın:

### 1. GitHub Hesabı ve Boş Depo (Repository) Oluşturma
1. [GitHub](https://github.com)'a giriş yapın.
2. Sağ üstteki **`+`** simgesine tıklayıp **New repository** seçin.
3. Repository name: **`novashop`** yazın.
4. Görünürlük: **Public** (veya isteğe bağlı Private) seçin.
5. ⚠️ **ÖNEMLİ:** *"Add a README file"*, *"Add .gitignore"* veya *"Choose a license"* seçeneklerinin **HİÇBİRİNİ İŞARETLEMEYİN**. Depo tamamen boş olmalıdır.
6. **Create repository** butonuna tıklayın.

### 2. GitHub Personal Access Token (PAT) Oluşturma
GitHub, terminalden parola ile push işlemlerini engellediği için bir erişim token'ı (PAT) oluşturmanız gerekir:
1. GitHub'da profil ikonunuza tıklayın -> **Settings** seçin.
2. Sol menünün en altındaki **Developer Settings** -> **Personal access tokens** -> **Tokens (classic)** seçeneğine tıklayın.
3. **Generate new token** -> **Generate new token (classic)** seçin.
4. **Note:** `novashop-lab` yazın.
5. **Expiration:** `30 days` seçin.
6. **Scopes:** En üstteki **`repo`** kutucuğunu işaretleyin (Tüm repository yönetim izinleri).
7. **Generate token** butonuna tıklayın.
8. Üretilen `ghp_xxxxxxxxxxxxxxxxxxxx` token'ını güvenli bir yere kopyalayın.

### 3. Ubuntu Sunucu Ortamı
- Ubuntu 22.04+ işletim sistemi (Cockpit web terminali veya SSH erişimi).
- Git kurulu olmalıdır (`git --version` >= 2.30).

---

## Kullanılan Placeholder'lar

| Placeholder | Anlamı | Örnek Değer |
|---|---|---|
| `<GITHUB_USERNAME>` | GitHub kullanıcı adınız | `johndoe` |
| `<STUDENT_NAME>` | Git commit yazar adı | `Ahmet Yilmaz` |
| `<STUDENT_EMAIL>` | Git commit yazar e-postası | `ahmet@example.com` |
| `<GITHUB_PAT_TOKEN>` | GitHub Personal Access Token | `ghp_1234567890abcdef...` |

---

## Adımlar

### Bölüm 1: Yerel Depoyu Başlatma ve İlk Commit

Bu bölümde, NovaShop kod tabanını sunucuda temiz bir Git geçmişiyle başlatıp kendi GitHub deponuza göndereceksiniz.

#### 1.1 Proje Dizinine Geçin ve Git Deposu Başlatın
```bash
cd ~/novashop
rm -rf .git
git init -b main
```
> **Not:** Mevcut `.git` dizinini silerek orijinal projenin geçmişini temizler ve deponun ilk mimarı olarak `main` dalıyla sıfırdan başlarsınız.

*Beklenen Çıktı:*
```text
Initialized empty Git repository in /home/.../novashop/.git/
```

#### 1.2 Depoya Özel (Local) Git Kimlik Bilgilerini Tanımlayın
```bash
git config --local user.name "<STUDENT_NAME>"
git config --local user.email "<STUDENT_EMAIL>"
```

*Doğrulama:*
```bash
git config --local --get user.name
git config --local --get user.email
```

#### 1.3 .gitignore Dosyasını İnceleyin
```bash
head -n 20 .gitignore
```

#### 1.4 Dosyaları Stage Alanına Alın ve İlk Commit'i Atın
```bash
git add .
git commit -m "feat: initial novashop starter repository with branding"
```

*Beklenen Çıktı:*
```text
[main (root-commit) 8a1b2c3] feat: initial novashop starter repository with branding
 ... files changed, ... insertions(+)
```

#### 1.5 GitHub Uzak Deposunu Ekleyin ve Push Edin
```bash
git remote add origin https://github.com/<GITHUB_USERNAME>/novashop.git
git push -u origin main
```
> **Kimlik Doğrulama:**  
> - **Username:** `<GITHUB_USERNAME>`  
> - **Password:** Oluşturduğunuz `<GITHUB_PAT_TOKEN>` değerini girin.

**Web Arayüzü Kontrolü:**  
Tarayıcınızda `https://github.com/<GITHUB_USERNAME>/novashop` sayfasını açın. Dosyaların, `main` branch'inin ve commit geçmişinin listelendiğini doğrulayın.

---

### Bölüm 2: Feature Branch Açma ve Pull Request Süreci

Bu bölümde, ana dalı (`main`) izole tutarak yeni bir feature branch açacak, bir ürün fiyatını güncelleyecek ve GitHub üzerinde Pull Request (PR) oluşturacaksınız.

#### 2.1 Yeni Feature Branch Oluşturun
```bash
git checkout -b feature/update-mug-product
```

*Beklenen Çıktı:*
```text
Switched to a new branch 'feature/update-mug-product'
```

#### 2.2 Ürün Fiyatını Güncelleyin
`src/ui/src/main/resources/data/products.json` dosyasındaki ilk ürünün (`Kubernetes Cluster Mug`) fiyatını `45` yerine `55` yapın:
```bash
sed -i 's/"price": 45/"price": 55/' src/ui/src/main/resources/data/products.json
```

#### 2.3 Değişikliği İnceleyin, Commit Edin ve Push Edin
```bash
git diff src/ui/src/main/resources/data/products.json
git add src/ui/src/main/resources/data/products.json
git commit -m "feat(catalog): update kubernetes mug price to 55"
git push -u origin feature/update-mug-product
```

#### 2.4 GitHub Üzerinde Pull Request (PR) Açın
1. GitHub'da `https://github.com/<GITHUB_USERNAME>/novashop` sayfasına gidin.
2. Sayfanın üstünde sarı kutuda **`Compare & pull request`** butonunu göreceksiniz. Butona tıklayın.
3. PR başlığı: `feat(catalog): update kubernetes mug price to 55`
4. **Files changed** sekmesine tıklayıp satır farkını (`-45` -> `+55`) inceleyin.
5. Yeşil **`Create pull request`** butonuna tıklayın.
6. ⚠️ **DİKKAT:** PR'ı henüz merge etmeyin! Bir sonraki bölümde bu PR üzerinden çakışma senaryosu simüle edilecektir.

---

### Bölüm 3: Kontrollü Merge Conflict Simülasyonu ve Çözümü

#### Senaryo:
Siz `feature/update-mug-product` dalında fiyatı `55` yapıp PR açmışken, bir ekip arkadaşınız `main` dalında aynı ürünün fiyatını acil olarak `50` olarak değiştirip `main` dalına push etmiştir.

#### 3.1 `main` Dalına Geri Dönün ve Rakip Değişikliği Push Edin
```bash
git checkout main
sed -i 's/"price": 45/"price": 50/' src/ui/src/main/resources/data/products.json
git commit -am "fix(pricing): adjust kubernetes mug price to 50 on main"
git push origin main
```

#### 3.2 GitHub PR Ekranını İnceleyin
1. GitHub'da açık bıraktığınız Pull Request sayfasına dönün ve sayfayı yenileyin (**F5**).
2. GitHub'ın otomatik olarak çakışmayı tespit ettiğini göreceksiniz:  
   ⚠️ **`This branch has conflicts that must be resolved`**
3. `Merge pull request` butonu devre dışı kalmıştır.

#### 3.3 Çakışmayı Terminalde Tetikleyin
```bash
git merge feature/update-mug-product
```

*Beklenen Çıktı:*
```text
Auto-merging src/ui/src/main/resources/data/products.json
CONFLICT (content): Merge conflict in src/ui/src/main/resources/data/products.json
Automatic merge failed; fix conflicts and then commit the result.
```

#### 3.4 Çakışmayı İnceleyin
```bash
git status
git diff src/ui/src/main/resources/data/products.json
```
Dosyada conflict bloklarını göreceksiniz:
```json
<<<<<<< HEAD
    "price": 50,
=======
    "price": 55,
>>>>>>> feature/update-mug-product
```
- `<<<<<<< HEAD`: Mevcut daldaki (`main`) değer (`50`).
- `=======`: Ayrım çizgisi.
- `>>>>>>> feature/...`: Gelen daldaki değer (`55`).

#### 3.5 Çakışmayı Çözün
Ekip kararı gereği geçerli fiyatın **`55`** olduğunu kabul ediyoruz. Dosyayı düzenleyerek işaretçileri kaldırın ve sadece doğru satırı bırakın:

```bash
# nano ile açıp elle düzenleyebilirsiniz:
nano src/ui/src/main/resources/data/products.json
```
*Veya komut satırından doğrudan temizleyin:*
```bash
sed -i '/<<<<<<< HEAD/d' src/ui/src/main/resources/data/products.json
sed -i '/"price": 50,/d' src/ui/src/main/resources/data/products.json
sed -i '/=======/d' src/ui/src/main/resources/data/products.json
sed -i '/>>>>>>> feature\/update-mug-product/d' src/ui/src/main/resources/data/products.json
```

**JSON Geçerliliğini Doğrulayın:**
```bash
jq . src/ui/src/main/resources/data/products.json > /dev/null && echo "✅ JSON GEÇERLİ"
```

#### 3.6 Merge Commit'ini Tamamlayın ve Push Edin
```bash
git add src/ui/src/main/resources/data/products.json
git commit -m "merge: resolve pricing conflict on kubernetes mug (set to 55)"
git push origin main
```

#### 3.7 Git Geçmişini Doğrulayın
```bash
git log --graph --oneline --decorate -n 6
```

#### 3.8 GitHub PR Ekranını Yenileyin
GitHub'daki PR sayfasını yenileyin (**F5**).  
Çakışma uyarısının kalktığını, PR durumunun yeşile döndüğünü ve artık **`Merge pull request`** butonunun kullanılabilir olduğunu gözlemleyin.

---

### Bölüm 4: Otomatik Doğrulama Betiğini Çalıştırma

Laboratuvar adımlarını başarıyla tamamladığınızı doğrulamak için doğrulama betiğini çalıştırın:

```bash
bash scripts/verify/verify-lab-01.sh
```

*Beklenen Çıktı:*
```text
=== [LAB-01] Doğrulama Başlatılıyor ===
✅ Git deposu mevcut.
✅ Local Git yapılandırması: <STUDENT_NAME> <<STUDENT_EMAIL>>
✅ Toplam commit sayısı: 4
✅ Çalışma ağacı temiz (clean working tree).
=== [LAB-01] Doğrulama Başarıyla Tamamlandı! ===
```

---

## 🧹 Temizlik (Cleanup)

Yereldeki geçici feature branch'i silin:
```bash
git branch -d feature/update-mug-product
```
