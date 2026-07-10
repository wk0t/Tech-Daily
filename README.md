# 📰 Tech & Cyber Daily

> Ton magazine quotidien d'actualités **tech, cybersécurité et intelligence artificielle** — sur PC et sur Android.

Chaque jour, l'application va chercher les dernières news auprès de **27 médias** francophones et anglophones, ne garde que ce qui parle vraiment d'informatique, retire les publicités, traduit automatiquement les articles anglais en français, et te les présente comme un vrai magazine — avec **lecture intégrée** (l'article s'ouvre directement dans l'app, sans redirection vers un site bourré de pubs).

Le tout **sans compte, sans pub, sans traçage**.

---

## ✨ Fonctionnalités

**Le magazine**
- 🔄 Récupération automatique des news depuis 27 sources (cyber, tech, IA, hardware)
- 🧹 Filtrage intelligent : uniquement du contenu informatique, zéro bon plan / pub / hors-sujet
- 🌐 Traduction automatique français des articles anglophones
- 📖 Lecture intégrée de l'article (texte + images extraits proprement, sans les pubs du site)
- 🖼️ Une image de couverture pour chaque article (via le flux ou la page)

**Pour lire mieux**
- 🔍 Recherche par mot-clé, sujet ou source
- ⭐ Sujets suivis (les articles correspondants remontent et sont surlignés)
- ❤️ Favoris / lire plus tard (accessibles hors ligne)
- 🕶️ Articles déjà lus grisés
- ⏱️ Temps de lecture estimé
- ⚡ Résumé « en bref » (TL;DR) en tête de chaque article
- 📖 Glossaire au toucher : touche un terme technique pour sa définition en français simple
- 🎧 Mode podcast : lecture vocale enchaînée, mains-libres
- 🔊 Synthèse vocale d'un article
- 🌗 Thème clair / sombre
- 👍👎 Personnalisation : vote sur les sources
- 📚 Archives des 7 derniers jours
- ↗️ Partage d'un article

**Spécial cyber**
- 🔴 Alerte menace : les news critiques (0-day, ransomware, faille exploitée…) sont mises en avant
- ⛈️ Niveau de menace du jour (Calme → Tempête cyber)
- 🧠 Quiz sécurité du jour

**Bonus**
- 💡 Astuce sécurité du jour
- 🔔 Mise à jour automatique : l'app te prévient quand une nouvelle version est disponible

---

## 📥 Installation (pour utiliser l'app)

### 💻 Sur PC (Windows)
1. Télécharge **[`TechCyberDaily.exe`](TechCyberDaily.exe)**.
2. Double-clique dessus. Le magazine du jour s'ouvre dans ton navigateur.
3. Au premier lancement, Windows peut afficher un avertissement SmartScreen (normal pour un programme non signé) → **Informations complémentaires → Exécuter quand même**.

> Astuce : lance `pc/Activer_ouverture_auto.ps1` (clic droit → Exécuter avec PowerShell) pour ouvrir le magazine automatiquement chaque matin.

### 📱 Sur Android
1. Télécharge **[`TechCyberDaily.apk`](TechCyberDaily.apk)** sur ton téléphone.
2. Ouvre le fichier → autorise l'installation d'applications de sources inconnues quand Android le demande.
3. Si Play Protect prévient (normal pour une app hors Play Store) → **Installer quand même**.

Android 7.0 (Nougat) ou plus récent.

---

## 🔄 Mise à jour automatique

L'application compare sa version à celle publiée dans [`version.json`](version.json). Quand une version plus récente est disponible, un bandeau **« 🔔 Nouvelle version disponible »** apparaît avec un lien de téléchargement. L'app ne télécharge et n'installe **jamais** rien toute seule — c'est toi qui décides.

**Pour publier une mise à jour** (côté mainteneur) :
1. Modifie le code, reconstruis l'`.exe` et l'`.apk` (voir ci-dessous).
2. Remplace `TechCyberDaily.exe` et `TechCyberDaily.apk` à la racine du dépôt.
3. Incrémente le numéro dans `version.json` (ex. `1.0.0` → `1.1.0`) et adapte les `notes`.
4. Pousse le tout sur GitHub. Les apps installées afficheront le bandeau.

---

## 🛠️ Construire depuis les sources

### PC
Aucun outil à installer (le compilateur C# est fourni avec Windows) :
```powershell
pc\build_exe.ps1     # génère TechCyberDaily.exe
```

### Android
Nécessite un JDK 17 et le SDK Android (build-tools 34, platform android-34). Compilation **sans Gradle**, avec `aapt` + `d8` + `apksigner` :
```powershell
android\build_apk.ps1     # génère TechCyberDaily.apk
```
> La clé de signature (`techcyber.jks`) n'est volontairement **pas** incluse dans le dépôt. Le script en régénère une automatiquement au premier build.

---

## 🗂️ Structure du projet

```
tech-daily/
├── pc/                          Version PC (PowerShell → .exe)
│   ├── TechCyberDaily.ps1         Moteur : récupération, filtres, traduction, extraction, génération HTML
│   ├── build_exe.ps1             Compile le script en .exe autonome
│   └── *_ouverture_auto.ps1      Activer / désactiver l'ouverture automatique du matin
├── android/                     Version Android (WebView native)
│   ├── assets/index.html         L'application complète (interface + logique)
│   ├── src/.../MainActivity.java Pont natif : réseau, cache, voix, notification
│   ├── src/.../NotifReceiver.java Notification quotidienne
│   ├── src/.../WidgetProvider.java Widget écran d'accueil
│   ├── AndroidManifest.xml
│   └── build_apk.ps1             Compile l'.apk
├── version.json                 Version publiée (pour la mise à jour auto)
├── TechCyberDaily.exe            Binaire PC prêt à l'emploi
└── TechCyberDaily.apk            Binaire Android prêt à l'emploi
```

---

## ⚙️ Comment ça marche

Les news sont récupérées **directement** depuis les flux RSS publics des médias (pas de serveur intermédiaire). Sur PC, c'est PowerShell qui fait le travail ; sur Android, un pont natif Java contourne les restrictions du navigateur (CORS) et gère l'encodage. Le contenu complet des articles est extrait de la page d'origine, nettoyé de ses publicités, puis affiché dans un lecteur intégré. La traduction utilise le point d'accès public gratuit de Google Traduction.

---

## 📝 Note

Projet personnel, fourni tel quel. Les articles restent la propriété de leurs médias respectifs ; chaque article garde un lien vers sa source d'origine. L'application se contente d'agréger et de mettre en forme des flux publics pour un usage privé.

## 📄 Licence

[MIT](LICENSE) — fais-en ce que tu veux.
