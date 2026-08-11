# Atatus iOS Agent — Changes

Every change below was ported from the **Atatus Android Agent**, which is the reference for what
Atatus-specific changes exist. Nothing here is new functionality: no APIs, flow, or architecture
were redesigned — only renamed or repointed where Atatus requires it.

Every changed source file carries an inline `// ATCHG` marker naming what was changed in that file.
**1,663 markers across 1,563 files.** Untouched files carry no marker.

Reference: `atatus-android-agent`, fork point `f28806d` (from `dd-sdk-android` commit `61409f2f`).
The Atatus delta was extracted from `git diff f28806d..HEAD` and its 8,372 `// ATCHG:` markers.

---

## 1. Functional changes

These change behaviour or what goes on the wire. Each is marked with `// ATCHG` at the exact line.

| # | Change | Where | Android reference |
|---|---|---|---|
| 1 | Site list reduced to one Atatus site; intake host is `mo-rx.atatus.com` | `AtatusInternal/Sources/Context/AtatusSite.swift` | `AtatusSite.ATATUS` |
| 2 | Added `serverUrl` override, read from `ATATUS_SERVER_URL` | `AtatusSite.swift` | `AtatusSite.serverUrl` |
| 3 | API key header `DD-API-KEY` → `api-key` | `AtatusInternal/Sources/Upload/URLRequestBuilder.swift` | `HEADER_API_KEY` |
| 4 | `DD-EVP-ORIGIN` / `-VERSION` → `ATATUS-EVP-ORIGIN` / `-VERSION` | `URLRequestBuilder.swift` | `HEADER_EVP_ORIGIN` |
| 5 | `DD-REQUEST-ID` → `ATATUS-REQUEST-ID` | `URLRequestBuilder.swift` | `HEADER_REQUEST_ID` |
| 6 | `DD-IDEMPOTENCY-KEY` → `AT-IDEMPOTENCY-KEY` | `URLRequestBuilder.swift` | `AT_IDEMPOTENCY_KEY` |
| 7 | `DD-CLIENT-TOKEN` → `atatus-client-token` | `URLRequestBuilder.swift` | `HEADER_CLIENT_TOKEN` |
| 8 | Added headers `ATATUS-AGENT-NAME`, `ATATUS-AGENT-VERSION`, `ATATUS-APP-NAME` | `URLRequestBuilder.swift`, Logs + Trace request builders | `HEADER_AGENT_NAME` etc. |
| 9 | Query param `ddsource` → `atatus_source` | `URLRequestBuilder.swift` | `QUERY_PARAM_SOURCE` |
| 10 | Query param `ddtags` → `atatustags` | `URLRequestBuilder.swift` | `QUERY_PARAM_TAGS` |
| 11 | Added query params `license_key`, `agent_name`, `agent_version`, `app_name` | RUM, Logs and Trace request builders | `buildUrl()` |
| 12 | RUM intake path → `/v1/ios/rum` | `AtatusRUM/Sources/Feature/RequestBuilder.swift` | `/v1/android/rum` |
| 13 | Logs intake path → `/v1/ios/logs` | `AtatusLogs/Sources/Feature/RequestBuilder.swift` | `/v1/android/logs` |
| 14 | Traces intake path → `/v1/ios/spans` | `AtatusTrace/Sources/Feature/RequestBuilder.swift` | `/v1/android/spans` |
| 15 | `clientToken` → `licenseKey` throughout config and context | `Atatus.Configuration`, `AtatusContext` | `Configuration.licensekey` |
| 16 | Build `variant` → `appName`; emitted tag key `variant` → `app_name` | `AtatusContext`, `ATTag` | `AtatusContext.appName` |
| 17 | Added `AgentInfo` (`agentName` = "Atatus iOS Agent", `agentVersion` = "1.0.0") | `AtatusInternal/Sources/AgentInfo.swift` *(new)* | `AgentInfo` |
| 18 | `agent: { name, version }` appended to every RUM event payload | RUM scopes + crash receiver | `RumEventSerializer` |
| 19 | `agent: { name, version }` appended to the log payload | `AtatusLogs/Sources/RemoteLogger.swift` | `LogEventSerializer` |
| 20 | `agent: { name, version }` appended to the spans envelope | `AtatusTrace/Sources/ATSpan.swift` | `SpanEventSerializer` |
| 21 | `log_source` injected (`flutter` / `react-native` / `swift`) | `AgentInfo.logSource`, `RemoteLogger` | `LogEventSerializer` (`"kotlin"`) |
| 22 | RUM `application.id` emptied (`""`) | RUM scopes + crash receiver | `Application(id = "")` |
| 23 | Attribute prefix `_dd` → `_atatus` | sources, models, JSON schemas | `_atatus.source` etc. |
| 24 | `dd.trace_id` / `dd.span_id` → `atatus.trace_id` / `atatus.span_id` | `AtatusLogs` attributes + sanitizer | `LogAttributes` |
| 25 | Trace headers `x-datadog-*` → `x-atatus-*` | `TracingHTTPHeaders.swift` | `TracingInterceptor` |
| 26 | Added agent heartbeat (30 min poll of `/v1/ios/agent-heartbeat`) | `AtatusInternal/Sources/AgentHeartbeat.swift` *(new)* | `AgentHeartbeat` |
| 27 | Added logs heartbeat (`/v1/ios/log/heart-beat`) gating log uploads | `AgentHeartbeat.swift`, Logs request builder | `LogsHeartbeat` |
| 28 | Heartbeat skipped when the license key is blank | `AgentHeartbeat.check`, both schedulers | same guard |
| 29 | Added `Atatus.setAgentEnabled(_:)`, suspending via `TrackingConsent` | `AtatusCore/Sources/AgentHeartbeatScheduler.swift` *(new)* | `Atatus.setAgentEnabled` |
| 30 | Both schedulers started at the end of `Atatus.initialize` | `AtatusCore/Sources/Atatus.swift` | same placement |
| 31 | Flags CDN host absent for the Atatus site (request skipped) | `AtatusFlags/Sources/Client/FlagAssignmentsFetcher.swift` | `AtatusSite.ATATUS -> null` |

**Unchanged on purpose** (Android did not change them): Session Replay `/api/v2/replay`, Profiling
`/api/v2/profile`, Flags `/api/v2/exposures`; Session Replay `applicationID`; telemetry and WebView
payloads are not tagged with `agent`.

---

## 2. Rename / rebrand changes

No behaviour change — naming only. Marked with a file-level `// ATCHG` naming what that file got.

| # | Change |
|---|---|
| 32 | 11 module directories `Datadog*` → `Atatus*`, plus `Package.swift` products/targets and 10 podspecs |
| 33 | Public type `Datadog` → `Atatus`, `DatadogSite` → `AtatusSite`, `DatadogContext` → `AtatusContext` |
| 34 | Symbol prefix `DD` → `AT` (`DDSpan` → `ATSpan`, `DDError` → `ATError`, the `DD` namespace → `AT`) |
| 35 | Member prefix `dd*` → `at*` (`ddAPIKeyHeader` → `atAPIKeyHeader`, …) |
| 36 | ObjC private symbols `__dd_private_*` → `__atatus_private_*` |
| 37 | Reverse-domain identifiers `com.datadoghq.*` → `com.atatus.*` (bundle IDs, queue labels, cache paths) |
| 38 | Podspec metadata: homepage, authors, source URL → Atatus |
| 39 | Licence headers, `LICENSE` and `NOTICE` copyright holder → Atatus |
| 40 | The literal word `Datadog` scrubbed to `dd` in all prose, comments, docs and `CHANGELOG.md` |

Change 40 follows Android, whose `CHANGELOG.md` contains zero occurrences of "Datadog" and whose
KDoc reads `dd API key header` and `Defines the dd sites`. **This file is the only exception** — it
is the porting record and must name the source project to stay useful.

---

## 3. Tests

Updated because a ported change invalidated them:

- `AtatusRUM/Tests/Feature/RequestBuilderTests.swift` — `/v1/ios/rum`, Atatus query params, single site
- `AtatusCore/Tests/Atatus/Logs/AtatusLogsFeatureTests.swift` — enables the logs heartbeat gate
- `AtatusCore/Tests/Atatus/RUM/RUMFeatureTests.swift` — query-string assertion relaxed
- `AtatusCore/Tests/Objc/ATConfigurationTests.swift`, `AtatusCore/Tests/Atatus/AtatusConfigurationTests.swift` — single site
- `AtatusFlags/Tests/Client/*` — single site; flags CDN now absent
- `AtatusProfiling/Tests/RequestBuilderTests.swift`, `AtatusSessionReplay/Tests/Feature/RequestBuilder/*` — single site

Added:

- `AtatusInternal/Tests/AtatusAgentTests.swift` — site + `serverUrl` override, `AgentInfo`, the `agent`
  object merged as a sibling of the event properties, renamed headers/query params, heartbeat URL,
  blank-license-key skip
- `AtatusLogs/Tests/LogsTests.swift` → `AtatusLogsRequestBuilderTests` — `/v1/ios/logs`, agent headers
  and query params, heartbeat gate skipping the batch

---

## 4. Verification status

| Check | Result |
|---|---|
| Swift syntax parse (all 1,652 files, `swiftc -parse`, Swift 6.0.3 via Docker) | **1,650 pass** |
| Pre-existing failures | 2 — `SRWireframe+CALayerSnapshot.swift`, `SRWireframe+ReplayID.swift`; these fail identically on `develop` (trailing commas in parameter lists need Swift 6.1) |
| Residual `Datadog` branding outside this file | 0 |
| ATCHG annotation added only comment lines | verified — no code line added or removed |

> ⚠️ **A full compile and the test suites have NOT been run.** The machine used has no Swift
> toolchain for Apple platforms and no Xcode, so `swift build` / `xcodebuild` could not execute.
> The syntax parse above validates that every file is well-formed Swift; it does **not** type-check.
> **Run the build and tests on macOS before relying on this.**

### Action required before the build can resolve

Five coordinates now name repositories/products that do not exist yet, because the `Datadog` → `dd`
scrub was applied without exception:

| Coordinate | Consumed by | Fails at |
|---|---|---|
| `ddSDKTesting` | SPM product in `Atatus.xcodeproj` + `ddSDKTesting.local.xcconfig` | package resolution |
| `github.com/dd/dd-sdk-swift-testing.git` | `XCRemoteSwiftPackageReference` | package resolution |
| `raw.githubusercontent.com/dd/opentelemetry-swift-packages/…` | `Cartfile` / `Cartfile.resolved` | `carthage bootstrap` |
| `github.com/dd/rum-events-format.git` | `tools/rum-models-generator/run.py` | `make models-generate` |
| `github.com/dd/dd-mobile-session-replay-snapshots` | `tools/sr-snapshots` | SR snapshot tests |

### Other open items

- **`api-key` vs `ATATUS-API-KEY`** — Android's production constant is `HEADER_API_KEY = "api-key"`,
  but some Android tests and the Atatus Flutter agent's iOS tests still expect `ATATUS-API-KEY`.
  Production was treated as authoritative. Confirm which the backend expects.
- **Logs are held back until the first successful heartbeat** — `isLogsAllowed` defaults to `false`,
  exactly as on Android.
- **`.github/CODEOWNERS`** still references `@DataDog/*` teams; replace with your own org's teams.
- **Cache path moved** from `Library/Caches/com.datadoghq.*` to `com.atatus.*`; previously cached
  data is orphaned, not migrated.
