# 🚀 2-Day MVP Sprint Checklist

**Goal:** Ship a working map-first pet rescue app to the community
**Philosophy:** No feature creep. Just 3 tabs. Solid foundation.
**Timeline:** 48 hours

---

## Day 1: Backend + Flutter Foundation (12 hours)

### Morning (6 hours) - Backend API

#### ✅ Setup (30 mins)
- [ ] Install backend dependencies: `cd backend && bun install`
- [ ] Start Postgres: `bun run docker:up`
- [ ] Run migrations: `bun run db:migrate`
- [ ] Verify Prisma client: `bun run db:generate`
- [ ] Test auth endpoint: `POST /api/v1/auth/otp/send`

#### 🐾 Pet Routes (3 hours)
**File:** `backend/src/routes/pets.ts`

- [ ] Create `GET /api/v1/pets/map` endpoint
  - Query params: `bounds`, `status`, `species`
  - Return pets within map bounds
  - Include distance calculation

- [ ] Create `POST /api/v1/pets` endpoint
  - Body: photos, location, species, notes
  - Validate: min 1 photo, valid location
  - Create Pet record
  - Return created pet

- [ ] Create `GET /api/v1/pets/:id` endpoint
  - Return full pet details
  - Include reporter/rescuer info

- [ ] Create `PATCH /api/v1/pets/:id/status` endpoint
  - Validate status transitions
  - Update pet status + additional fields
  - Create PetStatusHistory record

- [ ] Register routes in `backend/src/index.ts`

#### 📱 Push Notifications (1.5 hours)
**File:** `backend/src/services/notifications.ts`

- [ ] Create `sendRescueAlert(pet, nearbyUsers)` function
  - Use Firebase Admin SDK
  - Filter users within 5km
  - Send notification with pet details

- [ ] Create `sendAdoptionAlert(pet, subscribedUsers)` function
  - Filter users with `notifyAdoption: true`
  - Send notification

- [ ] Integrate into pet status updates
  - Call `sendRescueAlert` when pet created
  - Call `sendAdoptionAlert` when status → SEARCHING_ADOPTION

#### 🧪 Test Backend (1 hour)
- [ ] Test OTP auth flow (already works)
- [ ] Test create pet endpoint
- [ ] Test get pets for map
- [ ] Test status update
- [ ] Test push notification sends
- [ ] Verify database records created

---

### Afternoon (6 hours) - Flutter Foundation

#### 📦 Models & Repositories (2 hours)

**File:** `packages/rescue_core/lib/models/pet.dart`
- [ ] Create `Pet` model class
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
    final String? rescuerPhone;
    final DateTime reportedAt;
    // ... all fields from schema
  }
  ```
- [ ] Create `PetStatus` enum with `pinColor` getter
- [ ] Create `CreatePetRequest` model
- [ ] Create `UpdatePetStatusRequest` model
- [ ] Add `fromJson` and `toJson` methods

**File:** `packages/rescue_core/lib/repositories/pet_repository.dart`
- [ ] Create `PetRepository` class
- [ ] Implement `getPetsForMap(bounds, status, species)`
- [ ] Implement `getPetById(id)`
- [ ] Implement `createPet(request)`
- [ ] Implement `updateStatus(id, request)`

**File:** `packages/rescue_core/lib/di/service_locator.dart`
- [ ] Register `PetRepository`

**File:** `packages/rescue_core/lib/rescue_core.dart`
- [ ] Export pet models and repository

#### 🧠 BLoCs (2 hours)

**Folder:** `packages/rescue_core/lib/bloc/pet/`
- [ ] Create `pet_bloc.dart` with events:
  - `LoadPetsForMap`
  - `LoadPetDetails`
  - `UpdatePetStatus`
  - `RefreshPets`

- [ ] Create `pet_state.dart` with states:
  - `PetInitial`
  - `PetsLoading`
  - `PetsLoaded(List<Pet> pets)`
  - `PetDetailsLoaded(Pet pet)`
  - `PetError(String message)`

**Folder:** `packages/rescue_core/lib/bloc/report_pet/`
- [ ] Create `report_pet_bloc.dart` with events:
  - `PickPhotos`
  - `DetectLocation`
  - `UpdateLocation(LatLng)`
  - `SubmitReport`

- [ ] Create `report_pet_state.dart` with states:
  - `ReportInitial`
  - `PhotosPicked(List<File>)`
  - `LocationDetected(LatLng)`
  - `Uploading(progress)`
  - `ReportSuccess(Pet)`
  - `ReportError(String)`

#### 📲 Flutter App Creation (2 hours)

- [ ] Create app: `cd apps && flutter create rescue_app --org com.paws`
- [ ] Update `apps/rescue_app/pubspec.yaml`:
  ```yaml
  dependencies:
    rescue_core:
      path: ../../packages/rescue_core
    flutter_bloc: ^9.0.0
    get_it: ^8.0.0
    go_router: ^14.2.0
    google_maps_flutter: ^2.5.0
    url_launcher: ^6.3.0  # For WhatsApp
  ```

- [ ] Create app structure:
  ```
  lib/
  ├── main.dart
  ├── app.dart
  ├── core/
  │   ├── router.dart
  │   └── di.dart
  └── features/
      └── map/
          └── map_screen.dart  # Main screen
  ```

- [ ] Setup DI in `main.dart`
- [ ] Setup routing with 3 tabs
- [ ] Run `flutter pub get`

---

## Day 2: UI + Integration (12 hours)

### Morning (6 hours) - Map Interface

#### 🗺️ Map Screen (4 hours)
**File:** `apps/rescue_app/lib/features/map/map_screen.dart`

- [ ] Create `MapScreen` with `GoogleMap` widget
- [ ] Add 3 bottom tabs:
  - 🚨 Rescue (PetStatus.helpNeeded)
  - 🏠 Adoption (PetStatus.searchingAdoption)
  - ✨ Success (PetStatus.adopted)

- [ ] Implement tab switching (filters map by status)
- [ ] Add FAB (Floating Action Button) for "Report Pet"
- [ ] Implement map camera positioning (center on Bangalore)
- [ ] Add current location indicator

**Custom Pin Markers:**
- [ ] Create function to generate colored pins:
  - Red for HELP_NEEDED
  - Yellow for SEARCHING_ADOPTION
  - Green for ADOPTED

- [ ] Convert `List<Pet>` to `Set<Marker>`
- [ ] Handle marker tap → show bottom sheet

#### 📋 Pet Details Bottom Sheet (2 hours)
**File:** `apps/rescue_app/lib/features/map/widgets/pet_details_sheet.dart`

- [ ] Create `DraggableScrollableSheet`
- [ ] Show pet details:
  - Photo gallery (swipeable)
  - Status badge
  - Species, breed, age, gender
  - Location address + notes
  - Time posted ("2h ago")
  - Distance from user
  - Distress notes OR adoption notes

- [ ] Add "Contact" button:
  ```dart
  ElevatedButton.icon(
    icon: Icon(Icons.message),
    label: Text('Contact via WhatsApp'),
    onPressed: () => _openWhatsApp(pet.rescuerPhone),
  )
  ```

- [ ] Implement WhatsApp launch:
  ```dart
  void _openWhatsApp(String phone) {
    final message = Uri.encodeComponent(
      "Hi! I saw your rescue alert on Paws. Can I help?"
    );
    launchUrl(Uri.parse("https://wa.me/$phone?text=$message"));
  }
  ```

- [ ] Add "Mark Help Reached" button (if user is reporter)
- [ ] Add "Mark Adopted" button (if user is rescuer)

---

### Afternoon (6 hours) - Report Flow + Polish

#### 📸 Report Pet Screen (3 hours)
**File:** `apps/rescue_app/lib/features/report/report_pet_screen.dart`

- [ ] Create multi-step form:

**Step 1: Photos**
- [ ] Camera/gallery picker button
- [ ] Show selected photos in grid
- [ ] Allow remove photo
- [ ] Max 5 photos

**Step 2: Location**
- [ ] Auto-detect current location
- [ ] Show map with draggable pin
- [ ] Reverse geocode to address
- [ ] Text field for location notes

**Step 3: Details**
- [ ] Species dropdown (Dog/Cat/Bird/Other)
- [ ] Breed text field (optional)
- [ ] Age dropdown (optional)
- [ ] Gender buttons (optional)
- [ ] Distress notes text area (required)

**Step 4: Submit**
- [ ] Upload photos to Cloudinary (use existing service)
- [ ] Create pet via repository
- [ ] Show progress indicator
- [ ] On success: Navigate back to map, center on new pin
- [ ] On error: Show error message, allow retry

#### ⚙️ Settings Screen (1 hour)
**File:** `apps/rescue_app/lib/features/settings/settings_screen.dart`

- [ ] User profile section:
  - Phone number (from auth)
  - Name (editable)
  - Profile photo (optional)

- [ ] Notification preferences:
  - Toggle: Rescue alerts
  - Toggle: Adoption alerts
  - Toggle: Success stories
  - Slider: Rescue radius (1-10km)

- [ ] Logout button

#### 🎨 Polish & Error Handling (2 hours)

**Loading States:**
- [ ] Shimmer for loading pets
- [ ] Progress bar for photo upload
- [ ] Skeleton for pet details

**Empty States:**
- [ ] Empty rescue map: "No rescues nearby. You can be the first to report!"
- [ ] Empty adoption map: "No pets available for adoption yet"
- [ ] Empty success map: "No success stories yet"

**Error Handling:**
- [ ] Network error → Retry button
- [ ] Location permission denied → Manual address entry
- [ ] Photo upload failed → Show error, allow retry
- [ ] API errors → User-friendly messages

**Permissions:**
- [ ] Request location permission on first map open
- [ ] Request notification permission after login
- [ ] Request camera/storage permission on photo picker

---

## Launch Checklist (Final Hour)

### Backend Deployment
- [ ] Set up Railway project
- [ ] Add environment variables
- [ ] Deploy backend: `railway up`
- [ ] Run migrations: `railway run bun run db:deploy`
- [ ] Test deployed API

### Flutter Build
- [ ] Update API base URL in `EnvConfig`
- [ ] Add Google Maps API key (Android/iOS)
- [ ] Add Firebase config files:
  - `google-services.json` (Android)
  - `GoogleService-Info.plist` (iOS)

- [ ] Test on real device
- [ ] Build APK: `flutter build apk --release`
- [ ] Test APK installation

### Testing
- [ ] Test OTP login
- [ ] Test report rescue (with photos)
- [ ] Test map pin colors
- [ ] Test status update (Help Reached → Adoption)
- [ ] Test WhatsApp button
- [ ] Test push notification
- [ ] Test filters (species)
- [ ] Test on Android device
- [ ] Test on iOS device (if available)

### Documentation
- [ ] Update README with deployment URLs
- [ ] Add screenshots to README
- [ ] Create user guide (WhatsApp message)
- [ ] Prepare launch announcement

---

## Out of Scope (No Feature Creep!)

❌ **NOT building in MVP:**
- Chat system (WhatsApp only)
- User profiles/reputation
- Foster network
- Vet coordination
- Donations
- Advanced filters
- Pet matching algorithm
- Admin dashboard
- Multi-language
- Offline mode
- Social sharing

✅ **Only building:**
- Phone OTP auth
- 3-tab map interface
- Report rescue flow
- Status updates (2 transitions)
- WhatsApp contact button
- Push notifications
- Basic filters (species only)

---

## Success Criteria

**Day 1 End:**
- [ ] Backend API working (all endpoints tested)
- [ ] Flutter models + BLoCs ready
- [ ] App shell created with routing

**Day 2 End:**
- [ ] Map shows pins (all 3 colors)
- [ ] Can report new rescue with photos
- [ ] Can tap pin → see details → contact via WhatsApp
- [ ] Can mark status updates
- [ ] Push notifications working
- [ ] Deployed and installable

**Ready to Launch:**
- [ ] Backend deployed on Railway
- [ ] APK built and tested
- [ ] Documentation updated
- [ ] Launch message prepared
- [ ] 5 beta testers onboarded

---

## Emergency Shortcuts (If Stuck)

**If photo upload is slow:**
- Skip compression, just upload directly
- Set max 3 photos instead of 5

**If Google Maps is complex:**
- Use simple lat/lng display first
- Add map later as enhancement

**If push notifications don't work:**
- Skip for MVP, focus on map + reporting
- Add in post-launch

**If time runs out:**
- Skip Success tab, launch with just Rescue + Adoption
- Add Success tab in week 2

---

## Quick Commands

```bash
# Backend
cd backend
bun run dev              # Start dev server
bun run db:migrate       # Run migrations
bun run db:studio        # Open Prisma Studio

# Flutter
cd apps/rescue_app
flutter pub get          # Install deps
flutter run              # Run app
flutter build apk        # Build release APK

# Test
curl -X POST http://localhost:3000/api/v1/auth/otp/send \
  -H "Content-Type: application/json" \
  -d '{"phone":"9876543210"}'
```

---

**Let's ship this! 🚀**
