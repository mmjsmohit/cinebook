### Task 2: Shared Foundation (`cinebook_core`)
Implement the shared API and state logic in `cinebook_core`:
1. `AuthBloc`: manage logged-in state, load tokens on startup from secure storage, logout logic.
2. `dio` interceptors: attach `Authorization: Bearer <access>` header. Handle `401 Unauthorized` by calling `/auth/refresh` and retrying the original request.
3. Parse the standard `{ error: { code, message } }` envelope for failed requests.

