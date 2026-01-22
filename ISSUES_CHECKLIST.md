# Druto GitHub Issues Checklist

> Last updated: 2026-01-08
> Repository: https://github.com/Zuco-tech/druto/issues

## Summary

| Milestone | Total | Done | Progress |
|-----------|-------|------|----------|
| Sprint 1: Foundation | 7 | 0 | 0% |
| Sprint 2: Core Features | 9 | 0 | 0% |
| Sprint 3: Complete MVP | 12 | 0 | 0% |
| Sprint 4: Polish | 15 | 0 | 0% |
| Post-MVP | 11 | 0 | 0% |
| Phase 2: Growth | 14 | 0 | 0% |
| **Total** | **68** | **0** | **0%** |

---

## Sprint 1: Foundation (7 issues)

Core auth, DI setup, redemption endpoints

- [ ] #2 - feat(backend): implement redemption endpoints `priority:high`
- [ ] #5 - feat(backend): implement payment webhook handlers `priority:high`
- [ ] #12 - feat(core): implement authentication repository `priority:high`
- [ ] #13 - feat(core): implement user repository `priority:high`
- [ ] #19 - chore(core): setup dependency injection with GetIt `priority:high`
- [ ] #20 - feat(user): implement auth BLoC `priority:high`
- [ ] #38 - feat(merchant): implement auth BLoC `priority:high`

---

## Sprint 2: Core Features (9 issues)

Home, Explore, QR scanning, Dashboard

- [ ] #14 - feat(core): implement merchant repository `priority:high`
- [ ] #15 - feat(core): implement stamps repository `priority:high`
- [ ] #22 - feat(user): implement home BLoC `priority:high`
- [ ] #23 - feat(user): update home screen with real data `priority:high`
- [ ] #27 - feat(user): integrate QR scanner `priority:high`
- [ ] #28 - feat(user): implement scan flow BLoC `priority:high`
- [ ] #40 - feat(merchant): implement dashboard BLoC `priority:high`
- [ ] #41 - feat(merchant): update dashboard with real data `priority:high`
- [ ] #42 - feat(merchant): implement QR code screen `priority:high`

---

## Sprint 3: Complete MVP (12 issues)

Rewards, Redemption flow, Onboarding

- [ ] #16 - feat(core): implement rewards repository
- [ ] #17 - feat(core): implement redemptions repository
- [ ] #24 - feat(user): implement explore BLoC `priority:high`
- [ ] #25 - feat(user): implement explore screen `priority:high`
- [ ] #26 - feat(user): implement merchant detail screen `priority:high`
- [ ] #30 - feat(user): implement stamp success screen
- [ ] #31 - feat(user): implement reward unlocked screen
- [ ] #39 - feat(merchant): implement merchant onboarding flow `priority:high`
- [ ] #43 - feat(merchant): implement rewards management BLoC `priority:high`
- [ ] #44 - feat(merchant): implement rewards list screen `priority:high`
- [ ] #45 - feat(merchant): implement create/edit reward screen `priority:high`
- [ ] #48 - feat(merchant): implement verify redemption screen `priority:high`

---

## Sprint 4: Polish (15 issues)

Profiles, Customer management, Reviews

- [ ] #3 - feat(backend): implement review endpoints
- [ ] #4 - feat(backend): implement subscription management endpoints
- [ ] #18 - feat(core): add shared UI widgets
- [ ] #21 - feat(user): implement name entry screen
- [ ] #29 - feat(user): implement UPI app selection bottom sheet
- [ ] #32 - feat(user): implement rewards BLoC
- [ ] #33 - feat(user): implement my rewards screen
- [ ] #34 - feat(user): implement redemption screen
- [ ] #35 - feat(user): implement profile BLoC
- [ ] #36 - feat(user): implement profile screen
- [ ] #37 - feat(user): implement edit profile screen
- [ ] #46 - feat(merchant): implement customers BLoC
- [ ] #47 - feat(merchant): implement customers list screen
- [ ] #49 - feat(merchant): implement business profile screen
- [ ] #50 - feat(merchant): implement edit business screen

---

## Post-MVP (11 issues)

CI/CD, Testing, Infrastructure

- [ ] #6 - feat(backend): implement Cashfree payment gateway
- [ ] #7 - feat(backend): add cron jobs for scheduled tasks
- [ ] #8 - feat(backend): implement file upload service
- [ ] #9 - test(backend): add unit tests for services
- [ ] #10 - test(backend): add integration tests for API routes
- [ ] #11 - chore(backend): add Redis for rate limiting
- [ ] #51 - chore(infra): setup GitHub Actions for backend
- [ ] #52 - chore(infra): setup GitHub Actions for Flutter apps
- [ ] #53 - chore(infra): setup automated testing workflow
- [ ] #54 - docs: create API documentation with OpenAPI/Swagger
- [ ] #55 - docs: create developer setup guide

---

## Phase 2: Growth (14 issues)

Notifications, Analytics, Referrals

### Push Notifications
- [ ] #56 - feat(backend): implement FCM notification service
- [ ] #57 - feat(backend): add notification endpoints
- [ ] #58 - feat(backend): implement notification triggers
- [ ] #59 - feat(user): implement push notification handling
- [ ] #60 - feat(merchant): implement push notification handling

### Analytics
- [ ] #61 - feat(backend): implement advanced analytics endpoints
- [ ] #62 - feat(merchant): implement analytics screen

### Customer Engagement
- [ ] #63 - feat(backend): implement customer segments
- [ ] #64 - feat(merchant): implement customer segmentation view

### Referrals
- [ ] #65 - feat(backend): implement referral system
- [ ] #66 - feat(user): implement referral screens
- [ ] #67 - feat(backend): implement merchant referral system

### Reviews
- [ ] #68 - feat(backend): add review response feature
- [ ] #69 - feat(merchant): implement review management

---

## Quick Links

- [All Issues](https://github.com/Zuco-tech/druto/issues)
- [Sprint 1 Milestone](https://github.com/Zuco-tech/druto/milestone/1)
- [Sprint 2 Milestone](https://github.com/Zuco-tech/druto/milestone/2)
- [Sprint 3 Milestone](https://github.com/Zuco-tech/druto/milestone/3)
- [Sprint 4 Milestone](https://github.com/Zuco-tech/druto/milestone/4)
- [Post-MVP Milestone](https://github.com/Zuco-tech/druto/milestone/5)
- [Phase 2 Milestone](https://github.com/Zuco-tech/druto/milestone/6)

---

## Labels Reference

| Label | Description |
|-------|-------------|
| `priority:high` | Critical priority (P0) |
| `priority:medium` | Medium priority (P1) |
| `priority:low` | Low priority (P2/P3) |
| `backend` | Backend/API changes |
| `flutter` | Flutter app changes |
| `core` | Shared package changes |
| `infra` | Infrastructure/DevOps |
| `phase-2` | Phase 2 growth features |
| `test` | Test coverage |
| `chore` | Maintenance tasks |
