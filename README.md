# ⚡ ApexTelemetry — Bug Log & Active Recall Engine (iOS Sideloading)

ApexTelemetry este o aplicație nativă iOS (Swift 5.9+ / SwiftUI) cu temă OLED Pure Black, proiectată specific pentru candidații la examene de elită STEM (Admitere UPB / Politehnica, Bacalaureat, UniBuc FMI) pentru a elimina erorile cognitive recurente prin **Zero-Friction Ingestion** și **Active Recall Flashcard Reconstruction**.

Construită conform standardelor **Zero External Dependencies** (fără CocoaPods sau pachete SPM terțe), se compilează direct din linie de comandă sau GitHub Actions într-un fișier `.ipa` nesemnat, optimizat pentru semnarea web și instalarea prin [FlareStore](https://flarestore.app/web-signer).

---

## 🚀 Ghid Rapid de Compilare pe Windows (GitHub Actions CI/CD)

Deoarece lucrezi de pe un PC cu Windows fără un Mac fizic local cu Xcode, proiectul include un workflow nativ de GitHub Actions configurat pe runner Apple Silicon (`macos-14`).

### Pași pentru obținerea fișierului `.ipa`:
1. **Fă un repo nou pe GitHub** și încarcă acest proiect:
   ```bash
   git init
   git add .
   git commit -m "feat: initial commit ApexTelemetry"
   git branch -M main
   git remote add origin https://github.com/<utilizatorul-tau>/ApexTelemetry.git
   git push -u origin main
   ```
2. **Deschide repository-ul pe GitHub** în browser:
   - Mergi în tab-ul **Actions**.
   - Vei vedea workflow-ul: **„Build Unsigned iOS IPA (FlareStore)”**.
   - În aproximativ **60 - 90 secunde**, job-ul finalizează compilarea cu succes.
3. **Descarcă IPA-ul**:
   - Dă click pe rularea respectivă.
   - În secțiunea **Artifacts** din josul paginii, descarcă arhiva **`ApexTelemetry-unsigned-ipa`**.
   - Dezarhivează fișierul pentru a obține `ApexTelemetry.ipa`.
4. **Semnează și Instalează pe iPhone via FlareStore**:
   - Intră pe [https://flarestore.app/web-signer](https://flarestore.app/web-signer) de pe iPhone (în Safari) sau de pe PC.
   - Încarcă fișierul `ApexTelemetry.ipa`.
   - Selectează certificatul tău de dezvoltator (sau certificatul FlareStore).
   - Apasă **Sign & Install**. Aplicația va fi instalată instantaneu pe ecranul tău principal!

---

## 💻 Compilare Locală (Dacă ai acces la un Mac)

Dacă rulezi pe un Mac cu Xcode 15+ instalat, poți genera `.ipa`-ul local printr-o singură comandă:
```bash
chmod +x build_ipa.sh
./build_ipa.sh
```
Scriptul compilează scheme-ul `ApexTelemetry`, pregătește structura `Payload/ApexTelemetry.app`, împachetează arhiva `ApexTelemetry.ipa` în rădăcina proiectului și curăță fișierele temporare.

---

## 📋 Șabloane Prompt AI pentru Ingestie cu 1-Tap

Când rezolvi grile la Matematică, Fizică sau probleme de Info și greșești o problemă, roagă asistentul tău AI (ChatGPT, Claude, Gemini) să îți ofere rezumatul în următorul format.

### Format Markdown Recomandat (Copiază și dă Paste direct în aplicație):

```markdown
### 🔴 BUG LOG
Materie: Matematica
Subcategorie: Analiză Matematică (Derivate, Integrale, Limite, Asimptote)
Sursă: Culegere UPB 2024 Grila 18
Clasificare: Tip A
Bug: Am aplicat L'Hopital pe forma nedeterminata 0 * infinit in loc de 0/0
Patch: Transforma mereu f * g in f / (1/g) inainte de derivare
Invariant: L'Hopital este valid STRICT pentru cazurile 0/0 si ∞/∞
```

### Format JSON Alternativ:

```json
{
  "subject": "Informatica",
  "subCategory": "Eficiență Fișiere O(1) (Subiectul III.3 streaming)",
  "source": "BAC 2022 Subiectul III.3",
  "errorType": "Tip C",
  "bugDescription": "Am declarat un vector de 100.000 elemente depasind limita de memorie.",
  "patch": "Citeste secventa numar cu numar (while fin >> x) mentinand doar 2 variabile de contor.",
  "invariant": "Memorie O(1) inseamna spatiu constant indiferent de N."
}
```

Apoi, în **ApexTelemetry**, apasă pe butonul alb proeminent din partea de sus:
**„Paste AI Log din Clipboard”**.
Algoritmul inteligent de regex și fuzzy-matching va parsa automat toate câmpurile, va mapa subcategoria și va salva bug-ul instant, acompaniat de haptic feedback tactil.

---

## 🧠 Clasificarea Erorilor & Taxonomia Subcategoriilor

### Clasificare Erori (3 Culori OLED):
- **Tip A • Lacună Teoretică** (Violet `#A855F7`): Formulă, proprietate sau teoremă necunoscută.
- **Tip B • Eroare Mecanică de Calcul** (Chihlimbar `#F59E0B`): Semn greșit, neatenție la copiere, derivare greșită.
- **Tip C • Blocaj Euristic / Timp** (Roz/Roșu `#F43F5E`): Nerecunoașterea invariantului sau a metodei optime în 120 de secunde.

### Subcategorii Strict Integrate per Materie:
- **Matematică**:
  - `Analiză Matematică (Derivate, Integrale, Limite, Asimptote)`
  - `Algebră (Matrici, Determinanți, Grupuri, Inele Zn, Polinoame)`
  - `Geometrie & Trigonometrie (Vectori, Drepte, Ecuații Trigo)`
- **Informatică**:
  - `Algoritmică & Grafuri/Arbori (BFS, DFS, Arbori tați, Heap)`
  - `Șiruri de Caractere (cstring, char[], funcții C)`
  - `Eficiență Fișiere O(1) (Subiectul III.3 streaming)`
  - `C++ Low-Level & Sintaxă (Pointeri, Stivă, Operatori pe biți)`
- **Română**:
  - `Subiectul I (Text la prima vedere, argumentare B)`
  - `Subiectul II (Șabloane perspectivă, didascalii, idee poetică)`
  - `Subiectul III (Eseu canonic, structură, formule magice)`
- **Fizică**:
  - `Mecanică`
  - `Termodinamică`
  - `Curent Continuu`
  - `Optică`

---

## 🔒 Persistență & Siguranța Datelor la Re-semnare Certificat

- Toate datele sunt salvate în sandbox-ul aplicației (`Documents/bug_log.json`).
- În procesul de sideloading (prin FlareStore / Scarlet / SideStore), la expirarea certificatului gratuit de 7 zile sau schimbarea certificatului, datele din `Documents/` **rămân intacte** atât timp cât **Bundle ID-ul** (`com.apex.telemetry`) rămâne neschimbat.
- **Export & Import Rapid**: Din meniul de Setări (rotița din stânga sus), poți exporta oricând fișierul `bug_log.json` în Fișierele iOS, pe iCloud Drive sau prin WhatsApp/AirDrop.
- Dacă schimbi telefonul sau reinstalezi curat, folosești opțiunea **Importă Backup JSON** pentru a restaura instantaneu toate bug-urile și statisticile.

---

## 📐 Arhitectura Codului Sursă

```
ApexTelemetry/
├── App/
│   ├── ApexTelemetryApp.swift       # Entry-point SwiftUI, temă forțată OLED black
│   ├── Info.plist                   # Lock portret, suport documente & share
│   └── Assets.xcassets/             # Catalog resurse (AppIcon, AccentColor)
├── Models/
│   └── Models.swift                 # Subject, SubCategory taxonomy, ErrorType, BugEntry, TelemetryStats
├── Services/
│   ├── StorageManager.swift         # FileManager JSON atomic persistence (Documents/bug_log.json)
│   └── ClipboardParser.swift        # AI Regex & JSON smart parser cu fuzzy matching
├── ViewModels/
│   └── TelemetryViewModel.swift     # Coordonator MVVM, filtrare 2-tier, clipboard ingestion
└── Views/
    ├── Theme/
    │   └── Theme.swift              # Culori OLED #000000, #121215, haptics native UIKit
    ├── Dashboard/
    │   ├── DashboardView.swift      # Dashboard telemetrie, weekly bar, 2-tier filter chips
    │   └── BugCardView.swift        # Card cu tag subcategorie, patch terminal, invariant
    ├── Recall/
    │   └── ActiveRecallView.swift   # Mod Flashcard (Provocare -> Dezvăluire -> Evaluare)
    ├── Editor/
    │   └── ManualEntryView.swift    # Sheet editare cu picker dinamic de subcategorii
    └── Settings/
        └── SettingsView.swift       # Export/Import JSON (ShareLink, .fileImporter)
```
