# Nostr Canvas - Claude AI Context

This is a Nostr-based collaborative pixel canvas project (inspired by Reddit's r/place).

## Project Overview

- **Goal**: Build a decentralized collaborative pixel art canvas
- **Tech**: Flutter Web, Nostr protocol, PoW-based cooldown
- **Architecture**: 4-layer pattern (Data, Repository, Business Logic, Presentation)
- **State Management**: flutter_bloc

## Key Principles

### Architecture
- Keep layers separated (Data → Repository → Bloc → UI)
- No business logic in UI components
- Use blocs for state management
- Keep it simple - don't over-engineer

### Code Style
- **Prefer widgets over methods** - Make reusable widgets instead of private build methods
- **Use descriptive names** - Clear naming over comments
- **Document no-ops explicitly** - If a method intentionally does nothing, say why
- **Use asserts with messages** - Better than comments for validating assumptions

### State Management with Bloc
- One bloc per feature
- Events describe what happened
- States describe the UI state
- Use `part of` directives (bloc, event, state in separate files)

### Barrel Files
Create barrel files to export public APIs:
```dart
// lib/canvas/canvas.dart
export 'bloc/canvas_bloc.dart';
export 'view/canvas_page.dart';
```

## Project-Specific Notes

### Nostr Integration (To Be Implemented)
- Pixel placements will be Nostr events
- PoW cooldown to prevent spam
- Connect to multiple relays for redundancy
- Real-time canvas updates via WebSocket subscriptions

## Development Workflow

1. **Tests First** - Write tests, aim for high coverage
2. **Keep PRs Small** - Focused changes, clear descriptions
3. **Run Analysis** - `flutter analyze` must pass
4. **Format Code** - `flutter format` before committing

## Avoid

- ❌ Over-engineering - Build what's needed for the canvas
- ❌ Skipping tests
- ❌ Business logic in UI widgets
