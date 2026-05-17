## Summary

Add a refresh-token mechanism to the existing networking/auth architecture so that when any API call returns `401 Unauthorized`, the client automatically attempts to refresh credentials via `POST /auth/refresh-token` and then retries the original request once. The refresh endpoint accepts `{ "token": String, "refreshToken": String }` and returns `{ "token": String, "refreshToken": String }`.

## Current State Analysis (Repo-Grounded)

### ApiClient

File: `lib/core/network/api_client.dart`

* Adds `Authorization: Bearer <token>` via `tokenProvider`.

* When a response is `401`, it calls `onUnauthorized` (if provided) and throws `ApiException(kind: unauthorized)`.

* No retry/refresh logic exists today.

### Auth persistence

File: `lib/core/auth/token_store.dart`

* Persists `token`, `role`, and `registrationKey` via `SharedPreferences` or in-memory store.

* No refresh token persistence exists today.

### App bootstrap / wiring

File: `lib/app/app.dart`

* Creates `tokenStore`, then creates `ApiClient` with:

  * `tokenProvider: tokenStore.getToken`

  * `onUnauthorized: () async => auth.handleUnauthorized()`

* Creates `AuthRepository` + `AuthController` afterward.

### AuthRepository login

File: `lib/core/auth/auth_repository.dart`

* `POST /auth/login` and extracts token from `{accessToken|access_token|token}`.

* Does not extract or persist `refreshToken`.

## Target Behavior / Success Criteria

* On any API request (except refresh itself), if backend responds with `401`:

  1. Attempt refresh via `POST /auth/refresh-token` with `{ token, refreshToken }`.
  2. If refresh succeeds, persist the new `token` and `refreshToken`.
  3. Retry the original request once (with the new `Authorization` header).
  4. If retry still fails with `401`, treat as unauthorized (invoke `onUnauthorized`) and surface the error.

* Prevent infinite loops:

  * Never attempt refresh when the request itself is `POST /auth/refresh-token`.

  * Only retry once per original request.

* Concurrency-safe:

  * If multiple requests hit `401` concurrently, only one refresh call is performed; other requests await the same refresh result.

## Assumptions & Decisions (Locked)

* Refresh endpoint path is exactly: `POST /auth/refresh-token`

* Login response includes `refreshToken` (camelCase).

* Refresh token should be persisted in `TokenStore` (`SharedPrefsTokenStore` and `MemoryTokenStore`).

## Proposed Changes (Files + What/Why/How)

### 1) Persist refresh token in TokenStore

**Update** `lib/core/auth/token_store.dart`

* Extend `TokenStore` interface with:

  * `Future<String?> getRefreshToken();`

  * `Future<void> setRefreshToken(String token);`

* Update `MemoryTokenStore` to store `_refreshToken` in memory.

* Update `SharedPrefsTokenStore`:

  * Add a new key (e.g. `smartguard.auth.refresh_token`)

  * Implement get/set and ensure `clear()` removes it.

Why: refresh flow needs a reliable persisted `refreshToken` across sessions.

### 2) Capture refreshToken on login

**Update** `lib/core/auth/auth_repository.dart`

* After `/auth/login`, extract `refreshToken` from JSON:

  * `json['refreshToken']` (primary)

  * optionally tolerate `json['refresh_token']` as a fallback (safe robustness)

* Persist refresh token: `await _tokenStore.setRefreshToken(refreshToken)`

* Keep existing role extraction unchanged.

Decision: If `refreshToken` is missing/empty, throw a `StateError` (explicitly fail fast) so we don’t silently create sessions that can’t be refreshed.

### 3) Add refresh support to ApiClient (interceptor-like behavior)

**Update** `lib/core/network/api_client.dart`

Add constructor params:

* `TokenProvider? refreshTokenProvider` (same typedef style as tokenProvider but for refresh token), or define `typedef RefreshTokenProvider = Future<String?> Function();`

* `Future<void> Function(String token, String refreshToken)? onTokenRefreshed` (persists new tokens)

Add internal refresh lock:

* `Completer<bool>? _refreshCompleter;`

* `_refreshTokens()`:

  * Read current tokens:

    * `final token = await _tokenProvider?.call()`

    * `final refreshToken = await _refreshTokenProvider?.call()`

  * If missing, return `false`

  * Call refresh endpoint with a raw Dio request (not `request()` to avoid recursion):

    * `POST /auth/refresh-token`

    * JSON body `{ "token": token, "refreshToken": refreshToken }`

    * Headers should not include `Authorization` (avoid server rejecting expired token); include only JSON content type + accept.

  * Decode response JSON and extract:

    * `token` and `refreshToken`

  * Call `onTokenRefreshed(token, refreshToken)` to persist

  * Return `true`

Modify `request<T>()`:

* When a response returns `401`:

  * If request path is `/auth/refresh-token`, do not refresh; call existing unauthorized handling and throw.

  * Else:

    * Call `_ensureRefreshed()` which:

      * If a refresh is in flight, await it

      * Else perform refresh and complete completer

    * If refresh succeeded, retry the original request once (re-running tokenProvider so headers contain new token).

    * If refresh failed, fall back to existing unauthorized handling (`onUnauthorized`) and throw.

Why: keeps the refresh logic in the same place as existing 401 handling, matches current architecture (ApiClient already does auth-related behavior via onUnauthorized).

### 4) Wire refresh capabilities in app bootstrap

**Update** `lib/app/app.dart`

* When creating `ApiClient`, pass:

  * `refreshTokenProvider: tokenStore.getRefreshToken`

  * `onTokenRefreshed: (token, refreshToken) async { await tokenStore.setToken(token); await tokenStore.setRefreshToken(refreshToken); }`

* Keep `onUnauthorized: () async => auth.handleUnauthorized()` unchanged.

## Verification Steps

* `flutter analyze`

* `flutter test`

* Manual check (optional):

  * Force an expired token scenario, confirm app transparently refreshes and continues without redirect to login/access-denied.

