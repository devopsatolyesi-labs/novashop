# 01 — Git Senkronizasyon ve Çakışma (Conflict) Yönetimi

Bu doküman; yerel geliştirme ortamı, öğrenci deposu (GitHub) ve eğitmen deposu (GitLab) arasındaki çoklu repo senkronizasyonunda yaşanan çakışmaları, kök nedenlerini ve otomatik kodla çözüm adımlarını açıklar.

---

## 1. Karşılaşılan Sorunlar ve Hata Belirtileri

### Senaryo A: Doğrudan Web UI Üzerinden Yapılan Değişiklik Sonrası Push Reddi
- **Hata Çıktısı:**
  ```text
  To https://github.com/devopsatolyesi-labs/novashop.git
   ! [rejected]        main -> main (fetch first)
  error: failed to push some refs to 'https://github.com/devopsatolyesi-labs/novashop.git'
  hint: Updates were rejected because the remote contains work that you do not have locally.
  ```
- **Kök Neden:** Kullanıcı GitHub arayüzünden `labs/LAB-01/README.md` dosyasını düzenleyip commit atmış, ancak yerel ortam bu commit'i çekmeden (`fetch`) yeni değişiklikleri push etmeye çalışmıştır.

### Senaryo B: Otomatik Birleştirme Çakışması (Merge Conflict)
- **Hata Çıktısı:**
  ```text
  Auto-merging labs/LAB-01/README.md
  CONFLICT (content): Merge conflict in labs/LAB-01/README.md
  Automatic merge failed; fix conflicts and then commit the result.
  ```
- **Kök Neden:** Uzak repodaki commit ile yerel repodaki commit aynı satırları farklı şekilde değiştirmiştir.

---

## 2. Adım Adım Kodla Çözüm

### 1. Uzak Değişiklikleri Rebase ile Alma
Merge commit kirliliği oluşturmamak ve temiz bir commit ağacı korumak için `rebase` tercih edilir:
```bash
# 1. Uzaktaki tüm branch ve commitleri getir
git fetch origin main

# 2. Yerel değişiklikleri uzaktaki en son commitin üzerine oturt
git rebase origin/main
```

### 2. Çakışan Dosyayı Otomatik/Programatik Çözme
Çakışma durumunda dosya içine `<<<<<<< HEAD`, `=======`, `>>>>>>>` blokları eklenir:
```bash
# Çakışan dosyaları listele
git status --porcelain | grep "^UU"

# Çakışma işaretlerini incele ve hedef içeriği onar
# Çözüm tamamlandıktan sonra dosyayı evreye ekle:
git add labs/LAB-01/README.md

# Rebase işlemini tamamla
git rebase --continue
```

### 3. Çift Yönlü Repo Eşitleme (GitHub & GitLab)
Her iki uzaktaki depoyu (`origin` ve `gitlab`) tek komut dizisiyle senkronize tutma:
```bash
# GitHub Öğrenci Reposuna Gönder
git push origin main

# GitLab Eğitmen Reposuna Gönder
git push gitlab main
```

---

## 3. Doğrulama ve Test Komutları

```bash
# Commit geçmişinin doğrusal ve senkronize olduğunu doğrula:
git log --oneline -n 5 --graph

# Uzak repolar ile yerel branch farkı var mı kontrol et:
git status
```
*Beklenen Sonuç:* `Your branch is up to date with 'origin/main'. nothing to commit, working tree clean`.
