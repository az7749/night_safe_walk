# Night Safe Walk Project Context

## Project Theme

Night Safe Walk is a mobile platform for safer nighttime walking. It combines public safety facility data with pedestrian road network data, calculates safety scores for each road segment, visualizes those scores on a map, and recommends walking routes that prioritize safety instead of only shortest distance.

In Korean:

> 공공 안전시설 데이터와 보행 도로망을 결합해 도로 구간별 안전도를 시각화하고, 야간 보행자를 위한 안심 경로를 추천하는 모바일 플랫폼.

This theme is the main decision-making anchor for UI, backend APIs, data processing, and future feature work.

## Problem

Most map apps show safety facilities such as streetlights, CCTV, emergency bells, and police stations as simple point icons. This makes it hard for users to intuitively judge which actual road is safer.

At night, users often prefer bright and monitored roads over the absolute shortest path. General navigation services usually do not reflect that preference well enough.

## Solution Direction

The service should combine public data and pedestrian road data to calculate a safety score for each road segment. The app should color the road itself according to safety level, similar to traffic information, so users can immediately understand safe and risky paths.

Route search should use safety-aware costs, not only physical distance, so the app can recommend safer walking routes.

## Core Ideas

- Show safety on the road line itself, not only as facility point icons.
- Recommend safe walking routes by considering safety score and distance together.
- Reflect risk reports and changing conditions where possible.
- Keep the mobile UX map-first, with a bottom navigation bar and bottom sheets for common actions.

## Main Features

### Safety Infrastructure Map

Public and municipal data should be collected and displayed on the map.

Target facility data:

- Smart streetlights
- General security lights
- CCTV
- Emergency bells
- Police stations, precincts, and substations
- Safe keeper houses and 24-hour convenience stores

Main interactions:

- Display facilities on the map
- Query nearby facilities by radius
- Filter by facility type
- Use facility density to calculate road segment safety scores

### Road-Based Safety Visualization

Safety should be analyzed by road segment, especially between intersections, instead of only by grid cells.

Each road segment should aggregate nearby safety infrastructure and risk factors, convert them into a score, and show a line color on the map.

Color mapping:

- 80-100: Safe, green
- 60-79: Good, blue
- 40-59: Caution, yellow
- 20-39: Danger, orange
- 0-19: Critical, red

### Safe Walking Navigation

The route engine should not only find the fastest route. It should prefer brighter, safer, and better monitored roads.

Route modes:

- Recommended safe route: balances distance and safety.
- Main-road priority route: avoids risky alleys as much as possible.

If the route must enter a risky alley, future UX can include vibration alerts, stronger SOS affordance, or flashlight suggestions based on sensor data.

### Quick Field Reports

Users should be able to report issues quickly without long text input.

Report examples:

- Broken streetlight
- Broken security light
- Road damage
- Dangerous facility
- Construction or walking inconvenience

Reports should include current coordinates and may temporarily affect map safety data.

Report data should use TTL expiration to avoid stale risk information. Examples:

- Broken light: keep for about 7 days
- Temporary risk: short-lived, then auto-expire

### SOS and Settings

SOS should help users request help quickly in emergencies.

Future settings:

- Guardian contact registration
- Risky segment entry alert on/off
- Route preference selection
- Favorite places
- Account information and logout

## Safety Score Logic

Base formula:

```text
Safety score = 50 + infrastructure score - risk penalty
```

Score range:

- Minimum: 0
- Maximum: 100
- Base score: 50

Infrastructure score:

- Smart streetlight: +5 per item
- General security light: +3 per item
- CCTV: +4 per item
- Emergency bell: +3 per item
- Police station, precinct, or substation: +30 per segment
- 24-hour convenience store or safe keeper house: +5 per item

Risk penalty:

- Recent report: -15 per report
- Construction: -20 per segment
- Crime-prone area: -10 per segment
- Pedestrian accident hotspot: future penalty candidate

Future correction factors:

- Facility density by road length
- Time-based pedestrian volume
- Illumination level
- Real-time incidents
- Weather and visibility

Length correction is intentionally deferred for later refinement.

## Safe Route Cost Logic

Route search should add a risk-based penalty to actual distance.

```text
Cost = actual distance in meters * (1 + risk level * K)
```

Avoidance coefficient examples:

- Recommended safe route: K = 1.0
- Main-road priority route: K = 10.0

This makes risky roads behave as if they are longer, while still allowing fallback routes when no perfect route exists.

## Technical Direction

Road and walking path data:

- Prefer OpenStreetMap pedestrian network data for practical walking connectivity.
- Consider national node-link data only if useful later.

Safety and risk data:

- Use public data and municipal datasets.

Backend spatial stack:

- PostgreSQL for data storage
- PostGIS for spatial queries and map matching
- pgRouting for custom route search using safety-aware costs

Map:

- Naver Map API for the mobile app
- Custom overlays for facility markers and colored road segments

## Map Matching

Facility points should be mapped to nearby road segments.

Examples:

- Streetlight point to adjacent walking path
- CCTV point to monitored influence segment
- Emergency bell or convenience store to nearby road safety bonus

This converts point-based public data into road-segment-based safety scores.

## Map Marker Loading Strategy

Facility markers should not be loaded for the entire city at once.

Current direction:

- Re-query facility markers when camera movement finishes.
- Use the current visible map bounds as the primary query scope.
- Prefer viewport-based loading over full-city loading.
- Keep initial marker loading lightweight enough for smooth map interaction.

Performance policy:

- When zoomed out, reduce marker density or cluster markers.
- When zoomed in, allow more detailed individual facility markers.
- Start with street lights and security lights as the first live facility types.
- Add more facility categories only after viewport loading is stable.

Why this matters:

- Full dataset loading creates too many overlays at once.
- Bounds-based loading matches what the user is actually looking at.
- This approach scales better for CCTV, emergency bells, and other future facility layers.

## Data Pipeline

Expected flow:

1. Collect public data
2. Clean coordinates and normalize formats
3. Map match facilities and risk factors to road segments
4. Calculate segment safety scores
5. Store results in the database
6. Serve data to the app for map visualization and route search

## Current Repositories

- Flutter app: `night_safe_walk`
- Server: `safe_walk_server`

The Flutter app is the mobile UX layer. The server owns public data processing, spatial analysis, and route-related APIs.

## Flutter Structure Direction

Current direction:

```text
lib/
  main.dart
  components/
    bottom_navbar.dart
    bottom_sheets/
      guide_bottom_sheet.dart
      favorite_bottom_sheet.dart
      more_bottom_sheet.dart
  features/
    auth/
    main/
    map/
```

Future expansion:

```text
lib/
  core/
    theme/
    constants/
    widgets/
  components/
  features/
    auth/
    main/
    map/
    report/
    alert/
    mypage/
```

## UX Direction

The main screen should stay map-first. Bottom navigation buttons should open bottom sheets above the bottom bar instead of replacing the entire screen whenever possible.

The UX should support one-handed operation and fast decisions during nighttime walking.

## Expected Value

For users:

- Reduce anxiety during nighttime walking
- Choose safer routes instead of only shortest routes
- Recognize risky segments quickly
- Request help quickly in emergencies

For local governments:

- Identify risky red segments and report-heavy areas
- Prioritize installation of streetlights, CCTV, and emergency bells
- Support data-driven nighttime walking safety policy
