# Windows PowerShell Tools

Une collection de scripts PowerShell pour **entretenir et optimiser Windows** :

* Nettoyage et mise à jour complète du système
* Détection et suppression des fichiers doublons (images/vidéos)

---

## 📚 Sommaire

1. [Windows Clean & Update](#-windows-clean--update)
2. [Windows Media Deduper](#-windows-media-deduper) 

---

## 🧹 Windows Clean & Update

Un script pour **automatiser la mise à jour et le nettoyage** d’un PC Windows.

### 📌 Fonctions principales

* Installe les mises à jour Windows (PSWindowsUpdate)
* Met à jour Chocolatey & Winget
* Vide les fichiers temporaires et journaux
* Nettoie l’OS (DISM, CompactOS)
* Redémarre si nécessaire

### 🚀 Usage

```powershell
.\CleanAndUpdate.ps1
```

---

## 🗂️ Windows Media Deduper

Un script pour **supprimer les doublons** (images/vidéos) en se basant sur le **contenu**.

### 📌 Fonctions principales

* Scan récursif d’un dossier
* Détection par **SHA-256**
* Rapport CSV détaillé
* Déplacement en **quarantaine** ou suppression directe
* Choix du fichier conservé : **ancien** ou **récent**

### 🚀 Usage

Lister (dry-run) :

```powershell
.\dedupe.ps1 -Root 'D:\Image' -Action list
```

Déplacer en quarantaine :

```powershell
.\dedupe.ps1 -Root 'D:\Image' -Action move -Apply -Quarantine 'D:\QUARANTAINE_DUPS' -Keep oldest
```

Supprimer :

```powershell
.\dedupe.ps1 -Root 'D:\Image' -Action delete -Apply -Keep newest
```

---

## 📋 Prérequis communs

* Windows 10 / 11
* PowerShell 5.1+ (recommandé : **PowerShell 7**)
* Exécution en tant qu’administrateur
* Autoriser les scripts :

  ```powershell
  Set-ExecutionPolicy Bypass -Scope CurrentUser -Force
  ```
* (Pour le deduper) activer les **chemins longs** :

  ```powershell
  reg add HKLM\SYSTEM\CurrentControlSet\Control\FileSystem /v LongPathsEnabled /t REG_DWORD /d 1 /f
  ```

---

## 🤝 Contribuer

* Fork du projet
* Créez une branche `feature/x`
* Committez vos changements
* Ouvrez une Pull Request
* Les issues sont les bienvenues

---

## 📝 Licence

MIT — scripts libres d’utilisation, sans garantie.

---

👉 Veux-tu que je te génère aussi la **structure de repo GitHub complète** (arborescence avec `scripts/`, `docs/`, et ce README combiné en racine), ou tu préfères juste coller ce README directement à côté de tes `.ps1` ?
