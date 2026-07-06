# PaceFlow Agent Rules

## Hardware Integration Profile
- **Primary Wearable Target:** The user's primary device is a **Huawei GT Watch**.
- **Integration Strategy:** When working on Phase 7 (Real API Swap & Integrations), prioritize workflows that support the Huawei ecosystem. This means focusing on the "middleman" approach via **Android Health Connect / Google Fit** (where the Huawei Health app pushes data) or exploring the direct **Huawei Health Kit API** if raw, high-fidelity biomechanical data is strictly required. Do not assume Garmin or Apple Watch architectures as the default hardware.
- **Future Production Testing:** Even though Huawei is the primary target, the data ingestion architecture must remain abstract enough to support Garmin and other ecosystems later. The user does *not* need to purchase a Garmin for testing; agents should rely on simulated mock Garmin payloads to test cross-compatibility before full production launch.
