# Schema & Flow Documentation

## Updated Data Model

### Two Separate Entities

#### 1. Rescue (Red Pins - 🚨 Help Needed)
- **Purpose**: Initial rescue alert at the rescue site
- **Can represent**: 1 or multiple animals (quantity field)
- **Location**: Rescue site (never changes)
- **Status**: HELP_NEEDED → HELP_REACHED → COMPLETED

#### 2. Adoption (Yellow/Green Pins - 🏠 Adoption / ✨ Success)
- **Purpose**: Individual animal ready for adoption
- **Always**: One animal per record
- **Location**: Foster home (rescuer's location)
- **Status**: SEARCHING_ADOPTION → ADOPTED

---

## Complete Flow Example

### Scenario: "3 puppies found injured near MG Road"

**Step 1: Report Rescue (🚨 Red Pin)**
```
User opens app → Taps FAB → Takes photos → Marks location

POST /api/v1/rescues
{
  "quantity": 3,
  "species": "dog",
  "latitude": 12.9716,
  "longitude": 77.5946,
  "locationAddress": "MG Road, Bangalore",
  "locationNotes": "Behind bus stop, near ABC restaurant",
  "distressNotes": "3 puppies, 2-3 months old, injured legs, need immediate help",
  "photos": ["url1", "url2"]
}

Result:
- 1 Rescue record created
- Status: HELP_NEEDED
- Red pin appears on map at rescue site
- Push notification sent to nearby users (within 5km)
```

**Step 2: Rescuer Responds**
```
Rescuer taps red pin → Sees details → Contacts reporter via WhatsApp
→ Goes to location → Picks up all 3 puppies → Takes to vet
```

**Step 3: Mark Help Reached**
```
Rescuer taps "Mark Help Reached" button

PATCH /api/v1/rescues/:id/status
{
  "status": "HELP_REACHED",
  "rescueNotes": "Took all 3 to vet. 1 critical, 2 recovering."
}

Result:
- Rescue status: HELP_NEEDED → HELP_REACHED
- Red pin turns gray or disappears from Rescue tab
- Rescuer can now create adoptions
```

**Step 4: Create Adoptions (🏠 Yellow Pins)**
```
After vet care, rescuer fosters at home
Opens app → Goes to rescue details → Taps "Create Adoptions"

Creates 3 separate adoption records:

POST /api/v1/adoptions
{
  "rescueId": "original-rescue-uuid",
  "name": "Max",
  "species": "dog",
  "breed": "Labrador Mix",
  "age": "3 months",
  "gender": "male",
  "latitude": 12.9352,  // Rescuer's home (Koramangala)
  "longitude": 77.6245,
  "locationAddress": "Koramangala 5th Block",
  "locationNotes": "My foster home",
  "healthStatus": "recovering",
  "temperament": "friendly, playful",
  "adoptionNotes": "Good with kids, needs fenced yard",
  "rescuerPhone": "+919876543210",
  "photos": ["url_foster_home_1", "url_foster_home_2"]
}

Repeat 2 more times for the other 2 puppies (different names/details)

Result:
- 3 Adoption records created
- Status: SEARCHING_ADOPTION
- 3 yellow pins appear on Adoption tab at foster home location
- Push notification sent to users with adoption alerts enabled
```

**Step 5: Adoption Happens**
```
Potential adopter sees yellow pin → Taps → Sees Max's details
→ Contacts rescuer via WhatsApp → Coordinates meetup → Adopts Max

Rescuer marks:
PATCH /api/v1/adoptions/:id/status
{
  "status": "ADOPTED",
  "successStory": "Max found his forever home with a loving family!",
  "adopterPhone": "+919123456789",
  "photos": ["url_with_new_owner"]
}

Result:
- Adoption status: SEARCHING_ADOPTION → ADOPTED
- Yellow pin turns green, moves to Success tab
- Pin stays visible for 7 days, then auto-archives
- Push notification: "Success story: Max found his forever home!"
```

**Step 6: Rescue Complete**
```
When all 3 adoptions are marked ADOPTED:

System automatically updates:
Rescue status: HELP_REACHED → COMPLETED

Result:
- Original rescue record archived
- All 3 green pins visible on Success tab
- Community celebrates 3 successful adoptions!
```

---

## Map View by Tab

### 🚨 Rescue Tab (Red Pins)
**Shows**: `Rescue` records with `status = HELP_NEEDED`
**Query**: `GET /api/v1/rescues/map?status=HELP_NEEDED`
```json
{
  "rescues": [
    {
      "id": "uuid",
      "quantity": 3,
      "species": "dog",
      "latitude": 12.9716,
      "longitude": 77.5946,
      "distressNotes": "3 puppies injured",
      "reportedAt": "2h ago",
      "photos": ["url"]
    }
  ]
}
```

### 🏠 Adoption Tab (Yellow Pins)
**Shows**: `Adoption` records with `status = SEARCHING_ADOPTION`
**Query**: `GET /api/v1/adoptions/map?status=SEARCHING_ADOPTION`
```json
{
  "adoptions": [
    {
      "id": "uuid",
      "name": "Max",
      "species": "dog",
      "breed": "Labrador Mix",
      "latitude": 12.9352,  // Foster home
      "longitude": 77.6245,
      "healthStatus": "recovering",
      "temperament": "friendly",
      "rescuerPhone": "+919876543210",
      "photos": ["url"]
    }
  ]
}
```

### ✨ Success Tab (Green Pins)
**Shows**: `Adoption` records with `status = ADOPTED` (last 7 days)
**Query**: `GET /api/v1/adoptions/map?status=ADOPTED&days=7`
```json
{
  "adoptions": [
    {
      "id": "uuid",
      "name": "Max",
      "species": "dog",
      "latitude": 12.9352,
      "longitude": 77.6245,
      "successStory": "Max found his forever home!",
      "adoptedAt": "2 days ago",
      "photos": ["url_with_owner"]
    }
  ]
}
```

---

## API Endpoints

### Rescues

```typescript
POST   /api/v1/rescues              // Report new rescue
GET    /api/v1/rescues/map          // Get rescues for map (with filters)
GET    /api/v1/rescues/:id          // Get rescue details
PATCH  /api/v1/rescues/:id/status   // Mark help reached
DELETE /api/v1/rescues/:id          // Delete (only if HELP_NEEDED and no responses)
```

### Adoptions

```typescript
POST   /api/v1/adoptions            // Create adoption (from rescue or standalone)
GET    /api/v1/adoptions/map        // Get adoptions for map (with filters)
GET    /api/v1/adoptions/:id        // Get adoption details
PATCH  /api/v1/adoptions/:id        // Update adoption details
PATCH  /api/v1/adoptions/:id/status // Mark adopted
DELETE /api/v1/adoptions/:id        // Delete (only if SEARCHING_ADOPTION)
```

---

## Key Benefits of This Approach

✅ **Handles Multiple Animals**
- One rescue alert can represent 3 puppies
- No need to report 3 times

✅ **Accurate Locations**
- Rescue site location preserved (never changes)
- Adoption location separate (foster home)
- Map pins show correct locations

✅ **Clean Separation**
- Rescue tab: Help needed alerts
- Adoption tab: Individual animals ready for homes
- No confusion

✅ **Flexible**
- Can create adoptions from rescues (linked via rescueId)
- OR can create standalone adoptions (rescueId = null)
- Example: Someone wants to rehome their own pet

✅ **Future-Proof**
- Tracks full rescue journey
- Analytics: How many animals per rescue
- Success rate: Rescued → Adopted conversion

---

## Database Relationships

```
User (rescuer)
  ├── reportedRescues[]  (Rescue)
  ├── rescues[]          (Rescue - as rescuer)
  └── adoptions[]        (Adoption - as adopter)

Rescue
  ├── reportedBy (User)
  ├── rescuer (User)
  └── adoptions[] (Adoption - children created from this rescue)

Adoption
  ├── rescue (Rescue - optional parent)
  ├── rescuedBy (User - fostering)
  └── adopter (User - final owner)
```

---

## Status Transitions

### Rescue
```
HELP_NEEDED → HELP_REACHED → COMPLETED
    ↓              ↓              ↓
Red pin      (creating      All adopted
             adoptions)
```

### Adoption
```
SEARCHING_ADOPTION → ADOPTED
         ↓              ↓
    Yellow pin     Green pin
                  (7 days TTL)
```

---

## Implementation Notes

**For MVP:**
- Focus on the linked flow (Rescue → Adoptions)
- Standalone adoptions can be Phase 2
- Keep create adoption flow simple (manual form, not batch)

**UI Flow:**
1. Rescue details bottom sheet has "Mark Help Reached" button
2. After marking, shows "Create Adoption" button
3. Opens form to create first adoption
4. Can repeat to create more adoptions for same rescue

**Edge Cases:**
- What if only 2 out of 3 puppies survive? → Create 2 adoptions
- What if rescuer wants to keep one? → Create 2 adoptions, mark rescue as COMPLETED manually
- What if someone reports their own pet for adoption? → Phase 2 feature (standalone adoptions)
