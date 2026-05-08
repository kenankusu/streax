# Streax

Streax ist eine mobile Sport-Tracking-App mit Social-Media-Funktionen, die es Benutzern ermöglicht, sportlichen Aktivitäten zu dokumentieren, individuelle Trainingsziele zu verfolgen und Erfolge mit Freunden zu teilen. Die App kombiniert klassische Fitness-Tracking-Funktionen mit Gamification-Elementen wie eine Streak. Eine integrierte soziale Komponente erlaubt es, Beiträge zu posten und die von Freunden anzusehen. 

# Anleitung: Flutter-Projekt in VS Code starten

## 1. Voraussetzungen installieren

1. **Flutter SDK**  
   Lade das SDK herunter und füge es Deinem PATH hinzu:  
   - Windows: [Flutter installieren](https://docs.flutter.dev/get-started/install/windows)  
   - macOS: [Flutter installieren](https://docs.flutter.dev/get-started/install/macos)  
   - Linux: [Flutter installieren](https://docs.flutter.dev/get-started/install/linux)

   Tipps zum einfügen im PATH (Windows) [Flutter Dev](https://docs.flutter.dev/install/add-to-path)

2. **VS Code Extensions**  
   Öffne in VS Code den Extensions-Tab (⇧ ⌘ X bzw. Strg ⇧ X) und installiere:  
   - **Dart**  
   - **Flutter**  

---

## 2. Repository klonen

Öffne ein Terminal und führe aus:

```bash
git clone https://github.com/kenankusu/streax.git
cd streax
````

---

## 3. Abhängigkeiten installieren

Im Projektordner:

```bash
flutter pub get
```

Damit werden alle in der `pubspec.yaml` definierten Pakete heruntergeladen.

---

## 4. Geräte prüfen und Browser-Emulation

1. **Systemcheck**

   ```bash
   flutter doctor
   flutter devices
   ```

   * `flutter doctor` weist auf fehlende Komponenten hin.
   * `flutter devices` zeigt verfügbare Devices zur Emulation.

---

## 5. Projekt in VS Code öffnen

1. **File → Open Folder…**
2. Wähle deinen lokalen `streax`-Ordner aus.

---

## 6. App starten

1. Unten rechts in der Statusleiste das gewünschte Ziel wählen:

   * **Chrome** oder ein anderes Web-Device
     
2. Kommando-Palette öffnen (⇧ ⌘ P bzw. Strg ⇧ P) → `Flutter: Run Flutter App` oder drücke **F5**.

---

## 7. Hot Reload / Hot Restart

* **Hot Reload**: Drücke `r` im Terminal oder klicke im Debug-Panel auf den Reload-Button.

---

## 8. Fehlerbehebung

Falls beim installieren oder in der runtime Fehler bestehen, können diese Optionen helfen:

* **Abhängigkeiten aktualisieren**

  ```bash
  flutter pub upgrade
  ```
* **Projekt bereinigen**

  ```bash
  flutter clean
  flutter pub get
  ```
* **Ausführliche Logs**

  ```bash
  flutter run -v
  ```

---

