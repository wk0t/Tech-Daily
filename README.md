# Tech & Cyber Daily

Un petit magazine qui me sort chaque jour l'actu **tech, cybersécurité et IA**, sur PC et sur Android. J'en avais marre de faire le tour de quinze sites bourrés de pubs et de bandeaux cookies juste pour lire trois news qui m'intéressent — alors j'ai fait mon propre truc.

L'appli va chercher les articles chez **27 médias** (français et anglais), jette tout ce qui n'est pas de l'informatique, vire les pubs, traduit l'anglais en français, et me présente ça comme un vrai magazine. L'article s'ouvre **dans l'appli** — pas de redirection vers un site qui rame. Pas de compte, pas de pub, pas de mouchard.

## Ce que ça sait faire

Le principal, c'est le magazine du jour : les news des dernières 24 h, triées, nettoyées, traduites, avec une image de couverture et le texte complet lisible directement. Le filtrage est assez agressif — si un article parle de bons plans Amazon ou de politique, il dégage.

Autour de ça j'ai empilé pas mal de confort de lecture :

- recherche par mot-clé, sujet ou source ;
- **sujets suivis** : je marque « ransomware » ou « Apple » et les articles concernés remontent en haut, surlignés ;
- **favoris** consultables hors ligne, articles déjà lus grisés, temps de lecture estimé ;
- un **résumé en une ligne** (TL;DR) en tête de chaque article ;
- un **glossaire au toucher** : je touche un terme technique, j'ai sa définition en français simple ;
- **mode podcast** (lecture vocale enchaînée, mains libres) et lecture d'un seul article à voix haute ;
- thème clair / sombre, archives des 7 derniers jours, partage.

Et comme c'est orienté cyber, il y a un peu de sel en plus : une **alerte menace** qui met en avant les news critiques (0-day, ransomware, faille exploitée), un **niveau de menace du jour**, un petit **quiz sécurité** et l'astuce du jour.

L'appli se prévient elle-même quand une nouvelle version sort (un bandeau, rien de plus — elle ne télécharge jamais rien toute seule).

## Installer

### Windows

Récupère **[`TechCyberDaily.exe`](../../releases/latest)**, double-clique, et le magazine du jour s'ouvre dans ton navigateur. Au premier lancement Windows va râler avec SmartScreen (normal, c'est pas signé) → *Informations complémentaires* → *Exécuter quand même*.

Si tu veux qu'il s'ouvre tout seul le matin, lance `pc/Activer_ouverture_auto.ps1` (clic droit → Exécuter avec PowerShell).

### Android

Télécharge **[`TechCyberDaily.apk`](../../releases/latest)** sur le téléphone, ouvre-le, et autorise l'installation depuis une source inconnue quand Android le demande. Play Protect va prévenir (normal, l'appli n'est pas sur le Play Store) → *Installer quand même*. Il faut Android 7.0 ou plus récent.

### Linux

Prends le **`.AppImage`** dans la [dernière release](../../releases/latest), rends-le exécutable et lance-le :

```bash
chmod +x TechCyberDaily-x86_64.AppImage
./TechCyberDaily-x86_64.AppImage
```

Le magazine s'ouvre dans le navigateur. Il faut juste `python3`, présent d'office sur la plupart des distros.

### iPhone

Le `.ipa` de la release est **non signé**. Pour l'installer, tu le signes avec ton propre Apple ID via un outil de sideloading — c'est permis dans l'UE grâce au DMA :

1. installe [AltStore](https://altstore.io) (ou Sideloadly) sur ton ordi ;
2. branche l'iPhone, ouvre AltStore, connecte-toi avec ton Apple ID (un compte gratuit suffit) ;
3. installe `TechCyberDaily-unsigned.ipa` → AltStore le re-signe et le pose sur le téléphone.

Avec un Apple ID gratuit, il faut le ré-installer tous les 7 jours. Un compte développeur (99 €/an) tient un an.

## Compiler soi-même

**PC** — rien à installer, le compilateur C# est fourni avec Windows :

```powershell
pc\build_exe.ps1
```

**Android** — il faut un JDK 17 et le SDK Android (build-tools 34). Pas de Gradle, je fais tout à la main avec `aapt` + `d8` + `apksigner` :

```powershell
android\build_apk.ps1
```

La clé de signature (`techcyber.jks`) n'est volontairement pas dans le dépôt — le script en génère une au premier build.

**Linux et iOS** se compilent sur Linux et macOS. Comme je n'ai ni l'un ni l'autre sous la main, le dépôt embarque deux recettes **GitHub Actions** qui les construisent gratuitement sur les serveurs de GitHub (onglet *Actions* → *Run workflow*, ou automatiquement quand je pousse un tag `v*`). En local, ce serait `linux/build_appimage.sh` côté Linux et `cd ios && xcodegen generate` côté Mac.

## Comment ça marche

Les news sont récupérées **directement** depuis les flux RSS publics des médias, sans serveur intermédiaire. Sur PC c'est du PowerShell ; sur Android un pont natif en Java contourne les restrictions du navigateur (CORS) et gère l'encodage à la main. Le texte complet de chaque article est extrait de sa page d'origine, débarrassé de ses pubs, puis affiché dans le lecteur intégré. Pour la traduction, j'utilise le point d'accès public et gratuit de Google Traduction.

Rien n'est stocké ailleurs que sur ton appareil.

## Le dépôt en deux mots

```
pc/         la version PC : un gros script PowerShell (le moteur) + le build en .exe
android/    la version Android : une WebView + un pont natif Java, compilée en .apk
linux/      la recette AppImage
ios/        la recette iOS (WebView Swift)
version.json  la version publiée, pour la mise à jour auto
```

## Note

Projet perso, fourni tel quel. Les articles restent la propriété de leurs médias — chacun garde un lien vers sa source. L'appli ne fait qu'agréger et mettre en forme des flux publics pour un usage privé.

## Licence

[MIT](LICENSE) — fais-en ce que tu veux.
