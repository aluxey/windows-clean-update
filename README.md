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

## 📝 Licence

MIT — scripts libres d’utilisation, sans garantie.

---
