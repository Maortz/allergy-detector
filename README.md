# Allergy Detector App Infrastructure Setup

This project uses Flutter for front-end and Supabase for backend as described in the documentation.

## Getting Started

### 1. Prerequisites
- Flutter SDK: [Install Flutter](https://docs.flutter.dev/get-started/install)
- Supabase Account: [Supabase Signup](https://app.supabase.com/)
- Node.js (for Supabase CLI and some tooling): [Install Node.js](https://nodejs.org/)
- Git: [Install Git](https://git-scm.com/)

### 2. Clone & Environment Setup
```
git clone <repo-url>
cd allergy-detector
```
- Copy `.env.example` to `.env` and fill in your Supabase URL and public API key. Never commit `.env`!

### 3. Flutter
```
flutter pub get
flutter doctor
```

### 4. Supabase Backend
- Go to the [Supabase dashboard](https://app.supabase.com/project/fxtdpzdzdiseabxteokd)
- Set up tables as described in `/docs/superpowers/specs/2026-04-15-allergy-detector-design-assets/er-diagram.md`
- Enable Row-Level Security for MVP (fine-tune later)

### 5. Running the App
```
flutter run -d chrome      # For web 
flutter run -d android     # For Android
device/emulator
flutter run -d ios         # For iOS (Mac only)
```

---
## Documentation
Full design/spec and assets are in `docs/superpowers/specs/`.
Infra setup: `docs/superpowers/specs/2026-04-15-allergy-detector-infra-setup.md`

---
