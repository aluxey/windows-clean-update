# Windows Clean & Update

Un script PowerShell pour automatiser la mise à jour et le nettoyage complet d’un PC Windows.

- 📌 **Fonctions principales**  
  - Recherche et installe les mises à jour Windows (via PSWindowsUpdate)  
  - Met à jour les paquets Chocolatey & Winget  
  - Vide les dossiers temporaires  
  - Nettoie les composants Windows (DISM) et compacte l’OS (CompactOS)  
  - Vide les journaux d’événements  
  - Redémarre automatiquement si nécessaire
    
---

## 📋 Prérequis

- Windows 10 / 11  
- PowerShell 5.1+ (ou PowerShell Core)  
- Exécution en tant qu’administrateur  
- [PSWindowsUpdate](https://www.powershellgallery.com/packages/PSWindowsUpdate) (sera installé automatiquement)  
- (Optionnel) [Chocolatey](https://chocolatey.org/) et/ou [winget](https://learn.microsoft.com/fr-fr/windows/package-manager/winget/)  

---

## 🚀 Installation

1. Clonez ce dépôt :  
   ```powershell
   git clone https://github.com/VOTRE-UTILISATEUR/windows-clean-update.git
   cd windows-clean-update

2. Autorisez l’exécution de scripts :
    ```powershell
    Set-ExecutionPolicy Bypass -Scope CurrentUser -Force

---

## ⚙️ Usage

Lancez simplement le script en tant qu’administrateur :

  ```powershell
  .\CleanAndUpdate.ps1
  ```
    
Le script installera les mises à jour, nettoiera le système et redémarrera si besoin.

---

## 🤝 Contribuer

- Fork du projet
- Créez une branche feature/x
- Commit vos modifications
- Push puis ouvrez une Pull Request
- Ouvrez une Issue pour les bugs ou idées de nouvelles fonctionnalités


