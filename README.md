# Nostr Canvas

<p align="center">
  <img src="assets/launcher-icons/icon.jpeg" alt="Nostr Canvas Logo" width="200"/>
</p>

<p align="center">
  <strong>A r/place on Nostr</strong><br>
  Collaborative pixel art where no one owns the canvas
</p>

---

## What is This?

Remember [Reddit's r/place](https://en.wikipedia.org/wiki/R/place)? That massive collaborative pixel canvas where millions fought over every pixel?

Now imagine that - but **running on Nostr**.

## Features

- **PoW Cooldowns** - Rate limiting via proof-of-work
- **Real-time Updates** - See pixels appear as others place them
- **Multiple Auth Options** - Guest mode, import nsec, or NIP-07 extension

## Getting Started

### Prerequisites

- Flutter SDK ^3.9.0

### Run Locally

```bash
flutter pub get
flutter run -d chrome
```

### Build for Production

```bash
flutter build web
```

## Development

```bash
# Analyze
flutter analyze

# Format
dart format .

# Test
flutter test
```

## Tech Stack

- [Flutter Web](https://flutter.dev) - UI framework
- [Nostr Protocol](https://nostr.com) - Event storage and real-time sync
- [flutter_bloc](https://bloclibrary.dev) - State management
- [Flame](https://flame-engine.org) - Canvas rendering

## License

MIT License - see [LICENSE.md](LICENSE.md)
