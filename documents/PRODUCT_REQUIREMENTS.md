# Paws - Product Requirements Document

**Version:** 1.0
**Date:** January 2026
**Status:** MVP Specification
**Timeline:** 2-Day Sprint
**Target:** Community Gift - Solid, No-Feature-Creep MVP

---

## Executive Summary

**Paws** is a map-first mobile application that visualizes pet rescue operations across a city. It complements existing WhatsApp-based rescue coordination by providing spatial awareness and discovery.

**Development Approach:**
- **Timeline:** 2 days end-to-end
- **Philosophy:** Community first, feature creep never
- **Scope:** Only 3 tabs - Rescue → Adoption → Happy Moments
- **Auth:** Phone OTP only (already working)

### Core Value Proposition
- **For Rescuers:** See all active rescues on a map, coordinate spatially
- **For Adopters:** Browse available pets geographically, discover nearby animals
- **For Community:** Celebrate successful adoptions, see impact

### Key Differentiator
The map IS the product. Not a feature—the entire interface is built around spatial visualization.

---

## Product Vision

### The Problem

**Current State:**
- Rescuers coordinate via WhatsApp groups
- Messages about rescued animals get lost in chat scroll
- No spatial view of where rescues are happening
- Potential adopters can't easily discover available pets
- No centralized view of adoption-ready animals

**Pain Points:**
1. "Where exactly in Koramangala?" - Vague location descriptions
2. "Are there other rescues nearby?" - No spatial awareness
3. "Which dogs are available for adoption right now?" - Hard to track
4. "I want to adopt, where do I look?" - No discovery mechanism

### The Solution

**Paws provides:**
- Real-time map of all rescue operations
- Spatial visualization of help needed vs. help reached
- Discovery mechanism for potential adopters
- Success celebration layer for community motivation

**Key Insight:**
We're NOT replacing WhatsApp. We're adding a visual dashboard that WhatsApp can't provide.

---

## Product Strategy

### Strategic Positioning

**Complementary Tool:**
- WhatsApp = Communication (WHO and HOW)
- Paws = Visualization (WHAT and WHERE)
- They work together, not competing

**Low Adoption Friction:**
- "Keep using WhatsApp, but also pin rescues here"
- Not "switch from X to Y"
- Additive, not replacement

**Long-term Funnel to Zuco:**
- Adopters use Paws to find pets
- 3-6 months later, they need boarding
- Warm leads for Zuco pet boarding platform

---

## Core User Flows

### 1. Report Rescue 🚨

**Actor:** Anyone who sees an animal needing help

**Flow:**
1. Opens Paws app
2. Taps FAB (Floating Action Button)
3. Takes photo of animal
4. Current location auto-filled (can adjust pin)
5. Adds notes: "Injured leg, near ABC restaurant"
6. Selects species (Dog/Cat/Bird/Other)
7. Taps "Report"

**Result:**
- Red pin appears on RESCUE map at location
- All users nearby (within 5km) receive push notification
- Notification: "🚨 Rescue needed: Injured dog 2km from you"

**Technical:**
```
POST /api/v1/pets
{
  "species": "dog",
  "photos": ["https://cloudinary.com/..."],
  "latitude": 12.9716,
  "longitude": 77.5946,
  "locationAddress": "Koramangala, Bangalore",
  "locationNotes": "Near ABC restaurant",
  "distressNotes": "Injured leg, bleeding",
  "status": "HELP_NEEDED"
}
```

---

### 2. Respond to Rescue 🚑

**Actor:** Rescuer

**Flow:**
1. Receives push notification OR sees red pin on map
2. Taps pin to see details
3. Views:
   - Photo
   - Location notes
   - Time posted ("2 hours ago")
   - Distance from user ("2.3 km away")
4. Taps "Contact Reporter" button
5. Opens WhatsApp with pre-filled message:
   ```
   Hi! I saw your rescue alert on Paws for the injured dog near ABC restaurant.
   I can help. Are you still at the location?
   ```

**Coordination:**
- Happens on WhatsApp
- Rescuer goes to location
- Picks up animal
- Takes to vet/foster

---

### 3. Mark Help Reached ✅

**Actor:** Rescuer who picked up the animal

**Flow:**
1. Taps the red pin (their rescue)
2. Taps "Mark Help Reached"
3. Prompted to add update:
   - Upload new photo (animal now safe)
   - Health status: "Injured", "Healthy", "Needs vet care"
   - Temperament: "Friendly", "Shy", "Aggressive"
   - Adoption notes: "Needs experienced owner", "Good with kids"
   - Phone number (for adoption inquiries)
4. Taps "Update"

**Result:**
- Pin color changes: Red → Yellow
- Pin moves from RESCUE map to ADOPTION map
- Status changes: `HELP_NEEDED` → `HELP_REACHED` → `SEARCHING_ADOPTION`
- Push notification sent to users with adoption alerts enabled:
  ```
  🏠 New dog available for adoption in Koramangala
  Friendly puppy, 3 months old, vaccinated
  ```

**Technical:**
```
PATCH /api/v1/pets/:id/status
{
  "status": "HELP_REACHED",
  "healthStatus": "injured",
  "temperament": "friendly",
  "adoptionNotes": "Needs experienced owner",
  "rescuerPhone": "+919876543210",
  "photos": ["https://cloudinary.com/..."] // Updated photos
}
```

---

### 4. Adopt a Pet 🏠

**Actor:** Person wanting to adopt

**Flow:**
1. Opens Paws app
2. Switches to ADOPTION tab (map view)
3. Sees yellow pins across the city
4. Can filter:
   - By species (Dog/Cat/Bird/Other)
   - By distance (1km, 5km, 10km, All)
5. Taps a yellow pin to see details:
   - Photo gallery
   - Health status
   - Temperament
   - Adoption requirements
   - Rescuer's notes
   - Posted/rescued time
6. Taps "Contact Rescuer"
7. Opens WhatsApp with rescuer's number:
   ```
   Hi! I'm interested in adopting the [species] you rescued in [location].
   Is it still available?
   ```

**Coordination:**
- Happens on WhatsApp
- They discuss adoption requirements
- Schedule meetup
- Complete adoption

---

### 5. Mark Adopted ✨

**Actor:** Rescuer (after successful adoption)

**Flow:**
1. Taps the yellow pin
2. Taps "Mark Adopted"
3. Prompted for celebration details:
   - Upload "after" photo with new owner
   - Success story (optional): "Meet Max's new family!"
   - Adopter's phone (optional, for success story visibility)
4. Taps "Complete"

**Result:**
- Pin color changes: Yellow → Green
- Pin moves from ADOPTION map to SUCCESS map
- Status changes: `SEARCHING_ADOPTION` → `ADOPTED`
- Push notification sent to users with success alerts enabled:
  ```
  ✨ Success story: Max found his forever home!
  ```
- Green pin stays visible for 7 days, then disappears

**Technical:**
```
PATCH /api/v1/pets/:id/status
{
  "status": "ADOPTED",
  "successStory": "Meet Max's new family!",
  "photos": ["https://cloudinary.com/..."], // With new owner
  "adopterPhone": "+919123456789"
}
```

---

## Map Interface Design

### The 3 Map Layers

#### 1. RESCUE Map 🚨
**Purpose:** Real-time rescue operations

**Pin Color:** Red
**Status:** `HELP_NEEDED`

**What Users See:**
- All active rescue alerts
- Real-time updates
- Clustered pins when zoomed out
- Individual pins when zoomed in

**Pin Tap → Bottom Sheet:**
```
┌─────────────────────────────────┐
│ 📷 Photo                        │
│                                 │
│ 🚨 Help Needed                  │
│ Posted 2 hours ago              │
│ 2.3 km away                     │
│                                 │
│ 🐕 Dog • Unknown breed          │
│ 📍 Koramangala, Bangalore       │
│ "Near ABC restaurant"           │
│                                 │
│ "Injured leg, bleeding badly.   │
│  Seems very scared."            │
│                                 │
│ [Contact Reporter] → WhatsApp   │
│ [Mark Help Reached] (if auth)   │
└─────────────────────────────────┘
```

**Features:**
- Auto-refresh every 30 seconds
- New pins animate in
- Distance indicator from user
- Time posted ("2h ago", "1 day ago")

---

#### 2. ADOPTION Map 🏠
**Purpose:** Browse animals ready for adoption

**Pin Color:** Yellow
**Status:** `SEARCHING_ADOPTION`

**What Users See:**
- All rescued animals available for adoption
- Filtered by species
- Distance-based sorting

**Pin Tap → Bottom Sheet:**
```
┌─────────────────────────────────┐
│ 📷 Photo Gallery (swipe)        │
│                                 │
│ 🏠 Ready for Adoption           │
│ Rescued 3 days ago              │
│ 1.8 km away                     │
│                                 │
│ 🐕 Dog • Labrador Mix           │
│ Age: ~3 months • Male           │
│ 📍 Koramangala, Bangalore       │
│                                 │
│ Health: Injured (recovering)    │
│ Temperament: Friendly, playful  │
│                                 │
│ "Good with kids. Needs fenced   │
│  yard. Vaccinated. Dewormed."   │
│                                 │
│ Rescued by: Priya S.            │
│                                 │
│ [Contact Rescuer] → WhatsApp    │
│ [Mark Adopted] (if rescuer)     │
└─────────────────────────────────┘
```

**Features:**
- Filter by species (Dog/Cat/Bird/Other)
- Filter by distance radius
- Sort by: Nearest, Recently added, Longest waiting
- Photo gallery with swipe
- Detailed health/temperament info

---

#### 3. SUCCESS Map ✨
**Purpose:** Celebrate successful adoptions, motivate community

**Pin Color:** Green
**Status:** `ADOPTED`

**What Users See:**
- Recent successful adoptions (last 7 days)
- Success stories
- Before/after photos

**Pin Tap → Bottom Sheet:**
```
┌─────────────────────────────────┐
│ 📷 Before/After Photos          │
│ [Swipe to see journey]          │
│                                 │
│ ✨ Adopted!                     │
│ Success 2 days ago              │
│                                 │
│ 🐕 Meet Max!                    │
│ Labrador Mix • 3 months         │
│                                 │
│ "Max was rescued with an        │
│  injured leg 2 weeks ago.       │
│  After vet care and love, he    │
│  found his forever family!      │
│  They have a big yard and       │
│  another dog for him to play    │
│  with. Happy life, Max! 🎉"     │
│                                 │
│ Rescued by: Priya S.            │
│ Adopted by: Ravi & Family       │
│                                 │
│ ❤️ 47 people celebrated         │
│                                 │
│ [Celebrate] ❤️                  │
└─────────────────────────────────┘
```

**Features:**
- Auto-disappears after 7 days
- Can "celebrate" (like button)
- Shows rescue journey timeline
- Before/after photo comparison
- Success story text

---

## Navigation & UX

### App Structure

```
┌─────────────────────────────────┐
│  Paws                    [🔔]   │ ← App bar
├─────────────────────────────────┤
│                                 │
│                                 │
│         🗺️ MAP VIEW             │
│                                 │
│      (Google Maps with pins)    │
│                                 │
│                                 │
│                                 │
├─────────────────────────────────┤
│  [🚨 Rescue] [🏠 Adoption] [✨]  │ ← Bottom tabs
└─────────────────────────────────┘
         [➕] ← FAB
```

### Bottom Navigation

**3 Tabs (all map views):**

1. **🚨 RESCUE**
   - Shows red pins (help needed)
   - Default view on app open
   - Badge shows count of nearby rescues

2. **🏠 ADOPTION**
   - Shows yellow pins (available for adoption)
   - Badge shows count of pets available
   - Filter button in top-right

3. **✨ SUCCESS**
   - Shows green pins (recent adoptions)
   - Feel-good content
   - No filters needed

### Floating Action Button (FAB)

**Position:** Bottom-right
**Action:** Report new rescue
**Visible on:** RESCUE and ADOPTION tabs
**Hidden on:** SUCCESS tab (read-only)

---

## Features & Functionality

### Core Features (MVP)

#### 1. Map View
- Google Maps integration
- Custom pin markers (red/yellow/green)
- Pin clustering (when zoomed out)
- Current location indicator
- Auto-center on user location (first open)
- Smooth zoom transitions

#### 2. Report Rescue Flow
- Camera/gallery picker
- Multiple photo upload (max 5)
- Location auto-detection
- Drag pin to adjust location
- Search address (Google Places)
- Species selector (Dog/Cat/Bird/Other)
- Notes text area
- Form validation
- Upload progress indicator

#### 3. Pin Details Bottom Sheet
- Photo gallery (swipeable)
- Status badge (color-coded)
- Time posted (relative, e.g., "2h ago")
- Distance from user
- Species and breed info
- Location address
- Reporter/rescuer notes
- Contact button (opens WhatsApp)
- Status update button (for authorized users)

#### 4. Status Updates
- Mark Help Reached (rescuer only)
- Add adoption info (health, temperament, notes)
- Update photos
- Mark Adopted (rescuer only)
- Add success story

#### 5. Push Notifications
- Rescue alerts (within 5km, configurable)
- Adoption alerts (new pets available)
- Success story alerts (optional)
- Notification settings in app

#### 6. Filters & Search
- Filter by species
- Filter by distance radius
- Sort adoption pins (nearest, newest, longest waiting)

#### 7. Authentication
- Phone OTP login (MSG91)
- User profile (name, phone, photo)
- Notification preferences
- My rescues (pets I reported)
- My adoptions (pets I rescued)

---

### Future Features (Post-MVP)

#### Phase 2
- Foster network (temporary homes)
- Vet coordination (schedule appointments)
- Medical records (vaccination history)
- Donation integration (sponsor vet bills)
- User reputation (rescue count, adoptions)

#### Phase 3
- Advanced filters (age, size, temperament)
- Pet matching algorithm
- Foster-to-adopt pipeline
- Volunteer coordination
- Rescue organization profiles

---

## Technical Specifications

### Backend API

**Base URL:** `/api/v1`

#### Pets Endpoints

```typescript
// Get pets for map view
GET /pets/map
Query params:
  - bounds: "12.9,77.5,13.0,77.6" (SW lat,lng, NE lat,lng)
  - status: "HELP_NEEDED" | "SEARCHING_ADOPTION" | "ADOPTED"
  - species: "dog" | "cat" | "bird" | "other"
Response:
{
  "success": true,
  "data": {
    "pets": [
      {
        "id": "uuid",
        "latitude": 12.9716,
        "longitude": 77.5946,
        "status": "HELP_NEEDED",
        "species": "dog",
        "photos": ["url"],
        "reportedAt": "2026-01-20T10:30:00Z"
      }
    ]
  }
}

// Report new pet
POST /pets
Body:
{
  "species": "dog",
  "photos": ["cloudinary_url"],
  "latitude": 12.9716,
  "longitude": 77.5946,
  "locationAddress": "Koramangala, Bangalore",
  "locationNotes": "Near ABC restaurant",
  "distressNotes": "Injured leg"
}
Response:
{
  "success": true,
  "data": {
    "pet": { /* full pet object */ }
  }
}

// Get pet details
GET /pets/:id
Response:
{
  "success": true,
  "data": {
    "pet": {
      "id": "uuid",
      "species": "dog",
      "breed": "Labrador Mix",
      "photos": ["url1", "url2"],
      "status": "HELP_NEEDED",
      "reportedById": "user_id",
      "reportedBy": {
        "id": "uuid",
        "name": "Priya",
        "phone": "+919876543210"
      },
      "latitude": 12.9716,
      "longitude": 77.5946,
      "locationAddress": "Koramangala",
      "distressNotes": "Injured leg",
      "reportedAt": "2026-01-20T10:30:00Z"
    }
  }
}

// Update pet status
PATCH /pets/:id/status
Body:
{
  "status": "HELP_REACHED",
  "healthStatus": "injured",
  "temperament": "friendly",
  "adoptionNotes": "Good with kids",
  "rescuerPhone": "+919876543210",
  "photos": ["new_url"]
}
Response:
{
  "success": true,
  "data": {
    "pet": { /* updated pet object */ }
  }
}

// Delete pet (only if no responses)
DELETE /pets/:id
Response:
{
  "success": true
}
```

#### User Endpoints

```typescript
// Update notification preferences
PATCH /users/me/notifications
Body:
{
  "notifyRescue": true,
  "notifyAdoption": true,
  "notifySuccess": false,
  "rescueRadius": 5000 // meters
}

// Get my pets
GET /users/me/pets
Query params:
  - role: "reported" | "rescued" | "adopted"
Response:
{
  "success": true,
  "data": {
    "pets": [ /* array of pets */ ]
  }
}
```

---

### Database Schema (Prisma)

**Already defined in `/backend/prisma/schema.prisma`**

Key models:
- `User` - With notification preferences
- `Pet` - With status, location, photos, phone numbers
- `PetStatusHistory` - Audit trail

---

### Flutter Architecture

#### State Management
- **BLoC pattern** for business logic
- Repositories for API calls
- Services for platform features

#### Key BLoCs

```dart
// PetBloc - Manage pet listing and map pins
class PetBloc extends Bloc<PetEvent, PetState> {
  - LoadPetsForMap(bounds, status, filters)
  - LoadPetDetails(id)
  - UpdatePetStatus(id, statusUpdate)
  - DeletePet(id)
}

// ReportPetBloc - Handle rescue reporting
class ReportPetBloc extends Bloc<ReportPetEvent, ReportPetState> {
  - PickPhotos
  - DetectLocation
  - UploadPhotos
  - SubmitReport
}

// AuthBloc - Authentication (already exists)
// MapBloc - Map state management
```

#### Screens

```dart
apps/rescue_app/
├── lib/
│   ├── main.dart
│   ├── features/
│   │   ├── map/
│   │   │   ├── map_screen.dart          // Main screen with 3 tabs
│   │   │   ├── pet_pin.dart             // Custom pin widget
│   │   │   └── pet_details_sheet.dart   // Bottom sheet
│   │   ├── report/
│   │   │   └── report_pet_screen.dart   // Report flow
│   │   ├── auth/
│   │   │   └── (reuse from rescue_core)
│   │   └── settings/
│   │       └── settings_screen.dart
│   └── core/
│       ├── router.dart
│       └── di/
```

---

## User Stories

### Rescuer Persona: "Priya"
**Background:** Active animal rescuer, part of WhatsApp rescue groups

**User Stories:**

1. **As Priya**, I want to see all active rescues on a map, so I can identify which ones are near me and plan my route efficiently.

2. **As Priya**, I want to quickly report a new rescue with photos and location, so others know about it immediately.

3. **As Priya**, I want to mark when I've reached an animal, so others know it's been handled and I can now find it a home.

4. **As Priya**, I want to share the animal's health status and temperament after rescue, so potential adopters know what to expect.

5. **As Priya**, I want to share my phone number only when I mark "Help Reached", so I don't get calls during the rescue operation.

---

### Adopter Persona: "Ravi"
**Background:** Wants to adopt a dog, looking for the right match

**User Stories:**

1. **As Ravi**, I want to see all dogs available for adoption on a map, so I can find ones near my neighborhood.

2. **As Ravi**, I want to filter by species and distance, so I only see relevant options.

3. **As Ravi**, I want to see detailed health and temperament information, so I can find a good match for my family.

4. **As Ravi**, I want to contact the rescuer directly via WhatsApp, so I can coordinate a meetup easily.

5. **As Ravi**, I want to see photos of the animal in its current state, so I know what it looks like now (not just rescue photos).

---

### Community Member Persona: "Anita"
**Background:** Supports rescue efforts, can't actively rescue but wants to help

**User Stories:**

1. **As Anita**, I want to see when animals get adopted, so I feel good about the community's impact.

2. **As Anita**, I want to celebrate successful adoptions, so rescuers feel appreciated.

3. **As Anita**, I want to share success stories with friends, so more people get inspired to adopt.

4. **As Anita**, I want to turn on notifications for nearby rescues, so I can help if I happen to be in the area.

---

## Success Metrics

### Key Performance Indicators (KPIs)

**Adoption (User Growth):**
- Weekly Active Users (WAU)
- Monthly Active Users (MAU)
- User retention (D7, D30)
- New user signups per week

**Engagement:**
- Reports per week (rescue alerts posted)
- Adoption success rate (% of rescued pets adopted)
- Time from "Help Needed" to "Help Reached"
- Time from "Help Reached" to "Adopted"
- Map interactions per session
- Pins tapped per session

**Funnel Metrics:**
- Report → Help Reached conversion rate
- Help Reached → Adopted conversion rate
- Pin view → WhatsApp contact rate
- Push notification → app open rate

**Community:**
- Success story celebrations (heart reactions)
- WhatsApp contacts initiated
- User-generated success stories

---

### Success Criteria (MVP)

**Week 4:**
- 50+ registered users
- 20+ rescue reports posted
- 10+ "Help Reached" status updates
- 5+ successful adoptions

**Week 8:**
- 200+ registered users
- 100+ rescue reports
- 30+ successful adoptions
- 70%+ push notification opt-in rate

**Week 12:**
- 500+ registered users
- 300+ rescue reports
- 100+ successful adoptions
- Daily active user rate > 20%

---

## Go-to-Market Strategy

### Phase 1: Seeding (Weeks 1-2)

**Target:** Bangalore rescue community (WhatsApp groups)

**Tactics:**
1. Partner with 3-5 active rescuers
2. Post in 10+ rescue WhatsApp groups:
   ```
   👋 Hey everyone! We built a map tool to visualize all our
   rescue operations across Bangalore. Keep using WhatsApp
   for coordination, but also pin rescues here so everyone
   can see the full picture.

   Download: [link]
   ```
3. Personal demos for group admins
4. Incentive: First 50 successful adoptions get featured

**Goal:** 50 users, 20 reports

---

### Phase 2: Virality (Weeks 3-4)

**Leverage:**
- WhatsApp sharing: "Hey, I just adopted this puppy via Paws! Check it out: [link]"
- Instagram posts: Rescuers tag @pawsrescue when sharing adoption stories
- Success story push notifications

**Tactics:**
1. WhatsApp share button on success stories
2. Instagram-ready adoption story templates
3. Referral incentive (unlock badge for 5 friends invited)

**Goal:** 200 users, 100 reports

---

### Phase 3: Expansion (Weeks 5-12)

**Target:** Other cities (Mumbai, Delhi, Hyderabad)

**Tactics:**
1. Reach out to rescue communities in other cities
2. Local press coverage: "Bangalore's rescue map goes national"
3. NGO partnerships (shelters, vet clinics)
4. Add city-specific features (local vets, clinics)

**Goal:** 500+ users, 5+ cities

---

### Long-term: Zuco Funnel (Month 4+)

**Strategy:**
- Track adoptions in app
- 3 months post-adoption, send notification:
  ```
  🎉 Congrats on 3 months with [pet name]!
  Going on vacation soon? Try Zuco for trusted pet boarding.

  As a Paws user, get 20% off your first booking.
  ```

**Conversion Goal:** 15-20% of adopters → Zuco users

---

## Risk Analysis

### Technical Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Google Maps API costs | High | Implement pin clustering, cache map tiles, set daily quota limits |
| Image upload failures | Medium | Compress images client-side, show retry UI, use Cloudinary's auto-retry |
| Push notification not received | Medium | Implement in-app polling fallback every 60s when app is open |
| Location permission denied | Medium | Graceful fallback: manual address entry, still show map without "me" marker |

### Product Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Spam reports | High | Rate limit (1 report per 5 mins), require phone verification, admin moderation queue |
| Fake adoptions | Medium | Require rescuer to upload photo with adopter, community reporting |
| Inappropriate photos | Medium | Cloudinary auto-moderation, user reporting, admin review |
| Low adoption from rescue community | High | Start with champions (5-10 active rescuers), get testimonials, viral seeding |

### Business Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Users don't return after first use | High | Push notifications, success stories, gamification (badges for rescues) |
| Zuco funnel doesn't convert | Medium | A/B test messaging, timing, incentives; fine-tune notification cadence |
| Competing apps emerge | Low | Network effects (more pins = more valuable), first-mover advantage in rescue space |

---

## Development Timeline

### Week 1-2: Backend & Core Models
- ✅ Prisma schema (DONE)
- Create Pet API endpoints (GET, POST, PATCH)
- Status update logic
- Push notification service
- Image upload via Cloudinary

### Week 3-4: Flutter Core
- Create rescue_app
- Map screen with Google Maps
- Custom pin markers (red/yellow/green)
- Pin clustering
- Bottom sheet UI
- Tab navigation

### Week 5: Report Flow
- Report pet screen
- Camera/gallery picker
- Photo upload with progress
- Location picker (drag pin)
- Form validation

### Week 6: Status Updates
- Mark Help Reached flow
- Add adoption details form
- Mark Adopted flow
- Success story input

### Week 7: Push Notifications
- FCM integration
- Notification preferences UI
- Geofenced alerts (5km radius)
- Notification tap handling

### Week 8: Polish & Testing
- Error handling
- Loading states
- Empty states
- E2E testing
- Beta release to 10 rescuers

### Week 9-10: Launch
- Fix bugs from beta
- App Store / Play Store submission
- Launch to rescue communities
- Monitor metrics

---

## Design Principles

### 1. Map-First
The map is not a feature, it's the product. Every interaction starts and ends with the map.

### 2. Minimal Friction
3 taps to report. 2 taps to contact. No unnecessary forms.

### 3. Visual Communication
Photos tell the story. Minimize text fields. Color-coded pins communicate status instantly.

### 4. Complement, Don't Replace
We're not replacing WhatsApp. We're adding spatial context WhatsApp can't provide.

### 5. Celebrate Wins
Success stories motivate. Green pins = dopamine. Community needs to see impact.

### 6. Trust & Safety
Phone verification required. Spam protection. Inappropriate content reporting.

---

## Open Questions

1. **Pin auto-expiry:** Should old "Help Needed" pins auto-expire after X days if no update?
   - Proposed: 7 days, then fade to gray or archive

2. **Multiple photos per status:** Allow uploading new photos when marking "Help Reached"?
   - Proposed: Yes, always append to photo gallery

3. **Edit reports:** Can reporter edit notes/photos after posting?
   - Proposed: Yes, within 1 hour of posting

4. **Admin moderation:** How to handle spam/inappropriate content?
   - Proposed: User reporting → admin queue → manual review

5. **Success story visibility:** Should adopters' personal info be visible?
   - Proposed: Phone number optional, name + city only

6. **Notification radius:** Should users be able to customize rescue alert radius?
   - Proposed: Default 5km, adjustable 1-10km in settings

---

## Appendix

### Pin Color Reference
- 🔴 Red: `HELP_NEEDED` (active rescue alert)
- 🟡 Yellow: `SEARCHING_ADOPTION` (available for adoption)
- 🟢 Green: `ADOPTED` (success, visible 7 days)
- ⚫ Gray: Archived/expired (optional future feature)

### Status Workflow
```
HELP_NEEDED (red)
    ↓ [Mark Help Reached]
HELP_REACHED (internal, instant transition)
    ↓ [Add adoption details]
SEARCHING_ADOPTION (yellow)
    ↓ [Mark Adopted]
ADOPTED (green, 7-day TTL)
    ↓ [Auto-archive after 7 days]
[ARCHIVED] (optional)
```

### WhatsApp Integration
Pre-filled messages for contact buttons:

**Contact Reporter (from rescue alert):**
```
Hi! I saw your rescue alert on Paws for the [species] in [location].
I can help. Are you still at the location?
```

**Contact Rescuer (from adoption listing):**
```
Hi! I'm interested in adopting the [species] you rescued in [location].
Is [he/she] still available?
```

---

**Document Version:** 1.0
**Last Updated:** January 23, 2026
**Next Review:** After MVP launch (Week 10)
