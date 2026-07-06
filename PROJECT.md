# PROJECT.md: PaceFlow Core Architecture

## 1. Project Directory Structure

```
paceflow/
├── apps/
│   ├── mobile/         # Flutter (iOS/Android)
│   └── wearable/       # Flutter/Native (watchOS/Wear OS)
├── backend/
│   ├── prisma/         # Schema and Migrations
│   ├── src/
│   │   ├── api/        # Express Routes
│   │   ├── services/   # Physics, Simulation, & Auth Logic
│   │   ├── middleware/ # Telemetry Validation
│   │   └── index.ts    # Entry Point
│   └── tests/          # Unit & Integration Tests
└── infrastructure/     # Docker & CI/CD Configs
```

## 2. Database Schema (PostgreSQL)

- **Users**: ID, Email, Weight, VO2Max, Threshold HR, CreatedAt.
- **TrainingPlans**: ID, UserID, TargetDate, GoalTime, GoalDistance.
- **Courses**: ID, Name, GPX_Data (JSON), TotalElevationGain, HeatIndexFactor.
- **RunSessions**: ID, UserID, CourseID, Date, TotalTime, AvgPace.
- **TelemetrySamples**: ID, SessionID, Timestamp (ms), Lat, Lon, Elevation, Cadence, GCT (Ground Contact Time), VerticalOscillation, HeartRate.
- **PredictiveSimulations**: ID, UserID, CourseID, ScenarioParams (JSON), ProbableFinishTime, ConfidenceInterval.

## 3. Core API Endpoints

### Course & Pacing

- `POST /api/v1/courses/import`: Accepts GPX files and calculates slope coefficients.
- `GET /api/v1/pacing/curve`: Returns a terrain-adjusted pace curve for a specific course.

### Telemetry & Sync

- `POST /api/v1/sync/wearable`: Ingests millisecond-level telemetry from Garmin/Apple Health.
- `GET /api/v1/sessions/:id/metrics`: Retrieves biomechanical form data for a specific run.

### Analytical Engine

- `POST /api/v1/simulations/run`: Triggers the Monte Carlo engine for a selected course and goal.
- `GET /api/v1/analytics/fatigue-map`: Generates the geographical heat-map data.

## 4. System Architecture

1. **Client Layer**: Flutter Mobile/Wearable apps collect data via Garmin/HealthKit SDKs.
2. **Communication Layer**: Real-time Telemetry via WebSockets (for live coaching) and REST for sync.
3. **Processing Layer**: Node.js backend calculates physics-based pace adjustments and biomechanical thresholds.
4. **Intelligence Layer**: Gemini API synthesizes natural language coaching cues based on physics engine triggers.
5. **Data Layer**: PostgreSQL/Prisma stores historical training blocks and high-fidelity telemetry.

---

# 3. Phase-by-Phase Antigravity System Prompts

## Phase 1: Database Setup & Garmin/HealthKit Sensor Sync

**Task:** Initialize the PaceFlow backend infrastructure and wearable synchronization layer.

**Context:** Focus on high-fidelity data ingestion and structured storage.

**Instructions:**
1. Setup a Node.js Express project with TypeScript and Prisma ORM.
2. Define the PostgreSQL schema in `schema.prisma` including Users, TrainingPlans, Courses, RunSessions, and TelemetrySamples (supporting millisecond-level precision).
3. Implement API webhooks for Garmin Connect and Apple HealthKit to receive asynchronous workout data.
4. Create a telemetry ingestion service that validates and stores incoming sensor data (HR, Cadence, GCT, Vertical Oscillation) from wearable SDKs.
5. Establish a strict review milestone: Ensure the schema supports 100Hz telemetry samples without performance degradation.

**Boundary:** Do not implement the physics engine or UI in this phase.

## Phase 2: Physics-Engine & Elevation-Adjusted Pace Curve Calculator

**Task:** Develop the core pacing logic based on physical and environmental constraints.

**Context:** Transform raw GPS/GPX data into an actionable, dynamic racing plan.

**Instructions:**
1. Build a GPX Parser Service that calculates localized slopes (gradient %) for every 5-meter segment of a course.
2. Implement a Physics Engine that adjusts target pace based on:
   - Slope (using standard metabolic cost models for uphill/downhill).
   - Weather Data (fetching heat index and wind resistance via external API for the course coordinates).
3. Create an algorithm to generate a "Negative Split" pace curve that compensates for predicted energy expenditure.
4. Expose an endpoint `GET /pacing/curve` that returns a timestamped JSON array of target paces.
5. Review Milestone: Validate the pace curve against a control GPX file with 10% gradients.

**Boundary:** Focus exclusively on the mathematical model and API; no audio synthesis yet.

## Phase 3: Live Bio-Feedback Form Monitor & Audio Coach

**Task:** Program the real-time coaching logic and audio synthesis.

**Context:** Convert biomechanical telemetry into live performance corrections.

**Instructions:**
1. Implement a Signal Processing Service to monitor telemetry thresholds:
   - Cadence drops (>5% from baseline).
   - Ground Contact Time (GCT) increases indicative of fatigue.
   - Vertical Oscillation shifts.
2. Integrate the Gemini API to generate concise, natural language coaching instructions based on detected form degradation (e.g., "Shorten your stride; you're over-striding on the descent").
3. Implement a Text-to-Speech (TTS) pipeline to stream these instructions to the Flutter client.
4. Establish state tracking for "Coach Interventions" to prevent over-notifying the user.
5. Review Milestone: Verify the latency between a threshold breach and audio cue generation is under 2 seconds.

**Boundary:** No visualization or simulation logic in this phase.

## Phase 4: Flutter Mobile App UI & Core Navigation

**Task:** Initialize the Flutter mobile application and build the core visual screens.

**Context:** Establish the frontend foundation and user experience before wiring up real-time data. We will use Riverpod for state management and GoRouter for navigation, with a modern, high-contrast dark theme.

**Instructions:**
1. Initialize a Flutter project in `apps/mobile`.
2. Implement the foundational architecture (routing, state management, design tokens).
3. Build the **Dashboard (Home)** showing recent runs and goals.
4. Build the **Live Run Screen** to display metrics (Pace, HR, Cadence) and visual coaching cues.
5. Build the **Post-Run Analytics Screen** skeleton (ready for heat-maps and charts later).

**Boundary:** UI and mock state only. Do not attempt to integrate real backend data or webhooks yet.

## Phase 5: Backend Mocking & Simulation Engine

**Task:** Create a `MockDataService` to simulate live data without requiring paid or external APIs.

**Context:** Allow end-to-end testing of the live coaching system without needing physical hardware or API credits.

**Instructions:**
1. Build a mock telemetry generator that emits GPX coordinates, Heart Rate, and Cadence over WebSockets.
2. Replace real Gemini API calls with a local set of pre-written coaching cues (e.g., "Shorten your stride") that trigger upon simulated fatigue.
3. Stub the weather and Mapbox endpoints to return static responses.

## Phase 6: Frontend-Backend Integration

**Task:** Connect the newly built Flutter UI (Phase 4) to the Mock Data Engine (Phase 5).

**Context:** Prove that the architecture works end-to-end in real-time.

**Instructions:**
1. Wire the Live Run Screen to the simulated WebSocket stream.
2. Implement visual and audio (TTS) rendering of the mock coaching cues inside the Flutter app.

## Phase 7: Real API Swap & Production Prep

**Task:** Replace mock data with live external APIs.

**Context:** (Future phase) When resources allow, transition the system to production data.

**Instructions:**
1. Swap the Mock Gemini responses for live API calls.
2. Connect real Garmin/HealthKit ingestion hooks.
3. Activate the live Weather API and Mapbox integrations.
