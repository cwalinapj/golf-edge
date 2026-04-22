# Rail Golf Android App Architecture

The Android app is the dashboard and operator for two separate systems:

- the Raspberry Pi proxy backend
- the local FS Golf automation helper

The app must not become the Mevo proxy. Networking, packet capture, persistent
proxy state, and Mevo discovery live on the Pi. Android shows state, sends
commands to the Pi, and uses an AccessibilityService only for local FS Golf UI
automation.

## Build Order

1. Make the Android app talk to the Pi only.
2. Add an AccessibilityService test action for FS Golf.
3. Combine Pi state and FS Golf screen state into guarded actions.
4. Add full flows for monitor connection, indoor/outdoor mode, sessions, radar
   state, and diagnostics.

## Target Modules

The current app is Flutter with native Android platform code where needed. These
module names describe ownership boundaries. In the current single Flutter
package, mirror them as folders under `lib/` and native packages under
`android/app/src/main/kotlin/`.

## First Version Scope

Do not build all modules on day one. Start with the smallest useful vertical
slice:

```text
:app
:feature-dashboard
:feature-proxy
:feature-fsgolf-control
:core-accessibility
:core-pi-api
:core-model
:core-ui
:core-common
```

In Flutter source, mirror those names with underscore folders where needed:

```text
lib/features/dashboard/
lib/features/proxy/
lib/features/fsgolf_control/
lib/core/accessibility/
lib/core/pi_api/
lib/core/model/
lib/core/ui/
lib/core/common/
```

Then add:

```text
:feature-recipes
:feature-logs
:core-data
:core-database
:core-network
```

### app

The application shell.

Owns startup, navigation, dependency wiring, permission flow, accessibility
status binding, and the Pi connection banner.

Current files:

- `lib/main.dart`
- `lib/app.dart`

### feature-dashboard

The main home surface.

Shows Pi online/offline, proxy running/stopped, Mevo discovered/not discovered,
FS Golf current screen, radar status, quick actions, connection summary, and a
recent logs preview.

Target folder:

- `lib/features/dashboard/`

### feature-proxy

UI and state for Pi proxy control.

Owns start, stop, restart, proxy status, discovery response, TCP `5100`/`1258`
session state, logs, and counters. Talks only through `core-pi-api` /
repositories, never directly to networking code.

Target folder:

- `lib/features/proxy/`

Current seed:

- controller setup buttons for `Test Pi Connection`, `Get Proxy Status`, and
  `Show Mevo Info`

### feature-fsgolf-control

UI for controlling FS Golf.

Owns user-facing actions such as open FS Golf, outdoor mode, indoor mode, start
session, radar adjustment, back, and connect radar. This module calls a facade;
it does not inspect AccessibilityService nodes directly.

Target folder:

- `lib/features/fsgolf_control/ui/`
- `lib/features/fsgolf_control/viewmodel/`
- `lib/features/fsgolf_control/actions/`

Responsibilities:

- `ui/`: FS Golf control screens, buttons, and status display.
- `viewmodel/`: screen state, action enablement, and orchestration calls.
- `actions/`: named FS Golf commands such as outdoor mode, indoor mode, start
  session, radar adjustment, back, and connect radar. These call the
  `core-accessibility` facade and do not depend on native service internals.

### feature-recipes

Recipe management UI.

Owns saved automation recipes, test recipe, enable/disable, import/export JSON,
and recipe verification results.

Example recipe IDs:

- `set_outdoor_mode`
- `set_indoor_mode`
- `start_new_session`

Target folder:

- `lib/features/recipes/`

### feature-logs

User-facing diagnostics.

Shows Pi proxy events, accessibility action history, last failed recipe step,
last matched node, and TCP/UDP summaries.

Target folder:

- `lib/features/logs/`

### core-accessibility

Native Android automation layer.

Owns AccessibilityService, current node reads, lookup by resource ID/text/class,
click, long click, scroll, screen snapshot metadata, and action execution. The
Flutter UI talks to this through a small platform-channel facade.

Suggested native packages:

- `accessibility/service/`
- `accessibility/executor/`
- `accessibility/matcher/`
- `accessibility/reader/`
- `accessibility/model/`

Suggested Flutter facade:

- `lib/core/accessibility/`

Target core split:

```text
core-accessibility/
  service/
  executor/
  matcher/
  reader/
  model/
```

Responsibilities:

- `service/`: Android `AccessibilityService` lifecycle and permission state.
- `executor/`: guarded click, scroll, back, launch app, and action execution.
- `matcher/`: find nodes by text, resource ID, class, bounds, and screen rules.
- `reader/`: screen snapshots, visible text extraction, current screen state.
- `model/`: accessibility DTOs shared with recipes and FS Golf control.

### core-pi-api

Pi API client.

Owns DTOs and calls for REST/WebSocket endpoints:

- `/health`
- `/proxy/status`
- `/proxy/start`
- `/proxy/stop`
- `/proxy/logs`
- `/proxy/mevo`
- `/proxy/discovery`
- `/proxy/connections`

Current seed:

- `lib/core/api_client.dart`

Target folder:

- `lib/core/pi_api/`

Target core split:

```text
core-pi-api/
  api/
  dto/
  repository/
  websocket/
```

Responsibilities:

- `api/`: typed REST endpoint client definitions.
- `dto/`: wire-format request/response objects for the Pi API.
- `repository/`: Pi-facing repository implementations used by `core-data`.
- `websocket/`: live status/log stream client.

### core-model

Shared data models.

Examples:

- `ProxyStatus`
- `MevoDiscoveryInfo`
- `FsGolfScreenState`
- `Recipe`
- `RecipeStep`
- `ActionResult`
- `RadarStatus`

Current seed:

- `lib/core/models.dart`

Target folder:

- `lib/core/model/`

### core-data

Repositories that combine sources.

Examples:

- `ProxyRepository`
- `FsGolfRepository`
- `RecipeRepository`
- `LogRepository`

This layer connects Pi API, local storage, and accessibility state.

Target folder:

- `lib/core/data/`

### core-database

Local persistence.

For Flutter, use Drift or SQLite-backed storage if the data becomes relational.
For native-only storage, use Room in the Android layer. Store saved Pi hosts,
recipes, action history, cached status, and user preferences.

Current seed:

- `lib/core/mevo_binding_store.dart`
- `lib/core/wallet_user.dart`

Target folder:

- `lib/core/database/`

### core-network

Shared networking setup.

Owns HTTP/WebSocket client config, JSON serialization, interceptors, and
timeouts. `core-pi-api` depends on this.

Target folder:

- `lib/core/network/`

### core-ui

Reusable UI components.

Examples:

- status chips
- action cards
- confirm dialogs
- log rows
- connection banners
- recipe step cards

Target folder:

- `lib/core/ui/`

### core-common

Utilities and constants.

Examples:

- result wrappers
- timers
- JSON helpers
- logging helpers
- app constants

Target folder:

- `lib/core/common/`

## Dependency Rules

The app shell may wire every feature and core module:

```text
app
 ├─ feature-dashboard
 ├─ feature-proxy
 ├─ feature-fsgolf-control
 ├─ feature-recipes
 ├─ feature-logs
 ├─ core-ui
 ├─ core-data
 ├─ core-model
 ├─ core-common
 └─ core-accessibility + core-pi-api
```

Internally, these are the allowed dependency edges:

```text
app
 ├─ feature-dashboard
 ├─ feature-proxy
 ├─ feature-fsgolf-control
 ├─ core-ui
 └─ core-common

feature-dashboard -> core-pi-api, core-accessibility, core-model, core-ui
feature-proxy -> core-pi-api, core-model, core-ui
feature-fsgolf-control -> core-accessibility, core-model, core-ui

core-pi-api -> core-model, core-common
core-accessibility -> core-model, core-common
core-ui -> core-common
```

Forbidden dependencies:

- `core-pi-api` must not depend on UI.
- `core-accessibility` must not depend on feature UI.
- `feature-proxy` must not call native accessibility internals.
- `feature-fsgolf-control` must not call Pi networking directly.
- Android must not perform Mevo proxying; it controls the Pi proxy.

## Near-Term Refactor

Keep behavior stable while moving files:

1. Move `ApiClient` into `lib/core/pi_api/`.
2. Split models from `lib/core/models.dart` into `lib/core/model/`.
3. Move reusable panels/chips from `app.dart` into `lib/core/ui/`.
4. Create `lib/features/proxy/` for the Phase 1 proxy status/actions.
5. Create `lib/core/accessibility/` with a no-op facade before adding the native
   service.
6. Add native `AccessibilityService` skeleton only after Phase 1 Pi controls are
   stable on device.
