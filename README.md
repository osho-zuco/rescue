# 🐾 Rescue - Pet Rescue Platform

A non-profit mobile app to help rescue and rehome stray animals. Built with Flutter and Bun.

## Overview

**Rescue** connects people who find animals in distress with rescuers and potential adopters. The app enables:

- **Report** - Anyone can report an animal needing help with photos and location
- **Rescue** - Volunteers receive alerts and can mark when they've reached the animal
- **Adopt** - Once rescued, animals are listed for adoption with health details
- **Celebrate** - Success stories of adopted pets inspire the community

## Tech Stack

### Backend
- **Runtime**: Bun
- **Framework**: Hono
- **Database**: PostgreSQL + Prisma ORM
- **Auth**: Custom OTP (MSG91)
- **Images**: Cloudinary
- **Notifications**: Firebase Cloud Messaging
- **Deployment**: Railway

### Flutter App
- **State Management**: BLoC
- **DI**: get_it + injectable
- **Routing**: go_router
- **Location**: geolocator + Google Maps
- **Storage**: shared_preferences + flutter_secure_storage

## Project Structure

```
rescue/
├── backend/              # Bun + Hono + Prisma API
│   ├── src/
│   │   ├── routes/      # API endpoints
│   │   ├── services/    # Business logic
│   │   └── lib/         # Utilities
│   └── prisma/
│       └── schema.prisma # Database schema
│
├── packages/
│   └── rescue_core/     # Shared Flutter package
│       ├── lib/
│       │   ├── bloc/    # State management
│       │   ├── models/  # Data models
│       │   ├── repositories/ # API clients
│       │   ├── services/ # Platform services
│       │   ├── theme/   # App styling
│       │   └── widgets/ # Reusable UI
│       └── pubspec.yaml
│
└── apps/
    └── rescue_app/      # Main Flutter app (to be created)
```

## Getting Started

### Prerequisites

- [Bun](https://bun.sh) v1.0+
- [Flutter](https://flutter.dev) v3.6+
- [PostgreSQL](https://www.postgresql.org) v15+
- [Docker](https://www.docker.com) (optional, for local Postgres)

### Backend Setup

1. **Install dependencies**:
   ```bash
   cd backend
   bun install
   ```

2. **Setup database** (using Docker):
   ```bash
   bun run docker:up
   ```

3. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your credentials
   ```

4. **Run migrations**:
   ```bash
   bun run db:generate
   bun run db:migrate
   ```

5. **Start dev server**:
   ```bash
   bun run dev
   ```

API will be available at `http://localhost:3000`

### Flutter Setup

1. **Install dependencies**:
   ```bash
   cd packages/rescue_core
   flutter pub get
   ```

2. **Generate code** (for BLoC, models):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **Create the main app** (coming soon):
   ```bash
   cd apps
   flutter create rescue_app
   ```

## Database Schema

### User
- `phone` (unique, for OTP auth)
- `name`, `profilePhotoUrl`
- `notifyRescue`, `notifyAdoption`, `notifySuccess` (notification preferences)

### Pet
- `species`, `breed`, `age`, `gender`
- `latitude`, `longitude`, `locationAddress`
- `status`: HELP_NEEDED → HELP_REACHED → SEARCHING_ADOPTION → ADOPTED
- `photos[]` (Cloudinary URLs)
- `reportedById`, `rescuedById`, `adoptedById`
- `healthStatus`, `temperament`, `adoptionNotes`
- `rescuerPhone`, `adopterPhone` (for coordination)

### PetStatusHistory
- Audit trail of status changes

## API Endpoints

### Authentication
- `POST /api/v1/auth/otp/send` - Send OTP
- `POST /api/v1/auth/otp/verify` - Verify OTP, get JWT

### Pets
- `POST /api/v1/pets` - Report new pet
- `GET /api/v1/pets` - List pets (with filters)
- `GET /api/v1/pets/:id` - Get pet details
- `PATCH /api/v1/pets/:id/status` - Update status
- `DELETE /api/v1/pets/:id` - Delete report

### Users
- `PATCH /api/v1/users/me/notifications` - Update notification preferences
- `GET /api/v1/users/me/pets` - Get user's reported/rescued/adopted pets

## App Flow

### 1. RESCUE TAB 🚨
- User sees animal in distress
- Opens app → Takes photos → Marks location
- Status: "Help Needed"
- **Push notification** sent to nearby users
- Rescuer goes to location → Marks "Help Reached"
- Auto-moves to Adoption tab

### 2. ADOPTION TAB 🏠
- Status: "Searching Adoption"
- Rescuer adds health info, temperament, adoption notes
- **Push notification** sent to adoption subscribers
- Adopter taps "Get Rescuer's Phone"
- Coordinates via call/WhatsApp
- Rescuer marks "Adopted"
- Auto-moves to Happy Moments tab

### 3. HAPPY MOMENTS TAB ✨
- Status: "Success"
- Before/after photos
- Success story
- Public celebration feed

## Environment Variables

### Backend (.env)
```env
DATABASE_URL="postgresql://..."
JWT_SECRET="..."
OTP_PROVIDER="msg91"
MSG91_AUTH_KEY="..."
FIREBASE_PROJECT_ID="..."
FIREBASE_PRIVATE_KEY="..."
FIREBASE_CLIENT_EMAIL="..."
CLOUDINARY_CLOUD_NAME="..."
CLOUDINARY_API_KEY="..."
CLOUDINARY_API_SECRET="..."
```

### Flutter
```dart
// lib/config/env_config.dart
API_BASE_URL="https://api.rescue.app"
GOOGLE_MAPS_API_KEY="..."
```

## Deployment

### Backend (Railway)
```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Link project
railway link

# Deploy
railway up
```

### Flutter (Google Play / App Store)
```bash
# Android
flutter build appbundle --release

# iOS
flutter build ipa --release
```

## Contributing

This is a non-profit project. Contributions are welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT

## Contact

For questions or support, please open an issue on GitHub.

---

🐾 Built with ❤️ for animal welfare
