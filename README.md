# 📱 Task Management App

> Aplikasi manajemen tugas dengan sistem autentikasi dan role-based access yang dikembangkan dengan Flutter untuk Tes Kompetensi Mobile Programming - Thursina Tech

## 📋 Deskripsi

Task Management App adalah aplikasi mobile full-stack yang memungkinkan pengguna (Siswa dan Guru) untuk mengelola tugas dengan fitur lengkap CRUD (Create, Read, Update, Delete). Aplikasi ini dilengkapi sistem autentikasi JWT dan role-based access control, terintegrasi dengan custom REST API backend.

## ✨ Fitur

### 🔐 **Authentication System**
- **JWT Authentication** - Sistem login dengan token security
- **Role-Based Access** - Akses berbeda untuk Siswa dan Guru
- **Secure Login** - Validasi credential dengan encryption

### 👨‍🎓 **Fitur Siswa**
- 📝 **Melihat Daftar Tugas** - View tugas yang diberikan guru
- 📤 **Submit Tugas** - Upload hasil pengerjaan tugas
- 📊 **Status Submission** - Melihat status pengumpulan tugas

### 👨‍🏫 **Fitur Guru**
- ➕ **Membuat Tugas Baru** - Create tugas untuk siswa
- ✏️ **Edit Tugas** - Update detail tugas yang sudah ada
- 🗑️ **Hapus Tugas** - Delete tugas yang tidak diperlukan
- 📋 **Kelola Submission** - Melihat hasil pengumpulan siswa
- 📊 **Dashboard Management** - Overview manajemen tugas

## 🛠️ Teknologi yang Digunakan

### **Backend**
- **Node.js** - Runtime Environment
- **Express.js** - Web Framework
- **JWT** - Authentication
- **Swagger** - API Documentation
- **MongoDB/PostgreSQL** - Database

### **Frontend**
- **Flutter** 3.x - UI Framework
- **Dart** - Programming Language
- **Provider** - State Management
- **HTTP** - API Integration
- **SharedPreferences** - Local Storage

## 🚀 Instalasi dan Setup

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK
- Android Studio / VS Code
- Git

### Langkah Instalasi

1. **Clone repository**
   ```bash
   git clone https://github.com/Heri2803/mobile-apps-test.git
   cd mobile-apps-test
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi**
   ```bash
   flutter run
   ```

## 🗂️ Struktur Project

```
project_root/
├── backend/                 # Express.js API Server
│   ├── app.js              # Entry point server
│   ├── routes/             # API routes
│   ├── models/             # Database models
│   ├── middleware/         # Auth middleware
│   └── swagger.json        # API documentation
└── frontend/               # Flutter Application
    ├── lib/
    │   ├── main.dart       # Entry point aplikasi
    │   ├── models/
    │   │   ├── task_model.dart
    │   │   └── user_model.dart
    │   ├── services/
    │   │   ├── api_service.dart
    │   │   ├── auth_service.dart
    │   │   └── task_repository.dart
    │   ├── providers/
    │   │   ├── auth_provider.dart
    │   │   └── task_provider.dart
    │   ├── screens/
    │   │   ├── home_screen.dart
    │   │   ├── login_screen.dart
    │   │   ├── student_dashboard.dart
    │   │   ├── teacher_dashboard.dart
    │   │   └── task_screens/
    │   └── widgets/
    │       ├── task_item.dart
    │       ├── login_form.dart
    │       └── loading_widget.dart
    └── pubspec.yaml
```

## 🔌 API Backend Integration

**Custom REST API** dibangun dengan **Express.js + Node.js**

**Base URL:** `http://localhost:5000`  
**Swagger Documentation:** `http://localhost:5000/api-docs`

### 🚀 Cara Menjalankan Backend API

#### 1. **Setup Backend Server**
```bash
# Pindah ke folder backend
cd backend

# Jalankan server (pilih salah satu)
nodemon app.js
# atau
node app.js
```

#### 2. **Akses Swagger UI**
Setelah server berjalan, buka browser dan akses:
```
📑 Swagger UI available at http://localhost:5000/api-docs
```

### 🔐 Test Account Credentials

| Role | NIP | Password | Keterangan |
|------|-----|----------|------------|
| Siswa | `654321` | `siswa123` | Akses endpoint dengan role siswa |
| Siswa | `09876` | `heri123` | Akses endpoint dengan role siswa |
| Guru | `123456` | `guru123` | Akses endpoint dengan role guru |

### 🔑 Autentikasi API (Swagger)

#### **Langkah Login & Authorization:**

1. **Login via Swagger:**
   - Buka endpoint **Auth API → Login**
   - Klik **"Try it out"**
   - Edit value dengan salah satu account di atas:
   ```json
   {
     "nip": "654321",
     "password": "siswa123"
   }
   ```
   - Klik **"Execute"**

2. **Copy Token:**
   - Dari response, salin **token** yang diberikan

3. **Authorize:**
   - Klik icon **🔒 Authorize** (pojok kanan atas)
   - Paste token ke field authorization
   - Klik **"Authorize"**

4. **Testing Endpoints:**
   - Sekarang bisa akses endpoint **Tasks** dan **Task Submission**
   - Semua request akan menggunakan token yang sudah diauthorize

### 📋 Available Endpoints

| Method | Endpoint | Deskripsi | Role Required |
|--------|----------|-----------|---------------|
| POST | `/auth/login` | Login user | Public |
| GET | `/tasks` | Mengambil semua tugas | Siswa/Guru |
| POST | `/tasks` | Menambahkan tugas baru | Guru |
| PUT | `/tasks/:id` | Mengubah tugas | Guru |
| DELETE | `/tasks/:id` | Menghapus tugas | Guru |
| GET | `/tasksubmission` | Mengambil submission | Siswa/Guru |
| POST | `/tasksubmission` | Submit tugas | Siswa |

### ⚠️ Catatan Penting
- **Wajib login terlebih dahulu** untuk mengakses endpoint Tasks dan Task Submission
- **Token harus ditambahkan** di Authorize sebelum testing endpoint lainnya
- **Role-based access** - pastikan menggunakan account sesuai role yang dibutuhkan

## 📱 Cara Menjalankan Aplikasi Flutter

### 🚀 Setup & Run Frontend

#### 1. **Pastikan Backend Server Sudah Berjalan**
Lihat langkah di atas untuk menjalankan backend API terlebih dahulu.

#### 2. **Jalankan Flutter App**
```bash
# Buka terminal baru (jangan tutup terminal backend)
# Pindah ke folder frontend
cd frontend

# Install dependencies (jika belum)
flutter pub get

# Jalankan aplikasi
flutter run
```

### 🏠 Navigation Flow Aplikasi

#### **Home Screen**
Setelah aplikasi berjalan, akan ditampilkan halaman **Home** dengan pilihan:
- 🎓 **Student Page** → Halaman login untuk siswa
- 👨‍🏫 **Teacher Page** → Halaman login untuk guru

### 🔐 Login Credentials

Gunakan account berikut untuk testing aplikasi:

#### **👨‍🎓 Login Siswa:**
| NIP | Password | Role |
|-----|----------|------|
| `654321` | `siswa123` | Siswa |
| `09876` | `heri123` | Siswa |

#### **👨‍🏫 Login Guru:**
| NIP | Password | Role |
|-----|----------|------|
| `123456` | `guru123` | Guru |

### 🛠️ Testing Flow

1. **Pilih Role:**
   - Klik **"Student Page"** untuk login sebagai siswa
   - Klik **"Teacher Page"** untuk login sebagai guru

2. **Login:**
   - Masukkan NIP dan Password sesuai table di atas
   - Klik tombol Login

3. **Explore Features:**
   - **Siswa:** Dapat melihat tugas, submit tugas
   - **Guru:** Dapat membuat tugas, edit tugas, melihat submission

### 📋 Fitur Berdasarkan Role

#### **🎓 Fitur Siswa:**
- ✅ Melihat daftar tugas
- ✅ Submit tugas (task submission)
- ✅ Melihat status submission

#### **👨‍🏫 Fitur Guru:**
- ✅ Melihat semua tugas
- ✅ Membuat tugas baru
- ✅ Edit/Update tugas
- ✅ Hapus tugas
- ✅ Melihat semua submission siswa

### ⚡ Quick Start Command

```bash
# Terminal 1 - Backend
cd backend && nodemon app.js

# Terminal 2 - Frontend (terminal baru)
cd frontend && flutter run
```

## 🧪 Testing

### 🔧 Backend API Testing
```bash
# Test dengan Swagger UI
# Akses: http://localhost:5000/api-docs

# Atau test dengan curl
curl -X POST http://localhost:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"nip":"654321","password":"siswa123"}'
```

### 📱 Flutter App Testing
```bash
# Unit tests
flutter test

# Integration tests
flutter drive --target=test_driver/app.dart

# Widget tests
flutter test test/widget_test.dart
```

### 🔐 Manual Testing Flow

1. **Test Authentication:**
   - Login dengan account siswa
   - Login dengan account guru
   - Test invalid credentials

2. **Test CRUD Operations:**
   - **Guru:** Create, Read, Update, Delete tasks
   - **Siswa:** Read tasks, Submit task submission

3. **Test Role-based Access:**
   - Siswa tidak bisa create/edit/delete tasks
   - Guru bisa akses semua fitur

## 📦 Build & Deploy

### Android APK
```bash
flutter build apk --release
```

### iOS App
```bash
flutter build ios --release
```

## 🔧 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5
  http: ^1.1.0
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

## 🏗️ Arsitektur

Aplikasi menggunakan **Clean Architecture** dengan pola:
- **Presentation Layer**: UI Components & Screens
- **Business Logic Layer**: State Management & Use Cases  
- **Data Layer**: Models & API Services

## 🌟 Fitur Khusus

- **Local State Simulation**: Karena menggunakan JSONPlaceholder (API dummy), perubahan data disimulasikan secara lokal untuk pengalaman pengguna yang konsisten
- **Error Handling**: Penanganan error yang komprehensif untuk network issues
- **Loading States**: Indikator loading untuk semua operasi async
- **Confirmation Dialogs**: Dialog konfirmasi untuk aksi penting seperti menghapus tugas

## 🚨 Troubleshooting

### Issue: Tidak bisa mengambil data dari API
**Solusi:**
- Pastikan koneksi internet aktif
- Check firewall atau proxy settings
- Verifikasi URL endpoint API

### Issue: UI tidak update setelah operasi CRUD
**Solusi:**
- Pastikan `notifyListeners()` dipanggil di Provider
- Check context Provider yang digunakan

## 📝 Todo List

- [ ] Add search functionality
- [ ] Implement offline storage
- [ ] Add task categories
- [ ] Dark mode support
- [ ] Push notifications

## 👨‍💻 Developer

**Nama:** [Nama Anda]  
**Email:** [email@example.com]  
**LinkedIn:** [linkedin.com/in/username]  
**GitHub:** [github.com/username]

## 📄 Lisensi

Distributed under the MIT License. See `LICENSE` for more information.

## 🙏 Acknowledgments

- [Flutter Documentation](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider) untuk state management
- Thursina Tech untuk kesempatan tes kompetensi ini

---

<div align="center">
  <p>Made with ❤️ for Thursina Tech</p>
  <p>© 2024 [Nama Anda]. All rights reserved.</p>
</div>