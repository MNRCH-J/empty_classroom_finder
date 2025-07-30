# 📚 Empty Classroom Finder App (Flutter)

A modern Flutter application built to help students at SRM Ramapuram quickly find unoccupied classrooms based on timetable data.

---

## ✨ Features

- 🔐 **Login Screen** – Secure entry with username/password
- 🗓️ **Weekday Selector** – View timetables for Monday to Friday
- 📊 **Timetable Viewer** – Loads from CSV files
- 🔍 **Search Function**:
  - Find **free classrooms** by time
  - View **availability of specific classrooms**
- 🎨 **Color Coding**:
  - 🟩 Green: Free
  - 🟥 Red: Occupied
  - 🟨 Yellow: Booked by user
- 💬 **Hover Tooltips** – Show class, subject, and mentor info
- 💾 **Persistent Bookings** – Book and store reservations using Hive
- ⚡ **Fuzzy Search Support** – Handles minor typos in classroom names

---

## 🧱 Tech Stack

- **Flutter** + **Dart**
- **Hive** for local storage
- **CSV** for timetable data
- **VS Code** / **Android Studio** for development

---

## 📂 Folder Structure

empty_classroom_finder/
├── lib/
│ └── main.dart
├── assets/
│ └── (images/fonts if any)
├── *.csv # Timetable files (Day1_timetable.csv, etc.)
├── pubspec.yaml
└── README.md

yaml
---

## 🛠️ How to Run

1. Clone the repository:
   ```bash
   git clone https://github.com/MNRCH-J/empty_classroom_finder.git
   cd empty_classroom_finder

Get Flutter packages:
  flutter pub get
Run the app:
  flutter run
Make sure you have Flutter SDK installed and a device/emulator connected.
