# Sarcasm Keyboard

An iOS keyboard that auto-generates sArCaSm tExT (and other styling patterns)
so users don't have to manually alternate shift as they type.

**Status:** core `SarcasmKit` engine complete and tested. iOS app + keyboard
extension scaffolded.

## Repository layout

```
sarcasmKeyboard/
├── project.yml                         # XcodeGen spec (source of truth)
├── Package.swift                       # SwiftPM manifest for the engine library
├── Sources/SarcasmKit/                 # The pure-Swift engine (no UIKit)
│   ├── Engine/
│   │   ├── SarcasmPattern.swift        # Protocol every pattern conforms to
│   │   ├── LetterIndexedPattern.swift  # Helper protocol for letter-by-letter patterns
│   │   ├── SarcasmEngine.swift         # Pattern registry + helpers
│   │   └── SeededGenerator.swift       # Deterministic RNG
│   ├── Patterns/
│   │   ├── AlternatingPattern.swift    # aLtErNaTiNg (free, default)
│   │   ├── SpongeBobPattern.swift      # Mocking SpongeBob (free, seeded)
│   │   ├── RandomPattern.swift         # rAnDoM (free, non-deterministic)
│   │   ├── WordTogglePattern.swift     # wORD tOGGLE (free)
│   │   ├── SmallCapsPattern.swift      # ꜱᴍᴀʟʟ ᴄᴀᴘꜱ (Pro)
│   │   └── ZalgoPattern.swift          # Zalgo-lite (Pro)
│   └── Storage/
│       └── SharedDefaults.swift        # App Group UserDefaults bridge
├── Tests/SarcasmKitTests/              # 91 unit tests, all passing
├── SarcasmKeyboard/                    # iOS containing app (SwiftUI)
└── SarcasmKeyboardExtension/           # Custom Keyboard Extension
```

## Engine design

Every pattern conforms to `SarcasmPattern`:

```swift
protocol SarcasmPattern: Sendable {
    var id: String { get }
    var displayName: String { get }
    var isPremium: Bool { get }
    func transform(_ input: String) -> String
    func transformCharacter(_ char: Character, priorContext: String) -> String
}
```

- `transform(_:)` is used by the companion app, the preview UI, and the share sheet.
- `transformCharacter(_:priorContext:)` is used by the keyboard extension. It takes
  the text already in the field (`textDocumentProxy.documentContextBeforeInput`) and
  the character the user just typed, and returns the transformed string to emit.
  This keeps the transform monotonic — characters already committed are never revised.

Patterns that operate letter-by-letter can conform to `LetterIndexedPattern`, which
provides default implementations of both protocol methods in terms of
`transformLetter(_:atLetterIndex:)`. See `AlternatingPattern` for the simplest
example (~10 lines).

## Build & test

### Engine only

The `SarcasmKit` library builds and tests from the command line:

```bash
swift build
swift test
```

91 tests cover: empty strings, single characters, punctuation, numbers,
emoji (including ZWJ sequences like 👨‍👩‍👧), accented characters, determinism
of seeded patterns, keystroke-by-keystroke transforms, shared defaults, and
long inputs.

### iOS app & keyboard extension

The Xcode project is generated from `project.yml` by
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen    # one-time
xcodegen generate        # (re)generate SarcasmKeyboard.xcodeproj
open SarcasmKeyboard.xcodeproj
```

`.xcodeproj` is gitignored — `project.yml` is the source of truth. Regenerate
after pulling changes.

## Development principles

- **Keep `SarcasmKit` pure.** No `import UIKit`. No `import SwiftUI`. It must be
  portable to Kotlin for the Android port later.
- **Keyboard extension memory ceiling is ~48MB.** Don't bundle heavy assets or
  large frameworks into the extension target.
- **Never call the network from the extension.** Privacy is load-bearing for
  App Store approval of keyboards.
- **Store only transformed output in history, never raw input.** The raw input is
  the user's private typing.
