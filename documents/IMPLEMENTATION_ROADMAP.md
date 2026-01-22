# Implementation Roadmap

**Repository:** [github.com/osho-zuco/rescue](https://github.com/osho-zuco/rescue)
**Product:** Paws - Map-first pet rescue platform
**Status:** Foundation complete, ready for development

---

## ✅ Completed (Setup Phase)

### Infrastructure
- [x] Git repository initialized
- [x] GitHub repo created and pushed
- [x] Project renamed from Druto → Rescue
- [x] Clean codebase (removed loyalty features)
- [x] Documentation structure

### Backend Foundation
- [x] Bun + Hono + Prisma setup
- [x] Database schema designed (Pet, User, PetStatusHistory)
- [x] OTP authentication (MSG91/Twilio)
- [x] Cloudinary image upload service
- [x] Firebase push notifications configured
- [x] JWT middleware
- [x] Error handling patterns
- [x] Result type pattern

### Flutter Foundation
- [x] rescue_core package structure
- [x] BLoC pattern setup (AuthBloc ready)
- [x] DioClient with auto-retry
- [x] Location services
- [x] FCM service for push notifications
- [x] Theme system
- [x] Reusable UI widgets
- [x] Phone/OTP login screens
- [x] Google Maps Flutter dependency

### Documentation
- [x] README.md with setup instructions
- [x] Product Requirements Document (PRD)
- [x] Database schema documented
- [x] .env.example for configuration
- [x] .gitignore properly configured

---

## 🎯 Next Steps (Development Phase)

### Priority 1: Backend API (Week 1)

#### Task 1.1: Pet Routes
**File:** `backend/src/routes/pets.ts`

Create endpoints:
```typescript
GET    /api/v1/pets/map         // Get pets for map bounds
POST   /api/v1/pets             // Report new pet
GET    /api/v1/pets/:id         // Get pet details
PATCH  /api/v1/pets/:id/status  // Update status
DELETE /api/v1/pets/:id         // Delete report
```

**Validation:**
- Photos required (min 1, max 5)
- Location within bounds
- Status transitions enforced
- Rate limiting (1 report per 5 mins)

**Files to create:**
- `backend/src/routes/pets.ts`
- `backend/src/lib/geolocation.ts` (distance calculations)

#### Task 1.2: Notification Service
**File:** `backend/src/services/notifications.ts`

Functions needed:
```typescript
sendRescueAlert(pet: Pet, nearbyUsers: User[])
sendAdoptionAlert(pet: Pet, subscribedUsers: User[])
sendSuccessStoryAlert(pet: Pet)
```

**Integration:**
- Use existing Firebase Admin SDK
- Filter by user preferences
- Include distance in rescue alerts
- Template messages for WhatsApp

#### Task 1.3: Update Index
**File:** `backend/src/index.ts`

Register new routes:
```typescript
import petsRouter from './routes/pets'
app.route('/api/v1/pets', petsRouter)
```

#### Task 1.4: Database Migration
```bash
cd backend
bun run db:migrate -- --name add_pet_rescue_models
```

**Verification:**
- Test all endpoints with Postman
- Verify push notifications send
- Check database constraints

---

### Priority 2: Flutter Models & Repositories (Week 2)

#### Task 2.1: Pet Model
**File:** `packages/rescue_core/lib/models/pet.dart`

```dart
class Pet {
  final String id;
  final String species;
  final List<String> photos;
  final PetStatus status;
  final double latitude;
  final double longitude;
  final String locationAddress;
  final String? distressNotes;
  final String? healthStatus;
  final String? rescuerPhone;
  // ... (see PRD)

  factory Pet.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}

enum PetStatus {
  helpNeeded,
  helpReached,
  searchingAdoption,
  adopted;

  Color get pinColor {
    switch (this) {
      case helpNeeded: return Colors.red;
      case searchingAdoption: return Colors.amber;
      case adopted: return Colors.green;
      default: return Colors.grey;
    }
  }
}
```

#### Task 2.2: Pet Repository
**File:** `packages/rescue_core/lib/repositories/pet_repository.dart`

```dart
class PetRepository {
  final DioClient _dio;

  Future<Result<List<Pet>, ApiError>> getPetsForMap({
    required LatLngBounds bounds,
    PetStatus? status,
    String? species,
  });

  Future<Result<Pet, ApiError>> getPetById(String id);

  Future<Result<Pet, ApiError>> reportPet(ReportPetRequest request);

  Future<Result<Pet, ApiError>> updateStatus(
    String id,
    UpdatePetStatusRequest request,
  );

  Future<Result<void, ApiError>> deletePet(String id);
}
```

#### Task 2.3: Update Service Locator
**File:** `packages/rescue_core/lib/di/service_locator.dart`

Register PetRepository:
```dart
getIt.registerLazySingleton<PetRepository>(
  () => PetRepository(dio: getIt<DioClient>()),
);
```

#### Task 2.4: Export in rescue_core
**File:** `packages/rescue_core/lib/rescue_core.dart`

```dart
export 'models/pet.dart';
export 'repositories/pet_repository.dart';
```

---

### Priority 3: Flutter BLoCs (Week 2)

#### Task 3.1: Pet BLoC
**Folder:** `packages/rescue_core/lib/bloc/pet/`

**Files:**
- `pet_bloc.dart`
- `pet_event.dart`
- `pet_state.dart`

**Events:**
```dart
sealed class PetEvent {}
class LoadPetsForMap extends PetEvent {
  final LatLngBounds bounds;
  final PetStatus? filterStatus;
  final String? filterSpecies;
}
class LoadPetDetails extends PetEvent {
  final String petId;
}
class UpdatePetStatus extends PetEvent {
  final String petId;
  final UpdatePetStatusRequest request;
}
```

**States:**
```dart
sealed class PetState {}
class PetInitial extends PetState {}
class PetsLoading extends PetState {}
class PetsLoaded extends PetState {
  final List<Pet> pets;
  final PetStatus? currentFilter;
}
class PetDetailsLoaded extends PetState {
  final Pet pet;
}
class PetError extends PetState {
  final String message;
}
```

#### Task 3.2: Report Pet BLoC
**Folder:** `packages/rescue_core/lib/bloc/report_pet/`

**Events:**
```dart
class PickPhotos extends ReportPetEvent {}
class DetectLocation extends ReportPetEvent {}
class UpdateLocation extends ReportPetEvent {
  final LatLng location;
}
class SubmitReport extends ReportPetEvent {
  final ReportPetRequest request;
}
```

**States:**
```dart
class ReportPetInitial extends ReportPetState {}
class PhotosPicked extends ReportPetState {
  final List<File> photos;
}
class LocationDetected extends ReportPetState {
  final LatLng location;
}
class UploadingReport extends ReportPetState {
  final double progress; // 0.0 to 1.0
}
class ReportSuccess extends ReportPetState {
  final Pet pet;
}
class ReportError extends ReportPetState {
  final String message;
}
```

---

### Priority 4: Flutter App Creation (Week 3)

#### Task 4.1: Create App
```bash
cd apps
flutter create rescue_app --org com.paws --platforms android,ios
cd rescue_app
```

#### Task 4.2: Add Dependencies
**File:** `apps/rescue_app/pubspec.yaml`

```yaml
name: rescue_app
description: Paws - Pet Rescue Platform

dependencies:
  flutter:
    sdk: flutter

  # Shared package
  rescue_core:
    path: ../../packages/rescue_core

  # State management
  flutter_bloc: ^9.0.0

  # DI
  get_it: ^8.0.0

  # Routing
  go_router: ^14.2.0

  # Maps
  google_maps_flutter: ^2.5.0

  # UI
  cached_network_image: ^3.4.0
```

#### Task 4.3: App Structure
```
apps/rescue_app/lib/
├── main.dart
├── app.dart
├── core/
│   ├── router.dart
│   ├── theme.dart
│   └── di.dart
└── features/
    ├── map/
    │   ├── map_screen.dart
    │   ├── widgets/
    │   │   ├── pet_pin.dart
    │   │   └── pet_details_sheet.dart
    │   └── map_bloc.dart
    ├── report/
    │   ├── report_pet_screen.dart
    │   └── widgets/
    │       ├── photo_picker.dart
    │       └── location_picker.dart
    └── settings/
        └── settings_screen.dart
```

---

### Priority 5: Map Screen (Week 3-4)

#### Task 5.1: Main Map Screen
**File:** `apps/rescue_app/lib/features/map/map_screen.dart`

```dart
class MapScreen extends StatefulWidget {
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Pet? _selectedPet;
  PetStatus _currentTab = PetStatus.helpNeeded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(12.9716, 77.5946), // Bangalore
              zoom: 12,
            ),
            markers: _buildMarkers(),
            onTap: (_) => setState(() => _selectedPet = null),
          ),

          // Top filter bar
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: _buildFilterChips(),
          ),
        ],
      ),

      // Bottom sheet
      bottomSheet: _selectedPet != null
          ? PetDetailsSheet(pet: _selectedPet!)
          : null,

      // FAB
      floatingActionButton: _currentTab != PetStatus.adopted
          ? FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () => context.push('/report'),
            )
          : null,

      // Bottom tabs
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: _onTabChanged,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Rescue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Adoption',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.celebration),
            label: 'Success',
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    // Build markers from PetBloc state
  }
}
```

#### Task 5.2: Pet Pin Widget
**File:** `apps/rescue_app/lib/features/map/widgets/pet_pin.dart`

Custom marker with status color:
```dart
Future<BitmapDescriptor> createCustomPin(PetStatus status) async {
  // Create colored pin marker
  // Red for helpNeeded, Yellow for searchingAdoption, Green for adopted
}
```

#### Task 5.3: Pet Details Sheet
**File:** `apps/rescue_app/lib/features/map/widgets/pet_details_sheet.dart`

```dart
class PetDetailsSheet extends StatelessWidget {
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Photo gallery
              PhotoGallery(photos: pet.photos),

              // Status badge
              StatusChip(status: pet.status),

              // Details
              Text('Posted ${timeAgo(pet.reportedAt)}'),
              Text('${distance(pet)} km away'),

              // Notes
              Text(pet.distressNotes ?? pet.adoptionNotes ?? ''),

              // Contact button
              if (pet.rescuerPhone != null)
                ElevatedButton.icon(
                  icon: Icon(Icons.message),
                  label: Text('Contact Rescuer'),
                  onPressed: () => _openWhatsApp(pet.rescuerPhone!),
                ),

              // Status update button (if authorized)
              if (_canUpdateStatus(pet))
                OutlinedButton(
                  child: Text('Mark Help Reached'),
                  onPressed: () => _showStatusUpdateDialog(),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openWhatsApp(String phone) {
    final message = Uri.encodeComponent(
      "Hi! I saw your rescue alert on Paws for the ${pet.species}. "
      "Can I help?"
    );
    final url = "https://wa.me/$phone?text=$message";
    launchUrl(Uri.parse(url));
  }
}
```

---

### Priority 6: Report Flow (Week 4)

#### Task 6.1: Report Pet Screen
**File:** `apps/rescue_app/lib/features/report/report_pet_screen.dart`

Multi-step form:
1. Photo picker (camera/gallery)
2. Location picker (auto-detect + drag pin)
3. Species selector
4. Notes input
5. Submit

#### Task 6.2: Photo Picker Widget
Uses ImagePickerService from rescue_core

#### Task 6.3: Location Picker Widget
Uses LocationService + Google Maps

---

### Priority 7: Push Notifications (Week 5)

#### Task 7.1: FCM Setup
- Configure Firebase project
- Add google-services.json (Android)
- Add GoogleService-Info.plist (iOS)
- Request notification permissions

#### Task 7.2: Notification Handling
**File:** `apps/rescue_app/lib/core/notifications.dart`

```dart
class NotificationHandler {
  static void initialize() {
    FirebaseMessaging.onMessage.listen(_handleForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackground);
  }

  static void _handleForeground(RemoteMessage message) {
    // Show in-app notification
  }

  static void _handleBackground(RemoteMessage message) {
    // Navigate to pet details
    final petId = message.data['petId'];
    router.push('/pets/$petId');
  }
}
```

#### Task 7.3: Settings Screen
**File:** `apps/rescue_app/lib/features/settings/settings_screen.dart`

Notification preferences:
- Enable rescue alerts
- Enable adoption alerts
- Enable success stories
- Rescue radius slider (1-10km)

---

### Priority 8: Testing & Polish (Week 6)

#### Task 8.1: Error Handling
- Network errors → retry UI
- Location permission denied → fallback
- Image upload failed → show error + retry
- Empty states for each map view

#### Task 8.2: Loading States
- Shimmer for loading pets
- Progress indicator for report upload
- Skeleton for pet details

#### Task 8.3: E2E Testing
Test flows:
1. Report rescue → Verify push notification sent
2. Mark help reached → Verify pin color changes
3. Contact rescuer → Verify WhatsApp opens
4. Filter by species → Verify only filtered pins shown

---

## 🚀 Launch Checklist (Week 7-8)

### Pre-Launch
- [ ] Set up PostgreSQL database (Railway)
- [ ] Deploy backend to Railway
- [ ] Configure environment variables
- [ ] Run database migrations
- [ ] Set up Firebase project
- [ ] Configure Cloudinary account
- [ ] Set up MSG91 for OTP
- [ ] Test push notifications end-to-end

### Beta Testing
- [ ] TestFlight/Internal testing build
- [ ] Recruit 10 beta testers from rescue community
- [ ] Collect feedback
- [ ] Fix critical bugs
- [ ] Monitor analytics

### Launch
- [ ] App Store submission (iOS)
- [ ] Play Store submission (Android)
- [ ] Create landing page
- [ ] Prepare launch post for WhatsApp groups
- [ ] Reach out to rescue group admins
- [ ] Launch PR/social media

---

## 📊 Post-Launch Monitoring

### Metrics to Track
- Daily/Weekly/Monthly Active Users
- Reports per week
- Adoption success rate
- Notification engagement rate
- WhatsApp contact tap rate
- App crashes/errors (Sentry)

### Iterate Based On
- User feedback
- Completion rates for each flow
- Drop-off points
- Feature requests
- Bug reports

---

## 🔮 Future Roadmap (Post-MVP)

### Phase 2: Enhanced Discovery
- Advanced filters (age, size, temperament)
- Pet matching algorithm
- Saved searches
- Foster-to-adopt pipeline

### Phase 3: Community Features
- User profiles with rescue stats
- Badges and reputation
- Volunteer coordination
- Rescue organization profiles

### Phase 4: Support Features
- Vet coordination
- Medical records tracking
- Donation integration
- Fundraising for specific pets

### Phase 5: Zuco Integration
- Post-adoption check-ins
- Zuco boarding promo notifications
- Loyalty rewards for Paws users
- Cross-platform user sync

---

## Quick Commands Reference

```bash
# Backend
cd backend
bun install
bun run docker:up        # Start Postgres
bun run db:generate      # Generate Prisma client
bun run db:migrate       # Run migrations
bun run dev              # Start dev server

# Flutter Core
cd packages/rescue_core
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Flutter App
cd apps/rescue_app
flutter pub get
flutter run

# Git
git add .
git commit -m "feat: your message"
git push
```

---

**Last Updated:** January 23, 2026
**Current Status:** ✅ Foundation Complete → 🚧 Ready for Development
