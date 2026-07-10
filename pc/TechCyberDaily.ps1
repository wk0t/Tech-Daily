# =====================================================================
#  Tech & Cyber Daily  —  Ton magazine quotidien tech / cyber / IA
#  Récupère les news directement (sans proxy), extrait le contenu
#  complet des articles (lecture intégrée, sans pub) et génère le
#  magazine HTML dans le dossier temporaire.
#  IMPORTANT : ce fichier doit rester encodé en UTF-8 AVEC BOM
#  (sinon Windows PowerShell 5.1 casse les accents).
# =====================================================================
$ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13 } catch {}
[System.Net.ServicePointManager]::DefaultConnectionLimit = 16

$outFile = Join-Path $env:TEMP "TechCyberDaily_magazine.html"
$APP_VERSION = "1.0.0"   # version locale, comparee a version.json sur GitHub pour la mise a jour auto

# ---- Sources (flux RSS) — lang='en' => l'article sera traduit en français ----
$feeds = @(
  # --- Cyber / sécurité (FR) ---
  @{url="https://www.zataz.com/feed/";                                             name="Zataz";            cat="cyber"; lang="fr"},
  @{url="https://www.lemagit.fr/rss/ContentSyndication.xml";                       name="LeMagIT";          cat="cyber"; lang="fr"},
  @{url="https://www.lemondeinformatique.fr/flux-rss/thematique/securite/rss.xml"; name="Le Monde Info";    cat="cyber"; lang="fr"},
  @{url="https://www.it-connect.fr/feed/";                                         name="IT-Connect";       cat="cyber"; lang="fr"},
  @{url="https://www.undernews.fr/feed";                                           name="UnderNews";        cat="cyber"; lang="fr"},
  # --- Cyber / sécurité (EN, traduit) ---
  @{url="https://feeds.feedburner.com/TheHackersNews";                             name="The Hacker News";  cat="cyber"; lang="en"},
  @{url="https://www.bleepingcomputer.com/feed/";                                  name="BleepingComputer"; cat="cyber"; lang="en"},
  @{url="https://krebsonsecurity.com/feed/";                                       name="Krebs on Security";cat="cyber"; lang="en"},
  @{url="https://www.securityweek.com/feed/";                                      name="SecurityWeek";     cat="cyber"; lang="en"},
  # --- Tech généraliste (FR) ---
  @{url="https://www.numerama.com/feed/";                                          name="Numerama";         cat="tech"; lang="fr"},
  @{url="https://korben.info/feed";                                                name="Korben";           cat="tech"; lang="fr"},
  @{url="https://www.01net.com/feed/";                                             name="01net";            cat="tech"; lang="fr"},
  @{url="https://www.clubic.com/articles.rss";                                     name="Clubic";           cat="tech"; lang="fr"},
  @{url="https://www.journaldugeek.com/feed/";                                     name="Journal du Geek";  cat="tech"; lang="fr"},
  @{url="https://www.presse-citron.net/feed/";                                     name="Presse-citron";    cat="tech"; lang="fr"},
  @{url="https://www.silicon.fr/feed";                                             name="Silicon";          cat="tech"; lang="fr"},
  @{url="https://www.lesnumeriques.com/rss.xml";                                   name="Les Numériques";   cat="tech"; lang="fr"},
  @{url="https://next.ink/feed/";                                                  name="Next";             cat="tech"; lang="fr"},
  @{url="https://linuxfr.org/news.atom";                                           name="LinuxFr";          cat="tech"; lang="fr"},
  # --- Tech généraliste (EN, traduit) ---
  @{url="https://feeds.arstechnica.com/arstechnica/index";                         name="Ars Technica";     cat="tech"; lang="en"},
  @{url="https://www.theverge.com/rss/index.xml";                                  name="The Verge";        cat="tech"; lang="en"},
  @{url="https://techcrunch.com/feed/";                                            name="TechCrunch";       cat="tech"; lang="en"},
  # --- Intelligence artificielle (FR) ---
  @{url="https://www.actuia.com/feed/";                                            name="ActuIA";           cat="ia";   lang="fr"},
  @{url="https://www.lebigdata.fr/feed";                                           name="LeBigData";        cat="ia";   lang="fr"},
  # --- Hardware / mobile (FR) ---
  @{url="https://www.frandroid.com/feed";                                          name="Frandroid";        cat="hard"; lang="fr"},
  @{url="https://www.tomshardware.fr/feed/";                                       name="Tom's Hardware";   cat="hard"; lang="fr"},
  @{url="https://www.phonandroid.com/feed";                                        name="Phonandroid";      cat="hard"; lang="fr"}
)

# ---- Conteneur du corps d'article, par site (calibré par analyse des sources) ----
$siteContainer = @{
  'thehackernews.com'        = 'articlebody'
  'bleepingcomputer.com'     = 'articleBody'
  'zataz.com'                = 'entry-content'
  'lemagit.fr'               = 'content-body'
  'lemondeinformatique.fr'   = 'article-body'
  'numerama.com'             = 'article-content'
  'korben.info'              = 'article-content'
  '01net.com'                = 'entry-content'
  'clubic.com'               = 'article-body'
  'tomshardware.fr'          = 'article__content'
  'actuia.com'               = 'artbody'
  'linuxfr.org'              = 'entry-content'
  'arstechnica.com'          = 'post-content'
  'lesnumeriques.com'        = 'entry-content'
  'presse-citron.net'        = 'entry-content'
  'theverge.com'             = 'article-body'
  'journaldugeek.com'        = 'article-content'
  'it-connect.fr'            = 'entry-content'
  'krebsonsecurity.com'      = 'entry-content'
  'securityweek.com'         = 'article-content'
}

# ---- Mots-clés pour affiner la catégorie (SANS accents : comparés après repli) ----
$kw = @{
  cyber = @('cyber','piratage','pirate','hacker','hack','ransomware','rancongiciel','malware','virus','faille','vulnerab','phishing','hameconnage','fuite de donnees','data breach','securite','cyberattaque','attaque informatique','cnil','rgpd','exploit','zero-day','0-day','backdoor','botnet','ddos','vol de donnees','arnaque','escroquerie','espionnage')
  ia    = @('intelligence artificielle','chatgpt','openai','gemini','mistral',' llm','gpt-','claude','copilot','machine learning','deep learning','modele de langage','ia generative','anthropic','midjourney',' ia ')
  hard  = @('processeur',' cpu',' gpu','carte graphique','carte mere','nvidia',' amd ','intel','smartphone',' ram ','ddr',' ssd','pc portable','batterie','snapdragon','apple silicon','overclock','ecran oled')
}

# ---- Enlève les accents (matching robuste, insensible aux accents/encodage) ----
function Remove-Diacritics([string]$s) {
  if ([string]::IsNullOrEmpty($s)) { return "" }
  $n = $s.Normalize([Text.NormalizationForm]::FormD)
  $sb = New-Object Text.StringBuilder
  foreach ($c in $n.ToCharArray()) {
    if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
      [void]$sb.Append($c)
    }
  }
  return $sb.ToString().Normalize([Text.NormalizationForm]::FormC).ToLower()
}

# ---- Filtre anti-pub / hors-sujet ----
$blockLink = @('/bons-plans/','/bon-plan','/bons-plans','/deals/','/promo','/coupon','/vroom/','/streaming/','/soldes')
$blockTitle = @(
  'bon plan','bons plans','soldes','promo','reduction','remise','prix casse',
  'moins cher','pas cher','meilleur prix','a prix','french days','black friday','prime day',
  'cyber monday','ventes flash','vente flash','code promo','cashback','destockage',
  'sans payer','en stock','trouver du stock','ou acheter','bon d achat',
  '% de reduction','-20%','-30%','-40%','-50%','-60%','-70%',
  'ou regarder','regarder le match','en direct hd','streaming gratuit','voir le match',
  'coupe du monde','ligue des champions','ligue 1','en clair sur','diffusion tv','chaine et heure',
  'horoscope','guide d achat','meilleures offres','offre du jour','le deal ','les deals'
)
function Is-Junk([string]$title, [string]$link) {
  $t = Remove-Diacritics $title
  $l = $link.ToLower()
  foreach ($w in $blockLink)  { if ($l.Contains($w)) { return $true } }
  foreach ($w in $blockTitle) { if ($t.Contains($w)) { return $true } }
  return $false
}

# ---- Filtre POSITIF : uniquement du contenu lié à l'informatique ----
$topic = @(
  'informatique','ordinateur','logiciel','application','appli','numerique','windows','microsoft',
  'linux','ubuntu','macos','android','iphone','ipad','apple','smartphone','tablette','navigateur',
  'chrome','firefox','safari','internet',' web','site web','en ligne','reseau','wifi','bluetooth',
  'serveur','cloud','datacenter','fichier','systeme d','mise a jour',' update','objet connecte','domotique',
  'processeur',' cpu ',' gpu','carte graphique','carte mere','nvidia','geforce','radeon',' amd ','intel',
  'ryzen',' ram ','ddr','ssd','disque dur','stockage','puce','chipset','semi-conducteur','semiconducteur',
  'snapdragon','qualcomm',' usb','hdmi',' ecran','moniteur','clavier','souris','casque','peripherique',
  'routeur','router','firmware','console','nintendo','xbox','playstation','steam ','manette',
  'code source','coder','developpeur','developper','developpement','programmation','python','javascript',
  ' java','rust','github','gitlab','open source','opensource',' api ','base de donnees','framework','algorithme',
  'cyber','securite','security','piratage','pirate','pirater','hacker','hack','ransomware','rancongiciel',
  'malware','logiciel malveillant','virus','trojan','faille','vulnerab','exploit','zero-day','0-day',
  'phishing','hameconnage','fuite de donnees','data breach','leak','backdoor','botnet','ddos','rgpd','gdpr',
  'cnil','chiffrement','encryption','mot de passe','password','antivirus',' vpn','authentif','cve-',
  'cybercrime','cyberattaque','spyware','deepfake','scam',
  'intelligence artificielle','chatgpt','openai','gemini','mistral',' llm','gpt-','gpt4','gpt5',' claude ',
  'copilot','anthropic','machine learning','deep learning','reseau de neurones','chatbot','ia generative',
  'generative','modele de langage',
  'google','meta ','tiktok','telegram','whatsapp',' signal','samsung','huawei','xiaomi','aws ','azure',
  'cloudflare','wordpress','oracle','vmware','cisco','fortinet','quantique','blockchain','starlink'
)
function Is-Relevant([string]$title, [string]$excerpt) {
  $t = ' ' + (Remove-Diacritics ($title + ' ' + $excerpt)) + ' '
  foreach ($w in $topic) { if ($t.Contains($w)) { return $true } }
  return $false
}

# ---- Phrases parasites dans le corps des articles (repliées sans accent) ----
# Phrases assez spécifiques pour ne jamais couper un vrai paragraphe.
$junkPhrases = @(
  # FR — renvois / newsletter / partage / pub
  'lire aussi','a lire egalement','a lire :','a lire aussi','sur le meme sujet','sur le meme theme',
  'a decouvrir aussi','voir aussi :','dans la meme rubrique','notre dossier complet','notre comparatif',
  'abonnez-vous','abonne-toi','inscrivez-vous a','notre newsletter','la newsletter','recevez chaque',
  'recevez toute l actualite','recevez le meilleur','suivez-nous sur','suivez nous sur','rejoignez-nous',
  'rejoignez notre','partagez cet article','partager sur','partager cet article','cliquez ici pour',
  'laisser un commentaire','votre adresse e-mail','votre adresse email','pour aller plus loin',
  'cet article vous a plu','soutenez-nous','faire un don','sur patreon','sur tipeee','en partenariat avec',
  'article sponsorise','ceci est une publicite','contenu sponsorise','politique de confidentialite',
  'gerer mes cookies','accepter les cookies','tous droits reserves','credit photo','credits photo',
  'telechargez l application','notre application','meilleurs vpn','notre guide d achat','code promo',
  # EN — renvois / newsletter / partage / pub
  'read more:','also read:','you might also','you may also','related articles','related stories',
  'related reading','recommended for you','sign up for','subscribe to','our newsletter','follow us on',
  'share this article','leave a comment','all rights reserved','found this article interesting',
  'advertisement','sponsored content','sponsored by','in partnership with','this article originally appeared',
  'trending now','most popular','more from','join the conversation','click here to','continue reading'
)
function Test-JunkParagraph([string]$txt) {
  $t = Remove-Diacritics $txt
  foreach ($w in $junkPhrases) { if ($t.Contains($w)) { return $true } }
  return $false
}

function Clean-Text([string]$html) {
  if ([string]::IsNullOrEmpty($html)) { return "" }
  $t = $html
  $t = [regex]::Replace($t, '(?s)<!\[CDATA\[(.*?)\]\]>', '$1')
  $t = [regex]::Replace($t, '(?s)<[^>]+>', ' ')
  $t = [System.Net.WebUtility]::HtmlDecode($t)
  $t = [regex]::Replace($t, '\s+', ' ')
  return $t.Trim()
}

function Get-Tag([string]$xml, [string]$tag) {
  $m = [regex]::Match($xml, "(?s)<$tag(?:\s[^>]*)?>(.*?)</$tag>")
  if ($m.Success) { return $m.Groups[1].Value }
  return ""
}

function Resolve-Url([string]$u, [string]$pageUrl) {
  if ([string]::IsNullOrWhiteSpace($u)) { return "" }
  if ($u -match '^https?://') { return $u }
  if ($u.StartsWith('//')) { return 'https:' + $u }
  if ($u.StartsWith('/')) {
    $m = [regex]::Match($pageUrl, '^(https?://[^/]+)')
    if ($m.Success) { return $m.Groups[1].Value + $u }
  }
  return ""
}

function Get-ImgSrc([string]$imgTag, [string]$pageUrl) {
  # vignettes d'articles liés / miniatures WordPress : à ignorer
  if ($imgTag -match '(?i)attachment-thumbnail|attachment-medium|wp-post-image') { return "" }
  foreach ($attr in @('data-lazy-src','data-src','data-original','src')) {
    $m = [regex]::Match($imgTag, $attr + '\s*=\s*["'']([^"'']+)["'']', 'IgnoreCase')
    if (-not $m.Success) { continue }
    $u = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value.Trim())
    if ($u.StartsWith('data:')) { continue }
    $u = Resolve-Url $u $pageUrl
    if (-not $u) { continue }
    $low = $u.ToLower()
    $bad = $false
    foreach ($j in @('logo','icon','avatar','badge','pixel','1x1','150x150','emoji','smiley','gravatar','feedburner','doubleclick','/ads/','/ad/','adservice','adserver','taboola','outbrain','optidigital','criteo','banner','sponsor','captcha','.svg','tracking','/track','beacon','bleepstatic.com/c/','/promoted/','/sponsored/')) {
      if ($low.Contains($j)) { $bad = $true; break }
    }
    if ($bad) { continue }
    return $u
  }
  return ""
}

function Get-Image([string]$block) {
  foreach ($rx in @(
      '<media:content[^>]*url="([^"]+\.(?:jpg|jpeg|png|webp|gif)[^"]*)"',
      '<media:content[^>]*medium="image"[^>]*url="([^"]+)"',
      '<media:content[^>]*url="([^"]+)"[^>]*medium="image"',
      '<media:thumbnail[^>]*url="([^"]+)"',
      '<enclosure[^>]*url="([^"]+\.(?:jpg|jpeg|png|webp)[^"]*)"',
      '<img[^>]*src="([^"]+)"',
      '<img[^>]*src=''([^'']+)''' )) {
    $m = [regex]::Match($block, $rx, 'IgnoreCase')
    if ($m.Success) {
      $u = $m.Groups[1].Value.Trim()
      if ($u.StartsWith('//')) { $u = 'https:' + $u }
      if ($u -match '^https?://') { return $u }
    }
  }
  return ""
}

# ---- Image de couverture depuis les métadonnées de la page (og:image / twitter:image) ----
function Get-OgImage([string]$page) {
  if ([string]::IsNullOrWhiteSpace($page)) { return "" }
  foreach ($rx in @(
      '<meta[^>]+property\s*=\s*["'']og:image(?::url)?["''][^>]*content\s*=\s*["'']([^"'']+)["'']',
      '<meta[^>]+content\s*=\s*["'']([^"'']+)["''][^>]*property\s*=\s*["'']og:image["'']',
      '<meta[^>]+name\s*=\s*["'']twitter:image["''][^>]*content\s*=\s*["'']([^"'']+)["'']')) {
    $m = [regex]::Match($page, $rx, 'IgnoreCase')
    if ($m.Success) {
      $u = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value.Trim())
      if ($u.StartsWith('//')) { $u = 'https:' + $u }
      if ($u -match '^https?://' -and $u -notmatch '\.svg') { return $u }
    }
  }
  return ""
}

function Get-Cat([string]$base, [string]$text) {
  $t = Remove-Diacritics $text
  foreach ($w in $kw.cyber) { if ($t.Contains($w)) { return 'cyber' } }
  foreach ($w in $kw.ia)    { if ($t.Contains($w)) { return 'ia' } }
  foreach ($w in $kw.hard)  { if ($t.Contains($w)) { return 'hard' } }
  return $base
}

# ---- Extraction des blocs (paragraphes, sous-titres, images) d'un HTML ----
function Extract-Blocks([string]$html, [string]$pageUrl) {
  $out = New-Object System.Collections.Generic.List[object]
  if ([string]::IsNullOrWhiteSpace($html)) { return @() }
  $h = $html
  $h = [regex]::Replace($h, '(?is)<!\[CDATA\[(.*?)\]\]>', '$1')
  # description encodée en entités HTML (&lt;p&gt;) -> décoder d'abord
  if ($h -notmatch '(?i)<p[\s>]' -and $h -match '(?i)&lt;p') { $h = [System.Net.WebUtility]::HtmlDecode($h) }
  $h = [regex]::Replace($h, '(?is)<script\b.*?</script>', ' ')
  $h = [regex]::Replace($h, '(?is)<style\b.*?</style>', ' ')
  $h = [regex]::Replace($h, '(?is)<!--.*?-->', ' ')
  $h = [regex]::Replace($h, '(?is)<(aside|nav|footer|form|figcaption|button|svg)\b[^>]*>.*?</\1>', ' ')
  # retire les blocs pub / newsletter / articles liés (par classe CSS connue)
  $h = [regex]::Replace($h, '(?is)<(div|section|ul)\b[^>]*\b(?:class|id)\s*=\s*["''][^"'']*(?:ad-|-ad\b|ads\b|advert|optidigital|od-wrapper|taboola|outbrain|mc4wp|newsletter|related-|-related|share|social|sponsor|promo|ars-interlude|most-read|most-popular|read-also|lire-aussi|partner|affiliate|abo-|paywall|comment)[^"'']*["''][^>]*>.*?</\1>', ' ')
  $nText = 0; $nImg = 0
  foreach ($m in [regex]::Matches($h, '(?is)<(p|h2|h3|li|blockquote)(?:\s[^>]*)?>(.*?)</\1>|<img\b[^>]*>')) {
    if ($m.Value -match '(?i)^<img') {
      if ($nImg -ge 8) { continue }
      $src = Get-ImgSrc $m.Value $pageUrl
      if ($src) {
        $dup = $false
        foreach ($b in $out) { if ($b.t -eq 'img' -and $b.v -eq $src) { $dup = $true; break } }
        if (-not $dup) { $out.Add([pscustomobject]@{ t='img'; v=$src }); $nImg++ }
      }
    } else {
      if ($nText -ge 40) { continue }
      $tag = $m.Groups[1].Value.ToLower()
      $raw = $m.Groups[2].Value
      $txt = Clean-Text $raw
      if ($tag -eq 'h2' -or $tag -eq 'h3') {
        if ($txt.Length -ge 8 -and $txt.Length -le 200 -and -not (Test-JunkParagraph $txt)) {
          $out.Add([pscustomobject]@{ t='h'; v=$txt }); $nText++
        }
      } else {
        # un paragraphe qui n'est presque qu'un lien = renvoi "Lire aussi" -> on saute
        $isLinkOnly = ($raw -match '(?i)<a\b') -and ($txt.Length -lt 130)
        if ($txt.Length -ge 60 -and -not $isLinkOnly -and -not (Test-JunkParagraph $txt)) {
          $out.Add([pscustomobject]@{ t='p'; v=$txt }); $nText++
        }
      }
    }
  }
  return $out.ToArray()
}

# ---- Isole la région principale d'une page article ----
function Get-MainRegion([string]$page, [string]$link) {
  if ([string]::IsNullOrWhiteSpace($page)) { return "" }
  $siteHost = ([regex]::Match($link, '^https?://([^/]+)')).Groups[1].Value.ToLower()
  $hint = $null
  foreach ($k in $siteContainer.Keys) { if ($siteHost.Contains($k.ToLower())) { $hint = $siteContainer[$k]; break } }
  $patterns = @()
  if ($hint -and $hint -ne 'article') { $patterns += $hint }
  if (-not $hint -or $hint -eq 'article') {
    $arts = [regex]::Matches($page, '(?is)<article\b[^>]*>(.*?)</article>')
    if ($arts.Count -gt 0) {
      $best = ''
      foreach ($a in $arts) { if ($a.Groups[1].Value.Length -gt $best.Length) { $best = $a.Groups[1].Value } }
      if ($best.Length -gt 1500) { return $best }
    }
  }
  $patterns += @('entry-content','article__content','article-content','article-body','articlebody','post-content','post_content','post-body','obj_text','c-article','content-article','article_content','td-post-content','single-content','story-body','article-text')
  foreach ($pat in $patterns) {
    $mm = [regex]::Match($page, '(?is)<(div|section)\b[^>]*class\s*=\s*["''][^"'']*' + [regex]::Escape($pat) + '[^"'']*["''][^>]*>')
    if ($mm.Success) {
      $start = $mm.Index
      $len = [Math]::Min(80000, $page.Length - $start)
      return $page.Substring($start, $len)
    }
  }
  return $page  # dernier recours : les filtres de paragraphes feront le tri
}

# ---- Téléchargeur partagé (détecte l'encodage : en-tête HTTP, prologue XML, meta) ----
$dlScript = {
  param($u)
  try {
    $req = [System.Net.HttpWebRequest]::Create($u)
    $req.UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
    $req.Accept = 'text/html,application/xhtml+xml,application/xml,text/xml,*/*'
    $req.Timeout = 12000
    $req.ReadWriteTimeout = 12000
    $req.AllowAutoRedirect = $true
    $resp = $req.GetResponse()
    $ms = New-Object System.IO.MemoryStream
    $resp.GetResponseStream().CopyTo($ms)
    $bytes = $ms.ToArray()
    $ms.Dispose()
    $charset = ''
    if ($resp.ContentType -match 'charset=([\w\-]+)') { $charset = $Matches[1] }
    $resp.Close()
    if (-not $charset) {
      $head = [System.Text.Encoding]::ASCII.GetString($bytes, 0, [Math]::Min(4096, $bytes.Length))
      if ($head -match '(?i)(?:charset|encoding)\s*=\s*["'']?([\w\-]+)') { $charset = $Matches[1] }
    }
    $enc = [System.Text.Encoding]::UTF8
    if ($charset) { try { $enc = [System.Text.Encoding]::GetEncoding($charset) } catch {} }
    return $enc.GetString($bytes)
  } catch { return "" }
}
# télécharge une liste d'URLs en parallèle -> tableau aligné sur l'entrée
function Fetch-Many([string[]]$urls) {
  $pool = [runspacefactory]::CreateRunspacePool(1, 10)
  $pool.Open()
  $jobs = @()
  foreach ($u in $urls) {
    $ps = [powershell]::Create()
    $ps.RunspacePool = $pool
    [void]$ps.AddScript($dlScript).AddArgument($u)
    $jobs += @{ ps = $ps; handle = $ps.BeginInvoke() }
  }
  $out = New-Object System.Collections.Generic.List[string]
  foreach ($j in $jobs) {
    $c = ""
    try { $c = ($j.ps.EndInvoke($j.handle) | Select-Object -First 1) } catch { $c = "" }
    $j.ps.Dispose()
    $out.Add([string]$c)
  }
  $pool.Close()
  return $out.ToArray()
}

# =====================================================================
#  PHASE 1 — Récupération des flux (en parallèle)
# =====================================================================
Write-Host "Récupération des dernières news..." -ForegroundColor Cyan
$items = New-Object System.Collections.Generic.List[object]
$seen  = New-Object System.Collections.Generic.HashSet[string]

$feedContents = Fetch-Many ($feeds | ForEach-Object { $_.url })

for ($fi = 0; $fi -lt $feeds.Count; $fi++) {
  $f = $feeds[$fi]
  $content = $feedContents[$fi]
  if ([string]::IsNullOrWhiteSpace($content)) {
    Write-Host ("  - {0} : indisponible" -f $f.name) -ForegroundColor DarkYellow
    continue
  }

  $blocks = [regex]::Matches($content, '(?s)<item(?:\s[^>]*)?>.*?</item>')
  if ($blocks.Count -eq 0) { $blocks = [regex]::Matches($content, '(?s)<entry(?:\s[^>]*)?>.*?</entry>') }

  $n = 0
  foreach ($bm in $blocks) {
    $b = $bm.Value

    $title = Clean-Text (Get-Tag $b 'title')
    if ([string]::IsNullOrWhiteSpace($title)) { continue }

    $link = (Get-Tag $b 'link').Trim()
    if ([string]::IsNullOrWhiteSpace($link) -or $link -notmatch '^https?://') {
      $lm = [regex]::Match($b, '<link[^>]*href="([^"]+)"')
      if ($lm.Success) { $link = $lm.Groups[1].Value }
    }
    $link = ($link -replace '(?s)<!\[CDATA\[(.*?)\]\]>','$1').Trim()
    if ($link -notmatch '^https?://') { continue }

    # écarte pub / bons plans / streaming sport / hors-sujet
    if (Is-Junk $title $link) { continue }

    # dédoublonnage par titre
    $key = $title.ToLower()
    if (-not $seen.Add($key)) { continue }

    $rawDesc = Get-Tag $b 'description'
    if ([string]::IsNullOrWhiteSpace($rawDesc)) { $rawDesc = Get-Tag $b 'summary' }
    $rawFull = Get-Tag $b 'content:encoded'
    if ([string]::IsNullOrWhiteSpace($rawFull)) { $rawFull = Get-Tag $b 'content' }
    if ([string]::IsNullOrWhiteSpace($rawFull)) { $rawFull = $rawDesc }
    if ([string]::IsNullOrWhiteSpace($rawDesc)) { $rawDesc = $rawFull }

    $excerpt = Clean-Text $rawDesc
    $fullText = $excerpt
    if ($excerpt.Length -gt 180) { $excerpt = $excerpt.Substring(0,180) }

    # ne garder que les articles réellement liés à l'informatique
    if (-not (Is-Relevant $title $fullText)) { continue }

    $img = Get-Image $b
    if ([string]::IsNullOrWhiteSpace($img)) { $img = Get-Image $rawFull }

    $dateStr = (Get-Tag $b 'pubDate').Trim()
    if ([string]::IsNullOrWhiteSpace($dateStr)) { $dateStr = (Get-Tag $b 'published').Trim() }
    if ([string]::IsNullOrWhiteSpace($dateStr)) { $dateStr = (Get-Tag $b 'updated').Trim() }
    $iso = ""; $ticks = [long]0
    $dt = [datetime]::MinValue
    if ([datetime]::TryParse($dateStr, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$dt)) {
      $iso = $dt.ToUniversalTime().ToString("o")
      $ticks = $dt.ToUniversalTime().Ticks
    }

    $cat = Get-Cat $f.cat ($title + ' ' + $excerpt)

    $items.Add([pscustomobject]@{
      title      = $title
      link       = $link
      excerpt    = $excerpt
      img        = $img
      source     = $f.name
      cat        = $cat
      date       = $iso
      sort       = $ticks
      rawFull    = $rawFull
      body       = $null
      lang       = $f.lang
      translated = $false
    })
    $n++
    if ($n -ge 12) { break }
  }
  Write-Host ("  + {0} : {1} articles" -f $f.name, $n) -ForegroundColor Green
}

# tri par date décroissante, on garde les 60 plus récents
$top = @($items | Sort-Object -Property sort -Descending | Select-Object -First 60)

# =====================================================================
#  PHASE 2 — Contenu complet pour la lecture intégrée
# =====================================================================
Write-Host "Extraction du contenu des articles (lecture intégrée)..." -ForegroundColor Cyan

$needFetch = New-Object System.Collections.Generic.List[object]
foreach ($it in $top) {
  $blocks = @()
  if ($it.rawFull -and (Clean-Text $it.rawFull).Length -gt 600) {
    $blocks = @(Extract-Blocks $it.rawFull $it.link)
  }
  if ($blocks.Count -ge 3) { $it.body = $blocks }
  # on télécharge la page s'il manque le corps OU l'image de couverture
  if ($blocks.Count -lt 3 -or [string]::IsNullOrWhiteSpace($it.img)) { $needFetch.Add($it) }
}
Write-Host ("  {0} articles complets via le flux, {1} pages à télécharger..." -f ($top.Count - $needFetch.Count), $needFetch.Count)

if ($needFetch.Count -gt 0) {
  $pages = Fetch-Many ($needFetch | ForEach-Object { $_.link })
  $okPages = 0
  for ($pi = 0; $pi -lt $needFetch.Count; $pi++) {
    $it = $needFetch[$pi]
    $pageHtml = $pages[$pi]
    if ($pageHtml) {
      # image de couverture manquante -> og:image de la page
      if ([string]::IsNullOrWhiteSpace($it.img)) {
        $og = Get-OgImage $pageHtml
        if ($og) { $it.img = $og }
      }
      # corps manquant -> on l'extrait
      if (-not $it.body) {
        $region = Get-MainRegion $pageHtml $it.link
        $blocks = @(Extract-Blocks $region $it.link)
        if ($blocks.Count -ge 2) { $it.body = $blocks; $okPages++ }
      }
    }
  }
  Write-Host ("  {0}/{1} pages extraites avec succès" -f $okPages, $needFetch.Count) -ForegroundColor Green
}

# dernier repli image de couverture : 1re image du corps de l'article
foreach ($it in $top) {
  if ([string]::IsNullOrWhiteSpace($it.img) -and $it.body) {
    foreach ($bl in $it.body) { if ($bl.t -eq 'img' -and $bl.v) { $it.img = $bl.v; break } }
  }
}

# =====================================================================
#  PHASE 3 — Traduction automatique des articles en anglais
# =====================================================================
$toTranslate = @($top | Where-Object { $_.lang -eq 'en' })
if ($toTranslate.Count -gt 0) {
  Write-Host ("Traduction de {0} articles anglais vers le français..." -f $toTranslate.Count) -ForegroundColor Cyan
  $trScript = {
    param($texts)
    function Send-Batch($arr) {
      if ($arr.Count -eq 0) { return @() }
      $blob = ($arr -join "`n[[[0]]]`n")
      try {
        $u = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=fr&dt=t&q=" + [Uri]::EscapeDataString($blob)
        $req = [Net.HttpWebRequest]::Create($u)
        $req.UserAgent = 'Mozilla/5.0'; $req.Timeout = 15000
        $resp = $req.GetResponse()
        $sr = New-Object IO.StreamReader($resp.GetResponseStream(), [Text.Encoding]::UTF8)
        $raw = $sr.ReadToEnd(); $sr.Close(); $resp.Close()
        $j = $raw | ConvertFrom-Json
        $outstr = (-join ($j[0] | ForEach-Object { $_[0] }))
        $parts = $outstr -split '\[\[\[0\]\]\]'
        if ($parts.Count -eq $arr.Count) { return @($parts | ForEach-Object { $_.Trim() }) }
        return $arr           # secours : jamais de perte d'ordre
      } catch { return $arr }
    }
    $res = New-Object System.Collections.Generic.List[string]
    $chunk = New-Object System.Collections.Generic.List[string]
    $len = 0
    foreach ($t in $texts) {
      if ($len -gt 0 -and ($len + $t.Length) -gt 1500) {
        foreach ($x in (Send-Batch $chunk)) { [void]$res.Add($x) }
        $chunk.Clear(); $len = 0
      }
      [void]$chunk.Add([string]$t); $len += $t.Length + 12
    }
    if ($chunk.Count -gt 0) { foreach ($x in (Send-Batch $chunk)) { [void]$res.Add($x) } }
    return $res.ToArray()
  }
  $pool2 = [runspacefactory]::CreateRunspacePool(1, 6)
  $pool2.Open()
  $tjobs = @()
  foreach ($it in $toTranslate) {
    $texts = New-Object System.Collections.Generic.List[string]
    [void]$texts.Add([string]$it.title)
    [void]$texts.Add([string]$it.excerpt)
    $idx = New-Object System.Collections.Generic.List[int]
    if ($it.body) {
      for ($k = 0; $k -lt $it.body.Count; $k++) {
        if ($it.body[$k].t -ne 'img') { [void]$texts.Add([string]$it.body[$k].v); [void]$idx.Add($k) }
      }
    }
    $ps = [powershell]::Create()
    $ps.RunspacePool = $pool2
    [void]$ps.AddScript($trScript).AddArgument($texts.ToArray())
    $tjobs += @{ ps = $ps; handle = $ps.BeginInvoke(); item = $it; idx = $idx }
  }
  $okTr = 0
  foreach ($j in $tjobs) {
    $tr = @()
    try { $tr = @($j.ps.EndInvoke($j.handle)) } catch { $tr = @() }
    $j.ps.Dispose()
    if ($tr.Count -ge 2) {
      $j.item.title   = $tr[0]
      $j.item.excerpt = $tr[1]
      for ($m = 0; $m -lt $j.idx.Count -and (2 + $m) -lt $tr.Count; $m++) {
        $j.item.body[$j.idx[$m]].v = $tr[2 + $m]
      }
      $j.item.translated = $true
      $okTr++
    }
  }
  $pool2.Close()
  Write-Host ("  {0}/{1} articles traduits" -f $okTr, $toTranslate.Count) -ForegroundColor Green
}

# objets finaux exportés (sans rawFull/sort)
$export = @($top | ForEach-Object {
  [pscustomobject]@{
    title      = $_.title
    link       = $_.link
    excerpt    = $_.excerpt
    img        = $_.img
    source     = $_.source
    cat        = $_.cat
    date       = $_.date
    translated = [bool]$_.translated
    body       = if ($_.body) { @($_.body) } else { @() }
  }
})

$json = ConvertTo-Json -InputObject $export -Depth 6 -Compress
if ([string]::IsNullOrWhiteSpace($json) -or $export.Count -eq 0) { $json = "[]" }
$json = $json.Replace('</', '<\/')

# ---- Verification de mise a jour : on compare notre version a celle publiee sur GitHub ----
function Compare-Version($a, $b) {
  $pa = ($a -split '\.'); $pb = ($b -split '\.')
  for ($i = 0; $i -lt 3; $i++) {
    $x = [int]($pa[$i]); $y = [int]($pb[$i])
    if ($x -gt $y) { return 1 }; if ($x -lt $y) { return -1 }
  }
  return 0
}
$updateBanner = ""
try {
  $vr = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wk0t/tech-daily/main/version.json" -TimeoutSec 8 -UseBasicParsing -Headers @{'User-Agent'='Mozilla/5.0'}
  $vj = $vr.Content | ConvertFrom-Json
  if ($vj.version -and (Compare-Version $vj.version $APP_VERSION) -gt 0) {
    $dl = if ($vj.exe) { $vj.exe } else { $vj.apk }
    $notes = if ($vj.notes) { [System.Net.WebUtility]::HtmlEncode([string]$vj.notes) } else { "" }
    $updateBanner = "<div class='updatebar' style='display:flex'>&#128276; <b>Nouvelle version $($vj.version) disponible</b> $notes <a href='$dl' target='_blank' rel='noopener'>&#11015; Telecharger</a></div>"
    Write-Host ("Mise a jour disponible : v{0}" -f $vj.version) -ForegroundColor Yellow
  }
} catch { }

$fr = [Globalization.CultureInfo]::GetCultureInfo('fr-FR')
$dateJour = (Get-Date).ToString("dddd d MMMM yyyy", $fr)
$heure    = (Get-Date).ToString("HH:mm")

# ---------------------------------------------------------------
#  Gabarit HTML
# ---------------------------------------------------------------
$template = @'
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Tech &amp; Cyber Daily</title>
<style>
  :root{
    --bg:#0b0e14;--card:#151b2b;--card2:#1b2233;--line:#232c42;--txt:#e7ecf5;--muted:#8b96ad;
    --accent:#4f7cff;--accent2:#12d6a5;--gold:#ffb020;--radius:18px;--shadow:0 10px 30px rgba(0,0,0,.35);--fs:1;
  }
  *{box-sizing:border-box}html,body{margin:0;padding:0}
  body{
    background:radial-gradient(1200px 600px at 80% -10%, rgba(79,124,255,.14), transparent 60%),
      radial-gradient(900px 500px at -10% 10%, rgba(18,214,165,.10), transparent 55%),var(--bg);
    color:var(--txt);font-family:'Segoe UI',system-ui,-apple-system,Roboto,Arial,sans-serif;line-height:1.5;min-height:100vh;
    font-size:calc(16px * var(--fs));
  }
  .wrap{max-width:1240px;margin:0 auto;padding:26px 22px 80px}
  header.top{display:flex;align-items:flex-start;justify-content:space-between;gap:20px;flex-wrap:wrap;padding-bottom:18px;margin-bottom:18px;border-bottom:1px solid var(--line)}
  .brand h1{margin:0;font-size:34px;letter-spacing:.5px;font-weight:800;background:linear-gradient(90deg,#fff,#a9c1ff 60%,var(--accent2));-webkit-background-clip:text;background-clip:text;color:transparent}
  .brand .kick{display:inline-flex;align-items:center;gap:8px;font-size:12px;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:var(--accent2);margin-bottom:6px}
  .brand .kick .dot{width:8px;height:8px;border-radius:50%;background:var(--accent2);box-shadow:0 0 12px var(--accent2)}
  .headright{display:flex;flex-direction:column;align-items:flex-end;gap:8px}
  .headright .date{font-size:15px;font-weight:600;text-transform:capitalize}
  .headright .sub{font-size:12.5px;color:var(--muted)}
  .hbtns{display:flex;gap:8px}
  .iconbtn{width:40px;height:40px;border-radius:12px;border:1px solid var(--line);background:var(--card);color:var(--txt);font-size:17px;cursor:pointer}
  .iconbtn.on{border-color:var(--accent);color:#fff;background:var(--card2)}
  .searchbar{margin-bottom:16px}
  .searchbar input{width:100%;background:var(--card);border:1px solid var(--line);border-radius:12px;color:var(--txt);padding:11px 16px;font-size:15px;outline:none}
  .searchbar input:focus{border-color:var(--accent)}
  .tip{position:relative;overflow:hidden;background:linear-gradient(120deg,#16233f,#171e30 60%);border:1px solid var(--line);border-radius:var(--radius);padding:20px 22px;margin-bottom:16px;box-shadow:var(--shadow)}
  .tip .lbl{font-size:12px;letter-spacing:2px;text-transform:uppercase;color:var(--accent2);font-weight:800}
  .tip h2{margin:8px 0 5px;font-size:20px}.tip p{margin:0;color:#cbd5ea;max-width:900px}
  .digest{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);padding:18px 22px;margin-bottom:16px}
  .digest .lbl{font-size:12px;letter-spacing:2px;text-transform:uppercase;color:var(--gold);font-weight:800;margin-bottom:10px}
  .digest ol{margin:0;padding-left:22px}
  .digest li{margin:0 0 8px;font-size:15px;line-height:1.4;cursor:pointer}
  .digest li:last-child{margin-bottom:0}
  .digest li b{color:var(--txt);font-weight:600}.digest li span{color:var(--muted);font-size:12.5px}
  .digest li:hover b{color:var(--accent)}
  .topics{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:14px}
  .topics .tlab{font-size:12px;color:var(--muted);font-weight:700}
  .topic{display:inline-flex;align-items:center;gap:6px;background:rgba(255,176,32,.13);border:1px solid rgba(255,176,32,.35);color:var(--gold);padding:5px 11px;border-radius:999px;font-size:12.5px;font-weight:600}
  .topic b{cursor:pointer;opacity:.7}
  .topic-add{background:var(--card);border:1px dashed var(--line);color:var(--muted);padding:5px 12px;border-radius:999px;font-size:12.5px;cursor:pointer}
  .filters{display:flex;gap:10px;flex-wrap:wrap;margin-bottom:14px;align-items:center}
  .chip{border:1px solid var(--line);background:var(--card);color:var(--muted);padding:8px 16px;border-radius:999px;cursor:pointer;font-size:13.5px;font-weight:600}
  .chip.active{background:var(--accent);border-color:var(--accent);color:#fff}
  .chip.fav.active{background:#ff4d6d;border-color:#ff4d6d}
  .count{color:var(--muted);font-size:13px;margin-bottom:14px}
  .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:20px}
  .card{position:relative;background:var(--card);border:1px solid var(--line);border-radius:var(--radius);overflow:hidden;display:flex;flex-direction:column;text-decoration:none;color:inherit;box-shadow:var(--shadow);transition:.18s;cursor:pointer}
  .card:hover{transform:translateY(-4px);border-color:#33405e}
  .card.read{opacity:.5}
  .card.pin{border-color:rgba(255,176,32,.5)}
  .thumb{position:relative;aspect-ratio:16/9;background:#0e131f;overflow:hidden}
  .thumb img{width:100%;height:100%;object-fit:cover;display:block;transition:.4s}
  .card:hover .thumb img{transform:scale(1.05)}
  .thumb .noimg{width:100%;height:100%;display:flex;align-items:center;justify-content:center;font-size:44px;opacity:.4}
  .badge{position:absolute;left:12px;top:12px;font-size:11px;font-weight:800;letter-spacing:.5px;text-transform:uppercase;padding:5px 10px;border-radius:8px;color:#fff;backdrop-filter:blur(4px)}
  .b-cyber{background:rgba(255,77,109,.9)}.b-ia{background:rgba(176,107,255,.9)}.b-tech{background:rgba(79,124,255,.9)}.b-hard{background:rgba(255,176,32,.92);color:#1a1400}
  .heart{position:absolute;right:10px;top:10px;width:36px;height:36px;border-radius:50%;border:none;background:rgba(11,14,20,.55);color:#fff;font-size:17px;cursor:pointer;backdrop-filter:blur(4px);z-index:2}
  .heart.on{color:#ff4d6d}
  .pinstar{position:absolute;right:10px;bottom:10px;font-size:16px;filter:drop-shadow(0 1px 2px #000)}
  .body{padding:16px 18px 18px;display:flex;flex-direction:column;gap:8px;flex:1}
  .src{display:flex;align-items:center;justify-content:space-between;font-size:12px;color:var(--muted);gap:6px}
  .src .name{font-weight:700;color:#aab6cf}
  .src .tr{margin-left:7px;font-weight:600;font-size:10.5px;color:var(--accent2);background:rgba(18,214,165,.12);border:1px solid rgba(18,214,165,.3);padding:1px 6px;border-radius:6px}
  .src .meta{white-space:nowrap}
  .card h3{margin:0;font-size:17px;line-height:1.35}
  .card h3 mark{background:rgba(255,176,32,.28);color:inherit;border-radius:3px;padding:0 2px}
  .card .excerpt{margin:0;font-size:13.5px;color:var(--muted);flex:1}
  .card .go{font-size:12.5px;font-weight:700;color:var(--accent)}
  .relnote{font-size:12px;color:var(--accent2);font-weight:600}
  .status{text-align:center;padding:60px 20px;color:var(--muted)}
  .status .big{font-size:20px;color:var(--txt);margin-bottom:8px}
  footer{margin-top:50px;text-align:center;color:var(--muted);font-size:12.5px;border-top:1px solid var(--line);padding-top:22px}

  .modal{position:fixed;inset:0;background:rgba(4,7,14,.82);backdrop-filter:blur(6px);display:none;align-items:center;justify-content:center;z-index:60}
  .modal.open{display:flex}
  .sheet{background:var(--card2);border:1px solid var(--line);border-radius:18px;width:100%;max-width:520px;max-height:82vh;overflow-y:auto;padding:22px}
  .sheet h3{margin:2px 0 16px;font-size:19px}
  .setrow{display:flex;align-items:center;justify-content:space-between;padding:12px 0;border-bottom:1px solid var(--line);font-size:14px}
  .setrow:last-child{border-bottom:none}
  .toggle{width:46px;height:26px;border-radius:999px;border:1px solid var(--line);background:var(--card);position:relative;cursor:pointer;flex:0 0 auto}
  .toggle.on{background:var(--accent);border-color:var(--accent)}
  .toggle .knob{position:absolute;top:2px;left:2px;width:20px;height:20px;border-radius:50%;background:#fff;transition:.15s}
  .toggle.on .knob{left:22px}
  .srcgrid{display:flex;flex-wrap:wrap;gap:7px;margin-top:8px}
  .srctag{font-size:12px;padding:5px 10px;border-radius:999px;border:1px solid var(--line);background:var(--card);color:var(--muted);cursor:pointer}
  .srctag.on{border-color:var(--accent2);color:var(--accent2);background:rgba(18,214,165,.1)}
  .fsbtns{display:flex;gap:6px}
  .fsbtns button{width:34px;height:30px;border-radius:8px;border:1px solid var(--line);background:var(--card);color:var(--txt);cursor:pointer}
  .closebtn{margin-top:16px;width:100%;padding:12px;border-radius:12px;border:1px solid var(--line);background:var(--accent);color:#fff;font-weight:700;font-size:14px;cursor:pointer}

  .reader-backdrop{position:fixed;inset:0;background:rgba(4,7,14,.82);backdrop-filter:blur(6px);display:none;align-items:flex-start;justify-content:center;z-index:50;padding:28px 14px;overflow-y:auto}
  .reader{position:relative;background:var(--card2);border:1px solid var(--line);border-radius:20px;max-width:820px;width:100%;padding:20px 30px 32px;box-shadow:0 30px 80px rgba(0,0,0,.6);margin-bottom:30px}
  .rbar{position:sticky;top:0;display:flex;justify-content:flex-end;gap:8px;z-index:2;padding:4px 0;margin:-6px 0 0}
  .rbtn{width:40px;height:40px;border-radius:12px;border:1px solid var(--line);background:var(--card);color:var(--txt);font-size:16px;cursor:pointer}
  .rbtn.on{border-color:var(--accent);color:#fff}
  .rbtn.fav.on{color:#ff4d6d;border-color:#ff4d6d}
  .rmeta{display:flex;gap:12px;align-items:center;font-size:12.5px;color:var(--muted);flex-wrap:wrap}
  .rmeta .badge{position:static}.rmeta .rsrc{font-weight:700;color:#aab6cf}
  .rmeta .tr{font-weight:600;color:var(--accent2);background:rgba(18,214,165,.12);border:1px solid rgba(18,214,165,.3);padding:2px 8px;border-radius:6px}
  .rtitle{font-size:25px;line-height:1.3;margin:12px 0 6px}
  .rtime{font-size:13px;color:var(--muted);margin:0 0 16px}
  .reader img{max-width:100%;border-radius:12px;margin:6px 0 16px;display:block}
  .reader p{font-size:15.5px;line-height:1.75;color:#d5dcec;margin:0 0 14px}
  .reader p mark,.reader h3 mark,.rtitle mark{background:rgba(255,176,32,.28);color:inherit;border-radius:3px;padding:0 2px}
  .reader h3{font-size:18.5px;margin:24px 0 10px;color:#fff}
  .rnote{color:var(--muted);font-style:italic}
  .rrelated{margin:16px 0;padding:12px 16px;background:var(--card);border:1px solid var(--line);border-radius:12px;font-size:13.5px}
  .rrelated .rl{color:var(--muted);font-weight:700;font-size:11px;text-transform:uppercase;letter-spacing:1px;margin-bottom:6px}
  .rrelated a{color:var(--accent);text-decoration:none;margin-right:14px}
  .rsource{display:inline-block;margin-top:16px;color:var(--accent);font-weight:700;text-decoration:none;font-size:13.5px;border:1px solid var(--line);padding:9px 16px;border-radius:12px}
  @media(max-width:560px){.brand h1{font-size:26px}.headright{align-items:flex-start}}
  /* --- fonctions bonus --- */
  .card.crit{border-color:rgba(255,77,109,.6)}
  .alertpill{color:#ff4d6d;font-weight:800;font-size:10.5px;margin-right:5px}
  .menace{display:none;align-items:center;gap:6px;font-size:12px;font-weight:600;padding:5px 12px;border-radius:999px;border:1px solid var(--line);background:var(--card);color:var(--muted);margin-bottom:14px}
  .menace b{font-weight:800}
  .quiz{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);padding:16px 18px;margin-bottom:14px;display:none}
  .quiz .lbl{font-size:11px;letter-spacing:2px;text-transform:uppercase;color:#b06bff;font-weight:800;margin-bottom:8px}
  .quiz .qq{font-size:15px;font-weight:600;margin-bottom:10px}
  .qopts{display:flex;flex-direction:column;gap:7px}
  .qopt{text-align:left;background:var(--card2);border:1px solid var(--line);color:var(--txt);border-radius:10px;padding:10px 12px;font-size:13.5px;cursor:pointer;font-family:inherit}
  .qopt:hover:not(:disabled){border-color:var(--accent)}
  .qopt.ok{border-color:#12d6a5;background:rgba(18,214,165,.12)}
  .qopt.ko{border-color:#ff4d6d;background:rgba(255,77,109,.12)}
  .qopt:disabled{cursor:default}
  .qexp{margin-top:10px;font-size:13px;color:var(--muted)}
  .tldr{background:rgba(18,214,165,.08);border:1px solid rgba(18,214,165,.3);border-radius:12px;padding:12px 16px;margin:0 0 16px}
  .tldr .tl{font-size:11px;font-weight:800;letter-spacing:1px;text-transform:uppercase;color:var(--accent2);margin-bottom:6px}
  .tldr ul{margin:0;padding-left:18px}.tldr li{margin:0 0 5px;font-size:14px;color:#cbd5ea}
  .gl{border-bottom:1px dashed var(--accent2);cursor:pointer}
  .glpop{position:fixed;z-index:80;max-width:290px;background:var(--card2);border:1px solid var(--accent2);border-radius:10px;padding:10px 13px;font-size:13px;line-height:1.5;color:var(--txt);box-shadow:0 10px 30px rgba(0,0,0,.5);display:none}
  .glpop b{color:var(--accent2);text-transform:capitalize}
  .podbar{position:fixed;left:0;right:0;bottom:0;z-index:65;background:var(--card2);border-top:1px solid var(--line);padding:10px 14px;display:none;align-items:center;gap:12px}
  .podbar .pt{flex:1;font-size:13px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
  .podbar button{background:var(--accent);border:none;color:#fff;border-radius:8px;padding:8px 14px;font-weight:700;cursor:pointer}
  .toast{position:fixed;left:50%;bottom:90px;transform:translateX(-50%);background:var(--card2);border:1px solid var(--accent2);color:var(--txt);padding:10px 16px;border-radius:10px;font-size:13px;z-index:90;display:none;box-shadow:0 10px 30px rgba(0,0,0,.5)}
  .archday{margin-bottom:16px}
  .archdate{font-weight:700;font-size:14px;text-transform:capitalize;margin-bottom:6px;color:var(--accent2)}
  .archlink{display:block;color:var(--txt);text-decoration:none;padding:6px 0;border-bottom:1px solid var(--line);font-size:13.5px}
  .archlink span{color:var(--muted);font-size:12px}
  :root[data-theme="light"]{--bg:#eef1f7;--card:#ffffff;--card2:#ffffff;--line:#dfe4ee;--txt:#1a2233;--muted:#5b6678;--shadow:0 6px 20px rgba(20,30,60,.08)}
  :root[data-theme="light"] .tldr li,:root[data-theme="light"] .tip p{color:#33404f}
  :root[data-theme="light"] .reader p{color:#2a3444}

  .updatebar{display:none;align-items:center;gap:10px;flex-wrap:wrap;background:linear-gradient(90deg,rgba(79,124,255,.18),rgba(18,214,165,.14));border:1px solid var(--accent);border-radius:12px;padding:10px 14px;margin-bottom:12px;font-size:13.5px}
  .updatebar a{color:#fff;background:var(--accent);padding:6px 12px;border-radius:8px;text-decoration:none;font-weight:700}
  .updatebar .uc{margin-left:auto;cursor:pointer;color:var(--muted);font-weight:700}
</style>
</head>
<body>
<div class="wrap">
  __UPDATE__
  <header class="top">
    <div class="brand">
      <span class="kick"><span class="dot"></span> Édition du jour</span>
      <h1>Tech &amp; Cyber Daily</h1>
    </div>
    <div class="headright">
      <div class="date">__DATEJOUR__</div>
      <div class="sub">Actualisé à __HEURE__ · lecture intégrée, sans pub · news anglaises traduites</div>
      <div class="hbtns">
        <button class="iconbtn" id="podBtn" title="Mode podcast">🎧</button><button class="iconbtn" id="ttsAllBtn" title="Écouter le résumé">🔊</button>
        <button class="iconbtn" id="themeBtn" title="Thème clair/sombre">☀️</button><button class="iconbtn" id="archBtn" title="Archives">📚</button><button class="iconbtn" id="setBtn" title="Réglages">⚙️</button>
      </div>
    </div>
  </header>

  <div class="searchbar"><input id="search" type="search" placeholder="🔍 Rechercher un article, un sujet, une source…" autocomplete="off"></div>

  <section class="tip">
    <div class="lbl">💡 Astuce du jour</div>
    <h2 id="tipTitle">—</h2>
    <p id="tipText">—</p>
  </section>

  <section class="digest" id="digest" style="display:none">
    <div class="lbl">📌 Les infos à retenir</div>
    <ol id="digestList"></ol>
  </section>

  <div id="menace" class="menace"></div><section class="quiz" id="quiz"></section><div class="topics" id="topics"></div>

  <div class="filters" id="filters">
    <button class="chip active" data-cat="all">Tout</button>
    <button class="chip" data-cat="cyber">🔒 Cyber</button>
    <button class="chip" data-cat="tech">💻 Tech</button>
    <button class="chip" data-cat="ia">🤖 IA</button>
    <button class="chip" data-cat="hard">🔧 Hardware</button>
    <button class="chip fav" data-cat="fav">❤️ Favoris</button>
  </div>
  <div class="count" id="count"></div>

  <div class="grid" id="grid"></div>
  <div class="status" id="status" style="display:none"></div>

  <footer>Articles extraits des flux publics des médias — lecture sans publicité, news anglaises traduites en français.<br>Chaque article garde un lien vers sa source d’origine.<br><span style="opacity:.55">Tech &amp; Cyber Daily v1.0.0 · mise à jour automatique via GitHub</span></footer>
</div>

<div class="modal" id="setModal">
  <div class="sheet">
    <h3>⚙️ Réglages</h3>
    <div class="setrow"><span>Regrouper les articles en double</span><div class="toggle" id="tgCluster"><div class="knob"></div></div></div>
    <div class="setrow"><span>Taille du texte</span><div class="fsbtns"><button id="fsMinus">A−</button><button id="fsPlus">A+</button></div></div>
    <div style="padding:12px 0 4px;font-size:14px">Sources affichées <span style="color:var(--muted);font-size:12px">(clic pour masquer/afficher)</span></div>
    <div class="srcgrid" id="srcGrid"></div>
    <button class="closebtn" id="setClose">Terminé</button>
  </div>
</div>

<div class="reader-backdrop" id="readerBackdrop"><div class="reader" id="reader"></div></div>
<div id="glpop" class="glpop"></div>
<div id="toast" class="toast"></div>
<div class="podbar" id="podbar"><div class="pt"></div><button id="podStop">&#9209; Stop</button></div>
<div class="modal" id="archModal"><div class="sheet"><h3>&#128218; Archives</h3><div id="archBody"></div><button class="closebtn" id="archClose">Fermer</button></div></div>

<script>
var RAW = __NEWS_JSON__;
var TIPS = [
  {t:"Active la double authentification partout",x:"La 2FA (code généré par une appli comme Authy ou Google Authenticator) bloque la quasi-totalité des piratages de compte, même si ton mot de passe fuite. Commence par ta boîte mail : c’est la clé de tous tes autres comptes."},
  {t:"Un gestionnaire de mots de passe change la vie",x:"Bitwarden ou KeePass génèrent et retiennent un mot de passe unique pour chaque site. Tu n’as qu’un seul mot de passe maître à mémoriser, et plus aucun effet domino en cas de fuite."},
  {t:"Méfie-toi des liens dans les mails, même « officiels »",x:"Le phishing imite ta banque, Amazon ou les impôts. Avant de cliquer, survole le lien pour voir la vraie adresse. En cas de doute, va sur le site en tapant l’adresse toi-même."},
  {t:"Mets à jour… vraiment tout",x:"Windows, navigateur, téléphone, box internet. La plupart des piratages exploitent une faille déjà corrigée par une mise à jour que la victime n’avait pas installée."},
  {t:"Ne branche jamais une clé USB inconnue",x:"Une clé trouvée sur un parking est un grand classique d’attaque : elle peut exécuter un programme malveillant dès l’insertion. Dans le doute, jette-la."},
  {t:"Sauvegarde selon la règle 3-2-1",x:"3 copies de tes données, sur 2 supports différents, dont 1 hors ligne. C’est ta seule vraie protection contre les rançongiciels qui chiffrent tout ton PC."},
  {t:"Sur le Wi-Fi public, utilise un VPN",x:"Dans un café ou un aéroport, quelqu’un peut intercepter ton trafic. Un VPN chiffre tout. À défaut, évite de te connecter à ta banque sur ces réseaux."},
  {t:"Vérifie si tes comptes ont fuité",x:"Le site haveibeenpwned.com te dit gratuitement si ton email apparaît dans une fuite de données connue. Si oui : change immédiatement le mot de passe concerné."},
  {t:"Un mot de passe long bat un mot de passe compliqué",x:"« cheval-orange-tempête-42 » est plus solide et plus facile à retenir que « Xk7!p ». La longueur est ce qui compte le plus contre le piratage par force brute."},
  {t:"Ne réutilise jamais le même mot de passe",x:"Si un site est piraté, les attaquants testent ton couple email/mot de passe partout ailleurs. Un mot de passe unique par site coupe la réaction en chaîne."},
  {t:"Attention aux QR codes en pleine rue",x:"Le « quishing » : un QR code collé sur un parcmètre ou une terrasse peut rediriger vers un faux site de paiement. Vérifie toujours l’adresse qui s’affiche."},
  {t:"Regarde les autorisations de tes applis mobiles",x:"Pourquoi une lampe torche demande-t-elle l’accès à tes contacts et ta position ? Retire les permissions abusives dans les réglages de ton téléphone."},
  {t:"Chiffre ton disque avec BitLocker",x:"Sur Windows Pro, BitLocker chiffre ton disque en un clic. Si ton PC est volé, tes données restent illisibles. Gratuit et déjà intégré."},
  {t:"Méfie-toi des offres trop belles",x:"iPhone à 200 €, crypto qui double en une semaine, colis à réclamer… Si c’est trop beau, c’est une arnaque. Prends toujours le temps de vérifier."},
  {t:"Navigue avec un compte standard, pas administrateur",x:"Un malware a beaucoup plus de mal à s’installer sans les droits admin. Garde le compte administrateur pour les installations, pas pour le quotidien."}
];
(function(){var start=new Date(new Date().getFullYear(),0,0);var day=Math.floor((new Date()-start)/86400000);var tip=TIPS[day%TIPS.length];document.getElementById('tipTitle').textContent=tip.t;document.getElementById('tipText').textContent=tip.x;})();

function lsGet(k,def){try{var v=localStorage.getItem(k);return v==null?def:JSON.parse(v);}catch(e){return def;}}
function lsSet(k,v){try{localStorage.setItem(k,JSON.stringify(v));}catch(e){}}
var SETTINGS=lsGet('tcd_settings',{cluster:true,fontScale:1,disabled:[]});
var READ=lsGet('tcd_read',{}),FAV=lsGet('tcd_fav',{}),TOPICS=lsGet('tcd_topics',[]);
document.documentElement.style.setProperty('--fs',SETTINGS.fontScale||1);

function fold(s){return (s||'').normalize('NFD').replace(/[̀-ͯ]/g,'').toLowerCase();}
var CAT_LABEL={cyber:"Cyber",ia:"IA",tech:"Tech",hard:"Hardware"};
var CAT_ICON={cyber:"🔒",ia:"🤖",tech:"💻",hard:"🔧"};
var ALL=[],CURRENT='all',QUERY='';
function esc(s){var d=document.createElement('div');d.textContent=s||'';return d.innerHTML;}
function timeAgo(iso){if(!iso)return"";var d=new Date(iso);if(isNaN(d))return"";var s=(Date.now()-d.getTime())/1000;if(s<3600)return"il y a "+Math.max(1,Math.round(s/60))+" min";if(s<86400)return"il y a "+Math.round(s/3600)+" h";var days=Math.round(s/86400);return days<=1?"hier":"il y a "+days+" j";}
function readMins(a){if(a.mins)return a.mins;var w=0;var bd=bodyOf(a);if(bd.length){bd.forEach(function(b){if(b.t!=='img')w+=b.v.split(/\s+/).length;});}else{w=(a.excerpt||'').split(/\s+/).length*4;}a.mins=Math.max(1,Math.round(w/200));return a.mins;}
function matchesTopics(a){if(!TOPICS.length)return false;var t=fold(a.title+' '+a.excerpt);for(var i=0;i<TOPICS.length;i++){if(t.indexOf(fold(TOPICS[i]))>=0)return true;}return false;}
function markText(txt){var safe=esc(txt);if(!TOPICS.length)return safe;TOPICS.forEach(function(kw){if(!kw)return;var re=new RegExp('('+kw.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')+')','gi');safe=safe.replace(re,'<mark>$1</mark>');});return safe;}
function titleTokens(t){var f=fold(t).replace(/[^a-z0-9 ]/g,' ').split(/\s+/).filter(function(w){return w.length>3;});var s={};f.forEach(function(w){s[w]=1;});return Object.keys(s);}
function jaccard(a,b){if(!a.length||!b.length)return 0;var setb={};b.forEach(function(w){setb[w]=1;});var inter=0;a.forEach(function(w){if(setb[w])inter++;});return inter/(a.length+b.length-inter);}
function cluster(list){if(!SETTINGS.cluster)return list.slice();var used=[],toks=list.map(function(a){return titleTokens(a.title);});for(var i=0;i<list.length;i++){if(used[i])continue;list[i].related=[];for(var j=i+1;j<list.length;j++){if(used[j]||list[i].source===list[j].source)continue;if(jaccard(toks[i],toks[j])>=0.55){list[i].related.push({source:list[j].source,link:list[j].link});used[j]=true;}}}return list.filter(function(a,i){return !used[i];});}

var grid=document.getElementById('grid'),statusEl=document.getElementById('status');
function findByLink(link){for(var i=0;i<RAW.length;i++){if(RAW[i].link===link)return RAW[i];}if(FAV[link])return FAV[link];return null;}
function visibleList(){
  var list;
  if(CURRENT==='fav'){list=Object.keys(FAV).map(function(k){return FAV[k];});}
  else{list=ALL.filter(function(a){return (CURRENT==='all'||a.cat===CURRENT)&&SETTINGS.disabled.indexOf(a.source)<0;});}
  if(QUERY){var q=fold(QUERY);list=list.filter(function(a){return fold(a.title+' '+a.excerpt+' '+a.source).indexOf(q)>=0;});}
  if(CURRENT!=='fav'){
    var dec=list.map(function(a,i){return {a:a,i:i,p:(TOPICS.length&&matchesTopics(a))?1:0,s:severityOf(a),b:sourceBoost(a)};});
    dec.sort(function(x,y){return (y.p-x.p)||(y.s-x.s)||(y.b-x.b)||(x.i-y.i);});
    list=dec.map(function(o){return o.a;});
  }
  updateMenace();
  return list;
}
function cardHtml(a){
  var b=a.cat||'tech',isFav=!!FAV[a.link],isRead=!!READ[a.link],isPin=(TOPICS.length&&matchesTopics(a)&&CURRENT!=='fav');var sv=severityOf(a);
  var thumb=a.img?"<img src='"+esc(a.img)+"' loading='lazy' referrerpolicy='no-referrer' alt='' onerror=\"this.parentNode.innerHTML='<div class=\\'noimg\\'>"+(CAT_ICON[b]||'')+"</div>'\">":"<div class='noimg'>"+(CAT_ICON[b]||'')+"</div>";
  var tr=a.translated?"<span class='tr'>🌐 traduit</span>":"";
  var rel=(a.related&&a.related.length)?"<span class='relnote'>+ "+a.related.length+" source"+(a.related.length>1?'s':'')+"</span>":"";
  return "<a class='card"+(isRead?' read':'')+(isPin?' pin':'')+(sv===2?' crit':'')+"' data-link='"+esc(a.link)+"'>"+
    "<div class='thumb'><span class='badge b-"+b+"'>"+(CAT_LABEL[b]||'News')+"</span>"+thumb+
      "<button class='heart"+(isFav?' on':'')+"' data-fav='"+esc(a.link)+"'>"+(isFav?'♥':'♡')+"</button>"+(isPin?"<span class='pinstar'>⭐</span>":"")+"</div>"+
    "<div class='body'><div class='src'><span class='name'>"+(sv===2?"<span class='alertpill'>🔴 Alerte</span>":"")+esc(a.source)+tr+"</span><span class='meta'>"+readMins(a)+" min · "+timeAgo(a.date)+"</span></div>"+
    "<h3>"+markText(a.title)+"</h3><p class='excerpt'>"+esc(a.excerpt)+(a.excerpt&&a.excerpt.length>=180?'…':'')+"</p>"+
    "<div class='src'>"+rel+"<span class='go'>Lire ici →</span></div></div></a>";
}
function render(){
  var list=visibleList();
  document.getElementById('count').textContent=list.length+' article'+(list.length>1?'s':'')+(CURRENT==='fav'?' en favori':'');
  if(!list.length){grid.innerHTML='';statusEl.style.display='block';statusEl.innerHTML=CURRENT==='fav'?"<div class='big'>Aucun favori</div><div>Clique le ♡ d’un article pour le sauvegarder.</div>":"<div class='big'>Aucun article</div><div>Essaie une autre rubrique ou recherche.</div>";return;}
  statusEl.style.display='none';grid.innerHTML=list.map(cardHtml).join('');
}
function renderDigest(){var d=document.getElementById('digest'),ol=document.getElementById('digestList');if(!ALL.length){d.style.display='none';return;}var top=ALL.slice(0,3);ol.innerHTML=top.map(function(a){return "<li data-link='"+esc(a.link)+"'><b>"+esc(a.title)+"</b> <span>— "+esc(a.source)+"</span></li>";}).join('');d.style.display='block';}
function renderTopics(){var el=document.getElementById('topics');var h="<span class='tlab'>Sujets suivis :</span>";TOPICS.forEach(function(kw){h+="<span class='topic'>"+esc(kw)+"<b data-deltopic='"+esc(kw)+"'>✕</b></span>";});h+="<span class='topic-add' id='addTopic'>+ suivre un sujet</span>";el.innerHTML=h;}

/* Synthèse vocale (Web Speech) */
var speaking=false;
function speak(text){stopSpeak();if(window.speechSynthesis){var u=new SpeechSynthesisUtterance(text);u.lang='fr-FR';u.onend=function(){speaking=false;syncTts();};speechSynthesis.speak(u);speaking=true;syncTts();}}
function stopSpeak(){if(window.speechSynthesis)speechSynthesis.cancel();speaking=false;syncTts();}
function syncTts(){var b=document.getElementById('ttsAllBtn');if(b)b.classList.toggle('on',speaking);var rb=document.getElementById('rTts');if(rb)rb.classList.toggle('on',speaking);}

/* Lecteur */
var backdrop=document.getElementById('readerBackdrop'),readerEl=document.getElementById('reader'),readerOpen=false,readerCur=null;
function baseU(u){return(u||'').split('?')[0].replace(/-\d+x\d+(\.\w+)$/,'$1');}
function renderReader(a){
  var isFav=!!FAV[a.link];
  var h='<div class="rbar"><button class="rbtn'+(speaking?' on':'')+'" id="rTts" onclick="toggleReadAloud()">🔊</button><button class="rbtn" onclick="shareArticle(readerCur)" title="Partager">↗</button><button class="rbtn" onclick="voteSource(readerCur.source,1);toast(\'Plus de \'+readerCur.source)">👍</button><button class="rbtn" onclick="voteSource(readerCur.source,-1);toast(\'Moins de \'+readerCur.source)">👎</button><button class="rbtn fav'+(isFav?' on':'')+'" onclick="toggleFav(readerCur)">'+(isFav?'♥':'♡')+'</button><button class="rbtn" onclick="closeReader()">✕</button></div>';
  h+='<div class="rmeta"><span class="badge b-'+(a.cat||'tech')+'">'+(CAT_LABEL[a.cat]||'News')+'</span><span class="rsrc">'+esc(a.source)+'</span><span>'+timeAgo(a.date)+'</span>'+(a.translated?'<span class="tr">🌐 traduit de l’anglais</span>':'')+'</div>';
  h+='<h2 class="rtitle">'+markText(a.title)+'</h2><div class="rtime">⏱ '+readMins(a)+' min de lecture</div>';
  if(a.img)h+='<img src="'+esc(a.img)+'" referrerpolicy="no-referrer" onerror="this.remove()">';
  var seen=[baseU(a.img)];
  var bd=bodyOf(a);if(bd.length){bd.forEach(function(bk){if(bk.t==='img'){var kk=baseU(bk.v);if(seen.indexOf(kk)===-1){seen.push(kk);h+='<img src="'+esc(bk.v)+'" loading="lazy" referrerpolicy="no-referrer" onerror="this.remove()">';}}else if(bk.t==='h'){h+='<h3>'+markText(bk.v)+'</h3>';}else{h+='<p>'+markText(bk.v)+'</p>';}});}
  else{h+='<p>'+esc(a.excerpt)+'…</p><p class="rnote">Le contenu complet n’a pas pu être extrait — ouvre l’article sur le site d’origine ci-dessous.</p>';}
  if(a.related&&a.related.length){h+='<div class="rrelated"><div class="rl">Aussi couvert par</div>';a.related.forEach(function(r){h+='<a href="'+esc(r.link)+'" target="_blank" rel="noopener">'+esc(r.source)+' ↗</a>';});h+='</div>';}
  h+='<br><a class="rsource" href="'+esc(a.link)+'" target="_blank" rel="noopener">Source : '+esc(a.source)+' ↗</a>';
  readerEl.innerHTML=h;enhanceReader();
}
function openReaderLink(link){var a=findByLink(link);if(!a)return;readerOpen=true;readerCur=a;if(!READ[a.link]){READ[a.link]=1;lsSet('tcd_read',READ);}backdrop.style.display='flex';document.body.style.overflow='hidden';backdrop.scrollTop=0;renderReader(a);}
function closeReader(){readerOpen=false;readerCur=null;stopSpeak();backdrop.style.display='none';document.body.style.overflow='';render();}
function toggleReadAloud(){if(speaking){stopSpeak();return;}var a=readerCur;if(!a)return;var parts=[a.title];if(a.body)a.body.forEach(function(b){if(b.t!=='img')parts.push(b.v);});else parts.push(a.excerpt);speak(parts.join('. '));}
function snapshot(a){return{title:a.title,link:a.link,excerpt:a.excerpt,img:a.img,source:a.source,cat:a.cat,date:a.date,translated:a.translated,body:a.body||[],related:a.related||null,mins:a.mins||0};}
function toggleFav(a){if(!a)return;if(FAV[a.link])delete FAV[a.link];else FAV[a.link]=snapshot(a);lsSet('tcd_fav',FAV);if(readerOpen&&readerCur===a)renderReader(a);render();}
function addTopic(){var kw=prompt('Suivre un sujet (ex : ransomware, iPhone, IA) :');if(kw==null)return;kw=kw.trim();if(!kw)return;if(TOPICS.map(function(x){return x.toLowerCase();}).indexOf(kw.toLowerCase())<0){TOPICS.push(kw);lsSet('tcd_topics',TOPICS);}renderTopics();render();}
function delTopic(kw){TOPICS=TOPICS.filter(function(x){return x!==kw;});lsSet('tcd_topics',TOPICS);renderTopics();render();}
function openSettings(){document.getElementById('tgCluster').classList.toggle('on',SETTINGS.cluster);var names={};RAW.forEach(function(a){names[a.source]=1;});var g=document.getElementById('srcGrid');g.innerHTML=Object.keys(names).sort().map(function(n){var on=SETTINGS.disabled.indexOf(n)<0;return "<span class='srctag"+(on?' on':'')+"' data-src='"+esc(n)+"'>"+esc(n)+"</span>";}).join('');document.getElementById('setModal').classList.add('open');}
function closeSettings(){document.getElementById('setModal').classList.remove('open');}
function applyFont(){document.documentElement.style.setProperty('--fs',SETTINGS.fontScale);lsSet('tcd_settings',SETTINGS);}
function rebuild(){ALL=cluster(RAW.slice());render();renderDigest();saveHistory();}

document.getElementById('search').addEventListener('input',function(e){QUERY=e.target.value;render();});
document.getElementById('filters').addEventListener('click',function(e){var c=e.target.closest('.chip');if(!c)return;var chips=document.querySelectorAll('.chip');for(var i=0;i<chips.length;i++)chips[i].classList.remove('active');c.classList.add('active');CURRENT=c.dataset.cat;render();});
grid.addEventListener('click',function(e){var fav=e.target.closest('.heart');if(fav){e.preventDefault();e.stopPropagation();toggleFav(findByLink(fav.getAttribute('data-fav')));return;}var card=e.target.closest('a.card');if(!card)return;e.preventDefault();openReaderLink(card.getAttribute('data-link'));});
document.getElementById('digest').addEventListener('click',function(e){var li=e.target.closest('li');if(li)openReaderLink(li.getAttribute('data-link'));});
document.getElementById('topics').addEventListener('click',function(e){if(e.target.id==='addTopic'){addTopic();return;}var del=e.target.getAttribute('data-deltopic');if(del)delTopic(del);});
document.getElementById('setBtn').addEventListener('click',openSettings);
document.getElementById('setClose').addEventListener('click',closeSettings);
document.getElementById('setModal').addEventListener('click',function(e){if(e.target.id==='setModal')closeSettings();});
document.getElementById('tgCluster').addEventListener('click',function(){SETTINGS.cluster=!SETTINGS.cluster;lsSet('tcd_settings',SETTINGS);this.classList.toggle('on',SETTINGS.cluster);rebuild();});
document.getElementById('fsPlus').addEventListener('click',function(){SETTINGS.fontScale=Math.min(1.4,(SETTINGS.fontScale||1)+0.1);applyFont();});
document.getElementById('fsMinus').addEventListener('click',function(){SETTINGS.fontScale=Math.max(0.85,(SETTINGS.fontScale||1)-0.1);applyFont();});
document.getElementById('srcGrid').addEventListener('click',function(e){var t=e.target.closest('.srctag');if(!t)return;var name=t.getAttribute('data-src');var i=SETTINGS.disabled.indexOf(name);if(i<0)SETTINGS.disabled.push(name);else SETTINGS.disabled.splice(i,1);lsSet('tcd_settings',SETTINGS);t.classList.toggle('on',SETTINGS.disabled.indexOf(name)<0);render();});
document.getElementById('ttsAllBtn').addEventListener('click',function(){if(speaking){stopSpeak();return;}var top=ALL.slice(0,5);if(!top.length)return;speak('Voici les infos à retenir. '+top.map(function(a,i){return (i+1)+'. '+a.title+'.';}).join(' '));});
document.addEventListener('keydown',function(e){if(e.key==='Escape'){if(document.getElementById('setModal').classList.contains('open'))closeSettings();else if(readerOpen)closeReader();}});
backdrop.addEventListener('click',function(e){if(e.target===backdrop)closeReader();});

renderTopics();
/* ============ Fonctions bonus (menace, glossaire, TL;DR, podcast, thème, votes, historique, partage, quiz) ============ */
var GLOSSARY={"ransomware":"Logiciel malveillant qui bloque ou verrouille vos fichiers et réclame une rançon en argent pour vous les rendre.","phishing":"Arnaque par faux e-mail ou faux message qui vous pousse à donner vos mots de passe ou vos informations bancaires.","0-day":"Faille de sécurité toute nouvelle, encore inconnue de l’éditeur, que les pirates exploitent avant qu’un correctif existe.","rce":"Faille qui permet à un pirate de faire tourner ses propres programmes à distance sur votre ordinateur ou serveur.","vpn":"Outil qui crée un tunnel sécurisé sur Internet pour masquer votre position et protéger votre connexion.","chiffrement":"Technique qui transforme des données en code illisible, que seule une personne possédant la clé peut relire.","ddos":"Attaque qui inonde un site de connexions pour le saturer et le rendre inaccessible.","malware":"Terme général pour tout programme nuisible conçu pour endommager, espionner ou pirater un appareil.","cve":"Numéro officiel donné à une faille de sécurité connue pour que tout le monde puisse l’identifier facilement.","rgpd":"Loi européenne qui encadre la manière dont les entreprises collectent et utilisent vos données personnelles.","ia générative":"Intelligence artificielle capable de créer du contenu inédit comme du texte, des images ou de la musique.","llm":"Grand modèle d’intelligence artificielle entraîné sur d’énormes quantités de texte pour comprendre et écrire du langage.","cloud":"Le fait de stocker ses fichiers et d’utiliser des logiciels sur des serveurs distants via Internet, plutôt que sur son propre appareil.","api":"Passerelle technique qui permet à deux logiciels de se parler et d’échanger des données automatiquement.","open source":"Logiciel dont le code est public et que chacun peut consulter, utiliser et modifier librement.","pare-feu":"Barrière de sécurité qui filtre les connexions pour bloquer les accès indésirables à un réseau ou un appareil.","authentification à deux facteurs":"Sécurité qui demande, en plus du mot de passe, une deuxième preuve comme un code reçu sur votre téléphone.","cheval de troie":"Programme qui se fait passer pour un logiciel normal mais cache en réalité un virus ou un espion.","spyware":"Logiciel espion qui s’installe discrètement pour surveiller votre activité et voler vos informations.","botnet":"Réseau d’ordinateurs infectés et contrôlés à distance par un pirate pour mener des attaques en masse.","fuite de données":"Situation où des informations privées ou sensibles se retrouvent exposées ou volées, souvent après un piratage.","exploit":"Programme ou astuce qui profite d’une faille pour pirater un système ou en prendre le contrôle.","correctif":"Petite mise à jour publiée par un éditeur pour réparer un bug ou boucher une faille de sécurité.","porte dérobée":"Accès caché laissé dans un logiciel qui permet d’entrer dans un système en contournant la sécurité normale.","force brute":"Méthode de piratage qui essaie automatiquement des milliers de combinaisons jusqu’à trouver le bon mot de passe.","https":"Version sécurisée des sites web qui chiffre les échanges entre votre navigateur et le site visité.","cookie":"Petit fichier déposé par un site sur votre appareil pour vous reconnaître et suivre votre navigation.","deepfake":"Fausse vidéo ou fausse voix créée par intelligence artificielle pour faire dire ou faire faire n’importe quoi à une personne.","blockchain":"Registre numérique partagé et infalsifiable qui enregistre des transactions de façon transparente et sécurisée.","cryptomonnaie":"Monnaie numérique, comme le bitcoin, qui fonctionne sans banque grâce à la technologie blockchain.","bug bounty":"Programme qui récompense financièrement les personnes qui découvrent et signalent des failles dans un logiciel.","hacker":"Personne très douée en informatique qui cherche à contourner ou exploiter les protections d’un système.","dark web":"Partie cachée d’Internet, accessible avec des outils spéciaux, où circulent notamment des activités illégales.","captcha":"Petit test en ligne (images ou lettres) qui vérifie que vous êtes un humain et non un robot.","sandbox":"Espace isolé et sécurisé où l’on peut tester un programme suspect sans risque pour le reste du système.","machine learning":"Branche de l’intelligence artificielle où un programme apprend tout seul à partir d’exemples et de données.","algorithme":"Suite d’instructions qu’un ordinateur suit étape par étape pour résoudre un problème ou accomplir une tâche.","token":"Jeton numérique servant de clé temporaire pour prouver son identité ou représenter une valeur en ligne.","spam":"Courrier ou message indésirable envoyé en masse, souvent publicitaire ou frauduleux.","ver informatique":"Virus capable de se copier tout seul et de se propager d’un ordinateur à l’autre sans intervention humaine.","ingénierie sociale":"Manipulation psychologique qui pousse une personne à révéler des informations ou à commettre une erreur de sécurité.","chatbot":"Programme qui dialogue automatiquement avec vous par messages, pour répondre à des questions ou vous aider.","prompt":"Instruction ou question que l’on écrit à une intelligence artificielle pour obtenir une réponse.","zero-day":"Faille toute neuve, encore inconnue de l’éditeur, exploitée par les pirates avant qu’un correctif n’existe.","cyberattaque":"Tentative malveillante de voler, endommager ou bloquer des données ou des systèmes informatiques."};
var GLOSS_KEYS=Object.keys(GLOSSARY).sort(function(a,b){return b.length-a.length;});
var QUIZ=[{"q":"Quel mot de passe est le plus sûr ?","options":["motdepasse123","J'aime le café à 7h du matin !","azerty"],"correct":1,"explain":"Une phrase de passe longue, mêlant mots, chiffres et symboles, est bien plus difficile à deviner qu'un mot court ou courant."},{"q":"Que signifie l'authentification à deux facteurs (2FA) ?","options":["Utiliser deux mots de passe différents","Ajouter une deuxième preuve d'identité, comme un code sur le téléphone","Changer de mot de passe deux fois par an"],"correct":1,"explain":"La 2FA combine quelque chose que vous savez (mot de passe) avec quelque chose que vous avez (code, application, clé), ce qui bloque la plupart des piratages."},{"q":"Vous recevez un e-mail urgent de votre banque demandant vos identifiants via un lien. Que faites-vous ?","options":["Vous cliquez vite pour ne pas bloquer le compte","Vous ignorez le lien et contactez la banque par le site ou numéro officiel","Vous répondez avec vos identifiants"],"correct":1,"explain":"C'est une tentative de phishing typique. Une banque ne demande jamais vos identifiants par e-mail ; passez toujours par le canal officiel."},{"q":"Pourquoi faut-il installer les mises à jour de sécurité ?","options":["Pour avoir de nouvelles couleurs d'icônes","Pour corriger des failles que les pirates exploitent","Uniquement pour gagner de l'espace disque"],"correct":1,"explain":"Les mises à jour bouchent des vulnérabilités connues. Retarder une mise à jour laisse une porte ouverte aux attaques."},{"q":"À quoi sert principalement un VPN ?","options":["À rendre Internet plus rapide en toutes circonstances","À chiffrer votre connexion et masquer votre adresse IP","À supprimer définitivement les virus"],"correct":1,"explain":"Un VPN chiffre le trafic et cache votre IP, utile sur les réseaux non sûrs, mais ce n'est pas un antivirus et il n'accélère pas la connexion."},{"q":"Quelle est la bonne pratique pour les sauvegardes de données importantes ?","options":["Une seule copie sur l'ordinateur suffit","Appliquer la règle 3-2-1 : trois copies, deux supports, une hors site","Ne sauvegarder qu'une fois par an"],"correct":1,"explain":"La règle 3-2-1 protège contre la panne, le vol et les rançongiciels en gardant plusieurs copies dont une hors du domicile ou dans le cloud."},{"q":"Un site inconnu vous annonce que vous avez gagné un iPhone. Que faites-vous ?","options":["Vous saisissez vos coordonnées bancaires pour les frais de livraison","Vous fermez la page : c'est une arnaque","Vous partagez le lien à vos amis"],"correct":1,"explain":"Les faux gains servent à voler vos données ou votre argent. Si c'est trop beau pour être vrai, c'est une arnaque."},{"q":"Sur un Wi-Fi public gratuit, quelle attitude est la plus prudente ?","options":["Faire ses opérations bancaires sans précaution","Éviter les sites sensibles ou utiliser un VPN","Désactiver le verrouillage de son téléphone"],"correct":1,"explain":"Les réseaux publics peuvent être surveillés. Évitez les données sensibles ou chiffrez votre trafic avec un VPN."},{"q":"Une application lampe de poche demande l'accès à vos contacts et micro. Que faire ?","options":["Accepter, toutes les applis en ont besoin","Refuser : ces permissions n'ont aucun rapport avec sa fonction","Désinstaller votre antivirus"],"correct":1,"explain":"Une permission doit être cohérente avec la fonction de l'appli. Des demandes injustifiées sont un signal d'alerte."},{"q":"Faut-il réutiliser le même mot de passe sur plusieurs sites ?","options":["Oui, c'est plus simple à retenir","Non, un site piraté exposerait tous vos comptes","Oui, si le mot de passe est long"],"correct":1,"explain":"Avec un mot de passe unique par site, la fuite d'un service ne compromet pas les autres. Un gestionnaire de mots de passe aide à les gérer."},{"q":"Comment reconnaître un site web plus sûr pour un paiement ?","options":["L'adresse commence par https et le nom du site est correct","Le site a beaucoup de publicités clignotantes","Il propose uniquement le virement à un particulier"],"correct":0,"explain":"Le https indique une connexion chiffrée, mais vérifiez surtout l'orthographe exacte du nom de domaine, car les arnaqueurs imitent les vrais sites."},{"q":"Qu'est-ce qu'un gestionnaire de mots de passe ?","options":["Un logiciel qui crée et stocke des mots de passe forts","Un carnet papier posé près de l'ordinateur","Un service qui partage vos mots de passe publiquement"],"correct":0,"explain":"Il génère et retient des mots de passe uniques et complexes, protégés par un seul mot de passe maître à mémoriser."},{"q":"Un SMS vous dit qu'un colis est bloqué et demande de payer via un lien. Réaction ?","options":["Payer immédiatement les quelques euros demandés","Ne pas cliquer et vérifier sur le site officiel du transporteur","Rappeler le numéro et donner sa carte bancaire"],"correct":1,"explain":"Le smishing (phishing par SMS) imite les transporteurs. Vérifiez toujours via l'application ou le site officiel, jamais via le lien reçu."},{"q":"Que faire d'un ancien téléphone avant de le revendre ?","options":["Le vendre tel quel, c'est plus rapide","Effacer les données et réinitialiser aux réglages d'usine","Retirer seulement le fond d'écran"],"correct":1,"explain":"Une réinitialisation d'usine efface vos comptes, photos et données personnelles pour qu'ils ne tombent pas entre de mauvaises mains."},{"q":"Le 2FA par application (type authenticator) est généralement...","options":["Moins sûr que rien du tout","Plus sûr que le code par SMS","Inutile si on a un bon mot de passe"],"correct":1,"explain":"Les applications d'authentification résistent mieux au détournement de carte SIM que les codes envoyés par SMS."},{"q":"Un ami vous envoie sur les réseaux un message étrange avec un lien pressant. Que soupçonner ?","options":["Son compte est peut-être piraté","C'est forcément lui, on clique","Le lien est sûr car il vient d'un ami"],"correct":0,"explain":"Les comptes piratés servent à diffuser des liens malveillants. Vérifiez auprès de la personne par un autre moyen avant de cliquer."},{"q":"Pourquoi éviter de tout partager publiquement sur les réseaux sociaux ?","options":["Cela ralentit votre téléphone","Ces informations aident les arnaqueurs à vous cibler ou usurper votre identité","Cela consomme trop de batterie"],"correct":1,"explain":"Dates, lieux et habitudes publiés facilitent l'usurpation d'identité et les arnaques personnalisées. Limitez les informations visibles."},{"q":"Vous branchez une clé USB trouvée par terre. Bonne idée ?","options":["Oui, pour retrouver le propriétaire","Non, elle peut contenir un logiciel malveillant","Oui, si elle est jolie"],"correct":1,"explain":"Une clé inconnue peut infecter votre appareil dès le branchement. Ne connectez jamais un support dont vous ignorez l'origine."},{"q":"Qu'est-ce qu'un rançongiciel (ransomware) ?","options":["Un jeu vidéo en ligne","Un programme qui chiffre vos fichiers et exige une rançon","Un outil de nettoyage du disque"],"correct":1,"explain":"Le rançongiciel bloque l'accès à vos données contre paiement. De bonnes sauvegardes permettent de restaurer sans céder au chantage."},{"q":"Comment repérer un e-mail de phishing ?","options":["Fautes, adresse d'expéditeur douteuse et sentiment d'urgence","Il contient toujours une pièce jointe PDF","Il arrive uniquement le week-end"],"correct":0,"explain":"Fautes d'orthographe, adresses bizarres, urgence et liens suspects sont des signaux classiques d'une tentative de phishing."},{"q":"Faut-il accepter toutes les demandes d'amis d'inconnus en ligne ?","options":["Oui, plus on a de contacts mieux c'est","Non, un faux profil peut chercher à vous arnaquer","Oui, s'ils ont une belle photo"],"correct":1,"explain":"Les faux profils servent aux arnaques sentimentales ou à collecter vos données. N'acceptez que des personnes que vous connaissez vraiment."},{"q":"Quel est l'intérêt de verrouiller son téléphone avec un code ou la biométrie ?","options":["Cela améliore la qualité photo","Cela protège vos données si l'appareil est perdu ou volé","Cela augmente le stockage disponible"],"correct":1,"explain":"Un verrouillage empêche l'accès à vos messages, comptes et applications de paiement en cas de perte ou de vol."},{"q":"On vous appelle en se faisant passer pour le support technique de Microsoft. Que faire ?","options":["Donner l'accès à distance à votre ordinateur","Raccrocher : Microsoft n'appelle pas les particuliers ainsi","Communiquer votre mot de passe Windows"],"correct":1,"explain":"C'est une arnaque au faux support. Ne donnez jamais l'accès à distance ni vos identifiants à un appel non sollicité."},{"q":"Où télécharger une application mobile en confiance ?","options":["Sur les magasins officiels (App Store, Google Play)","Sur n'importe quel lien reçu par message","Sur un site inconnu proposant la version gratuite"],"correct":0,"explain":"Les magasins officiels contrôlent les applications. Les fichiers installés hors magasin peuvent contenir des logiciels malveillants."},{"q":"Un e-mail contient une pièce jointe inattendue nommée facture.exe. Réaction ?","options":["L'ouvrir pour voir de quoi il s'agit","Ne pas l'ouvrir : un fichier .exe inattendu est très suspect","La transférer à toute la famille"],"correct":1,"explain":"Les fichiers exécutables joints non sollicités sont un vecteur courant de virus. En cas de doute, n'ouvrez pas et supprimez."}];
var SEV={"critical":["activement exploite","exploite activement","exploitation active","actively exploited","exploited in the wild","in the wild","0-day","zero-day","zero day","faille critique","vulnerabilite critique","critical vulnerability","critical flaw","rce","execution de code a distance","remote code execution","ransomware","rancongiciel","fuite massive","fuite de donnees","data breach","violation de donnees","backdoor","porte derobee","wormable","emergency patch","correctif d'urgence","under attack","attaque en cours","supply chain","cvss 10","cvss 9.8","prise de controle","compromission"],"important":["correctif","patch","mise a jour de securite","security update","vulnerability patched","faille corrigee","avis de securite","security advisory","cve-","security fix","hotfix","mitigation","bulletin de securite","update available","mise a jour disponible","correctif disponible"]};

function bodyOf(a){return a.body||a.blocks||[];}
function severityOf(a){
  if(a.sev!=null)return a.sev;
  var t=fold((a.title||'')+' '+(a.excerpt||''));
  var s=0,i;
  for(i=0;i<SEV.critical.length;i++){if(t.indexOf(SEV.critical[i])>=0){s=2;break;}}
  if(!s){for(i=0;i<SEV.important.length;i++){if(t.indexOf(SEV.important[i])>=0){s=1;break;}}}
  a.sev=s;return s;
}
function updateMenace(){
  var el=document.getElementById('menace');if(!el)return;
  var c=0;ALL.forEach(function(a){if(severityOf(a)===2)c++;});
  var L=c>=6?{t:'Tempête cyber',e:'⛈️',c:'#ff4d6d'}:c>=3?{t:'Agité',e:'🌩️',c:'#ffb020'}:c>=1?{t:'Vigilance',e:'⚠️',c:'#ffb020'}:{t:'Calme',e:'🟢',c:'#12d6a5'};
  el.style.display='inline-flex';el.style.borderColor=L.c;el.innerHTML='<span>'+L.e+'</span> Niveau de menace : <b style="color:'+L.c+'">'+L.t+'</b>'+(c?' ('+c+' alerte'+(c>1?'s':'')+')':'');
}
var VOTES=lsGet('tcd_votes',{});
function voteSource(src,dir){VOTES[src]=(VOTES[src]||0)+dir;lsSet('tcd_votes',VOTES);}
function sourceBoost(a){var v=VOTES[a.source]||0;return v>3?3:(v<-3?-3:v);}

/* TL;DR extractif */
function sentencesOf(txt){var m=(txt||'').match(/[^.!?]+[.!?]+/g);return m?m:((txt&&txt.length>40)?[txt]:[]);}
function makeTLDR(a){
  var sents=[];
  var bd=bodyOf(a);if(bd.length){bd.forEach(function(b){if(b.t==='p'){sentencesOf(b.v).forEach(function(s){s=s.trim();if(s.length>45)sents.push(s);});}});}
  if(!sents.length&&a.excerpt)sents=[a.excerpt];
  if(sents.length<=3)return sents;
  var kw=['critique','faille','securite','vulnerab','nouveau','annonce','permet','million','utilisateur','attaque','pirate','fuite','lance','disponible'];
  var scored=sents.map(function(s,i){var sc=(sents.length-i)/sents.length;var f=fold(s);kw.forEach(function(w){if(f.indexOf(w)>=0)sc+=0.4;});return {s:s,sc:sc,i:i};});
  scored.sort(function(x,y){return y.sc-x.sc;});
  return scored.slice(0,3).sort(function(x,y){return x.i-y.i;}).map(function(o){return o.s;});
}

/* Glossaire : surligne les termes dans le lecteur (nœuds texte uniquement) */
function glossify(){
  if(!readerEl)return;
  var used={};
  var walker=document.createTreeWalker(readerEl,NodeFilter.SHOW_TEXT,null,false);
  var nodes=[],n;
  while(n=walker.nextNode()){var p=n.parentNode;if(p&&/^(P|H3|LI)$/.test(p.tagName)&&p.className.indexOf('rnote')<0)nodes.push(n);}
  nodes.forEach(function(tn){
    var txt=tn.nodeValue,low=fold(txt);
    for(var k=0;k<GLOSS_KEYS.length;k++){
      var term=GLOSS_KEYS[k];if(used[term])continue;
      var ft=fold(term),idx=low.indexOf(ft);if(idx<0)continue;
      var bfr=low.charAt(idx-1),aft=low.charAt(idx+ft.length);
      if(bfr&&/[a-z0-9éèàâê]/.test(bfr))continue;
      if(aft&&/[a-z0-9éèàâê]/.test(aft))continue;
      used[term]=1;
      var span=document.createElement('span');span.className='gl';span.setAttribute('data-t',term);span.textContent=txt.substr(idx,term.length);
      var post=document.createTextNode(txt.substr(idx+term.length));
      tn.nodeValue=txt.substr(0,idx);
      tn.parentNode.insertBefore(span,tn.nextSibling);
      tn.parentNode.insertBefore(post,span.nextSibling);
      break;
    }
  });
}
function showGloss(el){
  var t=el.getAttribute('data-t'),def=GLOSSARY[t];if(!def)return;
  var pop=document.getElementById('glpop');pop.innerHTML='<b>'+esc(t)+'</b><br>'+esc(def);
  var r=el.getBoundingClientRect();pop.style.display='block';
  var top=r.bottom+8,left=Math.min(r.left,window.innerWidth-300);
  pop.style.top=Math.min(top,window.innerHeight-120)+'px';pop.style.left=Math.max(8,left)+'px';
}
function hideGloss(){var p=document.getElementById('glpop');if(p)p.style.display='none';}

/* Enrichit le lecteur après chaque rendu : TL;DR + glossaire */
function enhanceReader(){
  var a=readerCur;if(!a||!readerEl)return;
  if(bodyOf(a).length){
    var tl=makeTLDR(a);
    if(tl.length){
      var box=document.createElement('div');box.className='tldr';
      box.innerHTML='<div class="tl">⚡ En bref</div><ul>'+tl.map(function(s){return '<li>'+esc(s)+'</li>';}).join('')+'</ul>';
      var anchor=readerEl.querySelector('.rtime');
      if(anchor)anchor.parentNode.insertBefore(box,anchor.nextSibling);
    }
  }
  glossify();
}

/* Mode podcast 🎧 */
var podcast={on:false,queue:[],idx:0};
function startPodcast(){
  var list=visibleList().slice(0,15);if(!list.length)return;
  podcast={on:true,queue:list,idx:0};playPodcast();
}
function playPodcast(){
  if(!podcast.on||podcast.idx>=podcast.queue.length){stopPodcast();return;}
  var a=podcast.queue[podcast.idx];
  var tl=(bodyOf(a).length)?makeTLDR(a).join(' '):a.excerpt;
  var bar=document.getElementById('podbar');
  if(bar){bar.style.display='flex';bar.querySelector('.pt').textContent='🎧 '+(podcast.idx+1)+'/'+podcast.queue.length+' — '+a.title;}
  speak('Article '+(podcast.idx+1)+'. '+a.title+'. '+(tl||''));
}
function stopPodcast(){podcast.on=false;stopSpeak();var bar=document.getElementById('podbar');if(bar)bar.style.display='none';}
window.onSpeakDone=function(){if(podcast.on){podcast.idx++;playPodcast();}else{speaking=false;syncTts();}};

/* Thème clair/sombre */
function applyTheme(){document.documentElement.setAttribute('data-theme',SETTINGS.theme||'dark');var b=document.getElementById('themeBtn');if(b)b.textContent=(SETTINGS.theme==='light')?'🌙':'☀️';}
function toggleTheme(){SETTINGS.theme=(SETTINGS.theme==='light')?'dark':'light';lsSet('tcd_settings',SETTINGS);applyTheme();}

/* Partage */
function toast(msg){var t=document.getElementById('toast');if(!t)return;t.textContent=msg;t.style.display='block';clearTimeout(window.__tt);window.__tt=setTimeout(function(){t.style.display='none';},2200);}
function shareArticle(a){
  if(!a)return;var text=a.title+' — '+a.link;
  if(window.AndroidBridge&&AndroidBridge.share){AndroidBridge.share(text);return;}
  if(navigator.share){navigator.share({title:a.title,url:a.link}).catch(function(){});return;}
  try{navigator.clipboard.writeText(text);toast('Lien copié !');}catch(e){window.prompt('Copie ce lien :',a.link);}
}

/* Historique / archives */
function saveHistory(){
  if(!ALL.length)return;
  var hist=lsGet('tcd_history',{});
  var key=new Date().toISOString().slice(0,10);
  hist[key]=ALL.slice(0,40).map(function(a){return {title:a.title,link:a.link,img:a.img,source:a.source,cat:a.cat,date:a.date,excerpt:a.excerpt};});
  var keys=Object.keys(hist).sort().reverse().slice(0,7);var trimmed={};keys.forEach(function(k){trimmed[k]=hist[k];});
  lsSet('tcd_history',trimmed);
}
function openArchives(){
  var hist=lsGet('tcd_history',{});var keys=Object.keys(hist).sort().reverse();
  var m=document.getElementById('archModal'),body=document.getElementById('archBody');
  if(!keys.length){body.innerHTML='<div style="color:var(--muted)">Aucun historique pour le moment. Reviens demain !</div>';}
  else{
    body.innerHTML=keys.map(function(k){
      var d=new Date(k+'T12:00:00').toLocaleDateString('fr-FR',{weekday:'long',day:'numeric',month:'long'});
      var arts=hist[k];
      return '<div class="archday"><div class="archdate">'+esc(d)+' <span style="color:var(--muted);font-weight:400">('+arts.length+')</span></div>'+
        arts.slice(0,12).map(function(a){return '<a class="archlink" href="'+esc(a.link)+'" target="_blank" rel="noopener">'+esc(a.title)+' <span>· '+esc(a.source)+'</span></a>';}).join('')+'</div>';
    }).join('');
  }
  m.classList.add('open');
}

/* Quiz du jour 🧠 */
function renderQuiz(){
  var el=document.getElementById('quiz');if(!el||!QUIZ.length)return;
  var start=new Date(new Date().getFullYear(),0,0);var day=Math.floor((new Date()-start)/86400000);
  var qi=day%QUIZ.length,q=QUIZ[qi];
  var answered=lsGet('tcd_quiz_'+qi,null);
  var h='<div class="lbl">🧠 Quiz sécurité du jour</div><div class="qq">'+esc(q.q)+'</div><div class="qopts">';
  q.options.forEach(function(o,i){var cls='qopt';if(answered!=null){if(i===q.correct)cls+=' ok';else if(i===answered)cls+=' ko';}h+='<button class="'+cls+'" data-qi="'+i+'"'+(answered!=null?' disabled':'')+'>'+esc(o)+'</button>';});
  h+='</div>';
  if(answered!=null)h+='<div class="qexp">'+(answered===q.correct?'✅ Bravo ! ':'❌ ')+esc(q.explain)+'</div>';
  el.innerHTML=h;el.style.display='block';el.setAttribute('data-qi',qi);el.setAttribute('data-correct',q.correct);el.setAttribute('data-exp',q.explain);
}

function initFeatures(){
  applyTheme();
  renderQuiz();
  var tb=document.getElementById('themeBtn');if(tb)tb.addEventListener('click',toggleTheme);
  var pb=document.getElementById('podBtn');if(pb)pb.addEventListener('click',function(){if(podcast.on)stopPodcast();else startPodcast();});
  var ab=document.getElementById('archBtn');if(ab)ab.addEventListener('click',openArchives);
  var ps=document.getElementById('podStop');if(ps)ps.addEventListener('click',stopPodcast);
  var am=document.getElementById('archModal');if(am)am.addEventListener('click',function(e){if(e.target.id==='archModal'||e.target.id==='archClose')am.classList.remove('open');});
  var qz=document.getElementById('quiz');
  if(qz)qz.addEventListener('click',function(e){var b=e.target.closest('.qopt');if(!b||b.disabled)return;var qi=qz.getAttribute('data-qi');lsSet('tcd_quiz_'+qi,parseInt(b.getAttribute('data-qi'),10));renderQuiz();});
  document.addEventListener('click',function(e){var g=e.target.closest('.gl');if(g){showGloss(g);e.stopPropagation();}else{hideGloss();}});
  document.addEventListener('keydown',function(e){if(e.key==='Escape'){hideGloss();if(podcast.on)stopPodcast();var a=document.getElementById('archModal');if(a)a.classList.remove('open');}});
}

initFeatures();
rebuild();
</script>
</body>
</html>

'@

$html = $template.Replace('__NEWS_JSON__', $json).Replace('__DATEJOUR__', $dateJour).Replace('__HEURE__', $heure).Replace('__UPDATE__', $updateBanner)
[System.IO.File]::WriteAllText($outFile, $html, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ""
Write-Host ("Magazine généré : {0} articles" -f $export.Count) -ForegroundColor Cyan
Start-Process $outFile
