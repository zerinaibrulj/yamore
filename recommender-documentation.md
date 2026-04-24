# Yamore yacht recommender system

This document describes how **yacht recommendations** are computed in the Yamore backend, exposed over HTTP, and consumed in the mobile app. The implementation is a **lightweight, explainable hybrid**: it combines **content-based** signals (what the user has booked and rated highly) with **popularity and quality** signals (bookings and average ratings), and applies **strict filtering** so users are not shown yachts they have already reserved.

---

## 1. High-level behavior

- **Input:** An optional `userId` (see [API and identity](#3-api-and-identity)) plus paging (`page`, `pageSize`).
- **Output:** A **paged list** of `YachtOverview` DTOs: active yachts only, excluding yachts the user has already reserved (when logged in), ordered by a fixed **priority of signals** (see [Ordering](#4-ranking-and-ordering)).
- **No ML model:** Scoring is done with **SQL (`IQueryable`) ordering** on entity fields and counts, not a trained model. This keeps behavior transparent and easy to adjust in `YachtsService.GetRecommendations`.

**Primary code:** `Yamore.Services/Services/YachtsService.cs` — method `GetRecommendations(int? userId, int page, int pageSize)`.

**Interface contract:** `Yamore.Services/Interfaces/IYachtsService.cs` documents the intended mix of content-based, collaborative-style, and popularity signals.

---

## 2. Data sources and “preference” construction

All recommendations are limited to yachts in state **`active`** (`y.StateMachine == "active"`). The query **includes** owner, location, country, reviews, yacht–service links, and reservations for filtering and ordering.

### 2.1 Logged-in user (`userId` resolved)

The service distinguishes **yachts the user has already booked** (non-cancelled reservations) from **candidates** to recommend.

1. **Past reservations (content-based regions)**  
   From `Reservations` where `UserId` matches and `Status != "Cancelled"`, the system collects **distinct `YachtId`s**. For those yachts, it reads:
   - **Preferred category IDs** — `Yacht.CategoryId`
   - **Preferred location IDs** — `Yacht.LocationId`
   - **Preferred country IDs** — `Location.CountryId`

2. **High ratings (4+ stars) (content-based “likes”)**  
   From `Reviews` where the user is the author and `Rating >= 4`, it collects **distinct `YachtId`s**. For those yachts it again derives:
   - Category, location, and country IDs (same as above)

   If the user has **no** 4+ star reviews, the three “high rating” ID lists are empty; reservation-based preferences can still apply.

3. **Union of “preference” ID sets**  
   - `combinedCategoryIds` = distinct union of category IDs from **reservations** and **high ratings**
   - `combinedLocationIds` = same for locations
   - `combinedCountryIds` = same for countries

4. **Add-on services (service affinity)**  
   From `ReservationServices` joined to the user’s reservations, it collects **distinct `ServiceId`s** the user has actually booked (`preferredServiceIds`).

5. **Candidate set**  
   **Candidates** = active yachts whose `YachtId` is **not** in the user’s non-cancelled reservation yacht list. So the recommender does not suggest a yacht the user has already booked.

### 2.2 Cold start (no preferences)

If **all** of the following are empty:

- `combinedCategoryIds`
- `combinedLocationIds`
- `combinedCountryIds`
- `preferredServiceIds`

then the system does **not** use the multi-level content ordering (section 4.1). It falls back to the same **popularity + rating** ordering used for anonymous users (section 4.2), but still only among **candidates** (yachts not already reserved by the user).

### 2.3 Anonymous or no user id

If there is **no** resolved user id, there is no personalization: **all active yachts** are ranked only by **popularity** and **average rating** (section 4.2). No category/location/service filtering is applied beyond `active`.

---

## 3. API and identity

**Endpoint:** `GET /Yachts/recommendations`

**Query parameters:** `userId` (optional), `page` (default 0), `pageSize` (default 10).

**Authentication:** The `Yachts` API is built on a base controller that uses **JWT authorization** for most actions. The mobile app calls this route **while logged in**, so a user id is normally present. The service method still implements a **no-`userId`** branch: when the effective id passed to `GetRecommendations` is `null`, it returns the **global popularity + rating** ordering over all active yachts (see section 2.3). That path is useful for tests, admin tooling, or any future unauthenticated read access; it is *not* the typical mobile path.

**Controller logic** (`Yamore.API/Controllers/YachtsController.cs` — `GetRecommendations`):

- Reads the current user id from the JWT claim `NameIdentifier`.
- **If the user is in the Admin role:** the effective id is `userId` from the query string **if provided**, otherwise the current user id. This allows admins to test or inspect another user’s recommendations.
- **If the user is not an admin:** the `userId` query parameter is **not** used for personalization; the effective id is always the **authenticated** user’s id. Non-admins cannot request another user’s recommendation profile via `userId`.

**Important:** The mobile client can pass `userId` in the query string, but for normal end users the server still bases personalization on the **token**, not on an arbitrary `userId`, unless the caller is an admin.

---

## 4. Ranking and ordering

### 4.1 Personalized user with at least one preference signal

**Candidates** are active yachts the user has **not** already reserved (see section 2.1). Ordering is **lexicographic** (first key wins, then next):

| Priority | Signal | Meaning |
| -------- | ------ | ------- |
| 1 | `CategoryId` in `combinedCategoryIds` | Match preferred categories (from past bookings + highly rated yachts) |
| 2 | `LocationId` in `combinedLocationIds` | Match preferred marinas/areas |
| 3 | Country in `combinedCountryIds` | Match preferred countries (via `Location.CountryId`) |
| 4 | Yacht offers a **previously booked** service | `YachtServices` contains a `ServiceId` in `preferredServiceIds` |
| 5 | **Average community rating** on the yacht (descending) | Quality signal |
| 6 | **Non-cancelled reservation count** on the yacht (descending) | Popularity / “social proof” |

Each of the first four is implemented as a boolean `OrderByDescending` in LINQ (true before false), so a yacht that matches the category is ranked above one that only matches country, etc. Within the same “tier,” later keys break ties.

### 4.2 Cold user (logged in but no preference lists) and anonymous

Ordering is only:

1. **Non-cancelled reservation count** (descending) — “most booked” active yachts
2. **Average rating** (descending) — tie-breaker for quality

For a logged-in cold user, the set is still **candidates** (excludes their own past yacht ids). For anonymous users, the set is **all active** yachts.

### 4.3 Pagination

After ordering, the service applies `Skip(page * pageSize)` and `Take(pageSize)`. The response includes a **total count** of the ordered set before the page window.

---

## 5. Response building

`BuildRecommendationOverviewResult` maps each `Yacht` entity to `YachtOverviewDto`:

- Basic fields: id, name, location, country, owner, dimensions, price, state, category id
- **Thumbnail:** first matching `YachtImages` row with `IsThumbnail` for that yacht, if any
- **Aggregates from reviews:** `AverageRating` and `ReviewCount` (only reviews with a rating)

---

## 6. Client (Flutter) behavior

**API call:** `ApiService.getRecommendations` — `GET .../Yachts/recommendations` with `page`, `pageSize`, and optional `userId` query parameters.

**Home experience** (`mobile_home_tab.dart`):

- Loads recommendations alongside the main yacht list (and categories).
- If the API returns **no** overview rows, the UI applies a **client fallback:** it sorts the full loaded list by **price (descending)** and takes the first 10. That cover cases like empty backend results for edge datasets or new users where the list might still be empty on the server side depending on data.

The horizontal **“Recommended for you”** strip is shown when the user is **not** in “favorites only” mode and there is at least one recommended yacht.

---

## 7. Design trade-offs and limitations (honest scope)

- **Not collaborative filtering in the strict sense** (no user–user matrix or matrix factorization). The “other users’ behavior” comes indirectly via **global popularity** (reservation count) and **global ratings** on each yacht.
- **Content signals** are **binary** (matches category/location/country or not; has overlapping service or not), not weighted counts (e.g. how many times a user visited a country).
- **Service overlap** is binary on the yacht’s add-on set vs the user’s historical `ReservationServices`.
- **Performance:** Includes and `Count`/`Average` in ordering can be heavy on large DBs; there is no separate recommendation cache or materialized view in the described code.

For reproducibility, any change to ordering should be done in **`YachtsService.GetRecommendations`**; API route and DTO shape should stay stable unless the mobile contract is updated.

---

## 8. File reference

| Area | File |
| ---- | ---- |
| Business logic | `Yamore/Yamore.Services/Services/YachtsService.cs` (`GetRecommendations`, `BuildRecommendationOverviewResult`) |
| Interface / summary | `Yamore/Yamore.Services/Interfaces/IYachtsService.cs` |
| HTTP surface | `Yamore/Yamore.API/Controllers/YachtsController.cs` |
| Mobile API | `Yamore/UI/yamore_mobile/lib/services/api_service.dart` |
| Home UI + fallback | `Yamore/UI/yamore_mobile/lib/screens/mobile/mobile_home_tab.dart` |

This matches the system **as implemented in the repository** at the time of writing.
