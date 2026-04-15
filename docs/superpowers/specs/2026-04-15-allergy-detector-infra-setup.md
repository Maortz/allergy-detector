# Allergy Detector App – Infrastructure Setup Guide

## 1. Prerequisites
- **Flutter SDK**
  - [Install Flutter](https://docs.flutter.dev/get-started/install) (latest stable)
  - Ensure you can run: `flutter doctor`
- **Node.js/NPM** (if you use Supabase CLI or want fast tooling): [Install Node.js](https://nodejs.org/)
- **Supabase Account**
  - [Sign up at Supabase](https://app.supabase.com/)
  - Create new project (choose region close to users; name: `allergy-detector`)
- **Git**
  - [Install Git](https://git-scm.com/)
  - This repo is already initialized—commit changes as you go!

## 2. Setting up Flutter
```
git clone <repo-url>
cd allergy-detector
flutter pub get
flutter doctor
```

## 3. Setting up Supabase Backend
- Go to [Supabase dashboard](https://app.supabase.com/), **create a new project**
- Note your **Project URL** and **anon/public API key**
- Set up these tables:
  - `products` (see ER diagram for fields)
  - `brands`
  - `allergens`
  - `feedback_reports`
- Enable Row-Level Security on all tables (for open, anonymous access as per MVP, tighten later)
- (Optional) [Supabase CLI](https://supabase.com/docs/guides/cli): For local dev/emulation or migrations

## 4. Creating .env file
Create a `.env` file in the project root:
```
SUPABASE_URL=your-project-url-here
SUPABASE_PUBLIC_API_KEY=your-anon-key-here
```
Never commit real secrets—this file is for local dev!

## 5. Running the App
```
flutter run -d chrome  # For web demo
flutter run -d android  # For Android device/emulator
flutter run -d ios  # For iOS (on Mac)
```

## 6. Useful Links
- [Flutter Docs](https://docs.flutter.dev/)
- [Supabase Docs](https://supabase.com/docs)
- [Open Food Facts Data](https://world.openfoodfacts.org/data)

---
**Commit this guide to docs and update as infra changes!**
