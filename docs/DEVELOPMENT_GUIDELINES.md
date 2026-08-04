# NexusMind Development Guidelines

## Scope and Architecture

Build with Flutter Material 3, Dart `^3.12.2`, Provider, GoRouter, Dio and the
existing secure/local storage abstractions. Extend the existing ownership model:
`core` for shared infrastructure, `features/<feature>` for contracts and data
implementations, `pages` for UI, and `main.dart` for dependency composition.
Do not add a competing state, routing, networking or persistence framework.

Pages depend on repository abstractions and DTOs only. Repositories own API and
storage details. New cross-page dependencies are wired through `MultiProvider`
in `main.dart`; pages must not construct clients, repositories or preferences.

## State, Routing and Async Work

- Use `ChangeNotifier` only for application state that needs reactive UI.
  Keep page-local interaction state in `StatefulWidget` state.
- Use `context.watch<T>()` for reactive values and `context.read<T>()` for
  commands and one-time reads. Check `mounted` after every `await` before a UI
  update.
- Start initial repository work in `initState`; provide loading, empty and
  error UI. Prevent duplicate submissions while a command is pending.
- Declare routes only in `router.dart`. Use `go` for tab changes and `push` for
  dismissible details or creation flows.

## Data and Security

- Define a repository interface before a local or HTTP implementation. HTTP
  requests go through `ApiClient` with an explicit parser.
- Follow `docs/BACKEND_DESIGN.md` as the API contract. Preserve response field
  casing in DTO `fromJson` mappings.
- Use `TokenStorage` for tokens and `AppSettings`/`EnvConfig` for non-sensitive
  configuration. Never log passwords, tokens or full API responses.

## UI Implementation

Follow `docs/UI_STYLE_GUIDE.md` and use `NexusTheme`, `NexusLayout` and
`NexusSurface` from `core/ui`. Component styles come from the active
`ColorScheme`; feature pages must not invent new visual tokens. Every new UI
must support both theme modes and compact mobile widths.

## Quality Gate

Run `dart format`, `flutter analyze`, and the relevant `flutter test` targets
before handing off a change. Add focused repository tests for mapping and error
behavior, and widget tests for user-visible routes or critical workflows.
