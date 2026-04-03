# Tracker – Stop the Bleeding!

Fixkosten-App für Flutter. Eine Datei, eine Tabelle, kein Overhead.

---

## Flutter-Pakete

Folgende Pakete in `pubspec.yaml` unter `dependencies` eintragen:

```yaml
dependencies:
   flutter:
      sdk: flutter
   sqflite: ^2.3.3
   path: ^1.9.0
```

Dann:

```bash
flutter pub get
```

---

## Was du noch tun musst

### 1. App-Icon

Das Standard-Flutter-Icon ist gesetzt. Da du ein anderes willst:

- Einfachste Lösung: Paket `flutter_launcher_icons` verwenden.
- Lege ein PNG (min. 1024×1024px) ab, z. B. `assets/icon/icon.png`.
- In `pubspec.yaml` ergänzen:

```yaml
dev_dependencies:
   flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
   android: true
   ios: true
   image_path: "assets/icon/icon.png"
```

Dann:

```bash
dart run flutter_launcher_icons
```

Ein komplett weißes PNG reicht – Hauptsache nicht Flutter-Standard.

---

### 2. App-Name

In `android/app/src/main/AndroidManifest.xml`:

```xml
android:label="Tracker"
```

In `ios/Runner/Info.plist`:

```xml
<key>CFBundleDisplayName</key>
<string>Tracker</string>
```

---

### 3. Android – minimale SDK-Version

In `android/app/build.gradle`:

```gradle
minSdkVersion 21
```

sqflite benötigt mindestens SDK 21.

---

## Datenbank

- **Datei:** `tracker.db` im App-Dokumente-Verzeichnis (automatisch angelegt)
- **Tabelle:** `fixkosten` (id, name, description, amount, interval)
- **View:** `v_summary` – aggregierte Monatssummen je Intervall-Bucket (optional, wird beim ersten Start erstellt)

---

## Architektur

Alles in `main.dart`, bewusst flach gehalten:

| Klasse          | Zweck                                                    |
| --------------- | -------------------------------------------------------- |
| `DB`            | SQLite-Singleton, alle Datenbankoperationen              |
| `Fixkosten`     | Datenmodell + Normalisierungslogik                       |
| `AppState`      | ChangeNotifier, hält die Liste im Speicher               |
| `HomeShell`     | BottomNavigationBar, wechselt zwischen den zwei Seiten   |
| `DashboardPage` | 6 KPI-Cards, kein Pull-to-Refresh nötig (live via State) |
| `ListPage`      | Scrollbare Liste, Edit/Delete via PopupMenu              |
| `EntrySheet`    | BottomSheet für Neu-/Bearbeiten                          |

---

## KPIs auf dem Dashboard

| KPI                  | Erklärung                                                           |
| -------------------- | ------------------------------------------------------------------- |
| Monatliche Belastung | Alle Posten normalisiert auf Monat (Jahresbetrag ÷ 12, Quartal ÷ 3) |
| Jährliche Belastung  | Normalisierter Monatswert × 12                                      |
| Monatliche Posten    | Rohsumme aller Einträge mit Intervall „Monatlich"                   |
| Quartalsposten       | Rohsumme aller Einträge mit Intervall „Quartalsweise"               |
| Jahresposten         | Rohsumme aller Einträge mit Intervall „Jährlich"                    |
| Einträge gesamt      | Anzahl aktiver Fixkostenposten                                      |

---

## Bekannte Einschränkungen / spätere Todos

- iOS benötigt keine weiteren Permissions für sqflite.
- Kein Export, kein Backup – bewusst weggelassen.
- Das App-Icon muss manuell gesetzt werden (siehe oben).
