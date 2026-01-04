# Nostr Place

<p align="center">
  <img src="assets/launcher-icons/icon.png" alt="Nostr Place Logo" width="200"/>
</p>

<p align="center">
  <strong>A decentralized r/place on Nostr</strong><br>
  Collaborative pixel art where no one owns the canvas
</p>

---

## What is This?

Remember [Reddit's r/place](https://en.wikipedia.org/wiki/R/place)? That massive collaborative pixel canvas where millions fought over every pixel?

Now imagine that - but **decentralized, censorship-resistant, and running on Nostr**.

Nostr Place lets anyone place pixels on a shared canvas. No accounts, no servers to shut down, no corporate overlords deciding what art lives or dies. Just pure, chaotic, collaborative creativity powered by cryptographic proof-of-work.

### Key Features

- **Truly Decentralized** - Canvas state lives across Nostr relays, not a single server
- **PoW Cooldowns** - Rate limiting via proof-of-work instead of login walls
- **Real-time Updates** - See pixels appear as others place them
- **Permissionless** - No signups, no permissions, just create

---

## How It Works

1. **Pick a pixel** on the canvas
2. **Choose your color** from the palette
3. **Compute proof-of-work** (this creates your cooldown)
4. **Publish to Nostr** - Your pixel is now immortalized on the network
5. **Wait for cooldown** - PoW difficulty determines how long

All pixel placements are Nostr events. The canvas rebuilds itself from relay history. If one relay goes down, others keep the canvas alive.

---

## Tech Stack

Built with modern web tech and Nostr protocol:

- **Flutter Web** - Smooth, responsive canvas UI
- **Nostr Protocol** - Decentralized event storage and real-time sync
- **flutter_bloc** - Clean state management architecture
- **WebSocket Relays** - Live pixel updates
- **PoW Algorithm** - Fair, cryptographic rate limiting

### Architecture

Following a clean 4-layer pattern:

```
Data Layer → Repository → Business Logic (Bloc) → UI
```

- **Data**: Nostr relay clients, WebSocket connections
- **Repository**: Canvas state, event aggregation
- **Bloc**: Pixel placement logic, PoW computation
- **UI**: Interactive canvas, color picker, pixel preview

See [CLAUDE.md](.claude/CLAUDE.md) for detailed architecture guidelines.

---

## Getting Started

### Prerequisites
- Flutter SDK ^3.9.0
- Dart SDK ^3.9.0

### Run Locally

```bash
# Clone the repo
git clone <repository-url>
cd nostrplace

# Install dependencies
flutter pub get

# Launch in browser
flutter run -d chrome
```

### Build for Production

```bash
flutter build web
```

Deploy the `build/web` directory to any static host.

---

## Current Status

🚧 **In Active Development**

- ✅ Project foundation and architecture
- ✅ Design system and UI framework
- ⏳ Canvas data model
- ⏳ Nostr relay integration
- ⏳ PoW cooldown mechanism
- ⏳ Pixel drawing interface
- ⏳ Real-time sync

Want to contribute? Check out the [Next Steps](#next-steps) section.

---

## Nostr Protocol Details

### Event Format

Pixels are published as Nostr events (kind TBD):

```json
{
  "kind": <TBD>,
  "content": "{\"x\": 100, \"y\": 200, \"color\": \"#FF5733\"}",
  "tags": [
    ["canvas", "main"],
    ["pow", "<nonce>"]
  ],
  "created_at": 1234567890,
  "pubkey": "<user_pubkey>",
  "sig": "<signature>"
}
```

### Proof-of-Work

- Users compute a nonce that produces a hash with leading zeros
- Difficulty adjusts cooldown time (more zeros = longer wait)
- Relays can optionally verify PoW before accepting events
- Prevents spam without authentication

### Relay Strategy

- Connect to multiple relays for redundancy
- Fetch historical events to reconstruct canvas
- Subscribe to real-time updates via WebSocket
- Eventually consistent canvas state

See [Nostr Protocol Resources](#resources) for implementation references.

---

## Development

### Code Quality

```bash
# Lint
flutter analyze

# Format
flutter format lib/

# Test
flutter test

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Design System

Custom Material 3 theme with light/dark modes located in `packages/design_system/`.

### Contributing

Contributions welcome! This project follows [Very Good Ventures](https://verygood.ventures/) architecture principles.

1. Fork and create a feature branch
2. Follow existing patterns (see CLAUDE.md)
3. Write tests (aim for high coverage)
4. Submit PR with clear description

---

## Next Steps

1. **Define Nostr event kind** for pixel placements (coordinate with Nostr community)
2. **Build canvas data model** (position, color, timestamp, event ID)
3. **Implement Nostr client** (WebSocket relay connections)
4. **Design PoW algorithm** (balance difficulty vs user experience)
5. **Create canvas UI** (zoomable, pannable grid)
6. **Add pixel drawing** (color picker, preview, publish flow)

---

## Resources

### Nostr
- [Nostr Protocol](https://nostr.com/)
- [NIP-01: Basic Protocol](https://github.com/nostr-protocol/nips/blob/master/01.md)
- [NIP-13: Proof of Work](https://github.com/nostr-protocol/nips/blob/master/13.md)
- [Nostr Relay List](https://nostr.watch/)

### Flutter
- [Flutter Web Docs](https://docs.flutter.dev/platform-integration/web)
- [flutter_bloc Guide](https://bloclibrary.dev/)

---

## License

TBD

---

**Built with Flutter + Nostr** | Inspired by r/place | No servers, no censorship, just pixels
