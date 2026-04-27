# AsyncLeakDemo

Companion code for the talk **"When async/await leaks into your domain layer"** ([Medium article](https://medium.com/@oliverperez.e/when-asynchrony-leaks-into-your-domain-layer-6204f03b4663)).

The app is a one-screen SwiftUI demo that adds movie titles to a favorites list with simulated 1.5s "DB" latency. Each architectural stage lives on its own branch — switch between branches (or compare them with `git diff`) to watch async contamination spread and contract.

## Stages

| Branch                            | Tag           | Architecture        | UX                                                            |
| --------------------------------- | ------------- | ------------------- | ------------------------------------------------------------- |
| `stage-1-sync-baseline`           | `v1-sync`     | ✅ Correct, sync     | ❌ UI freezes for 1.5s — even the spinner can't animate        |
| `stage-2-async-leak`              | `v2-leak`     | ❌ Contaminated      | ✅ Smooth — but `async` has spread everywhere                  |
| `stage-3-dispatcher-fix`          | `v3-fix`      | ✅ Correct, sync     | ✅ Smooth (cooperative pool at risk under blocking I/O)        |
| `stage-4-execution-strategies`    | `v4-execution`| ✅ Correct, sync     | ✅ Smooth, GCD-backed — pool-safe for blocking I/O             |
| `main`                            | —             | = `stage-4`         | Production-honest default                                     |

## The slides this code is built for

**The contamination slide.** Open `Domain/AddFavoriteUseCase.swift` on `stage-2-async-leak` and ask:

> *What inside this function actually needs to suspend? Trimming a string? A length check?*
>
> *We didn't introduce concurrency. We introduced syntax.*

**The killer slide.** Diff the test file between Stage 1 and Stage 2:

```sh
git diff v1-sync v2-leak -- AsyncLeakDemoTests/AddFavoriteUseCaseTests.swift
```

Same test. ~2.5× longer. Three new keywords. One new actor. *"Nothing in this test is asynchronous by nature."*

**The mic-drop slide.** Diff the domain and tests between Stage 1 and Stage 3:

```sh
git diff v1-sync v3-fix -- AsyncLeakDemo/Domain/ AsyncLeakDemo/Repository/ AsyncLeakDemoTests/
```

Empty diff. Same domain. Same tests. *"Async lives in `Dispatcher`. The domain doesn't know it exists."*

**The closing slide.** Diff the composition root between Stage 3 and Stage 4:

```sh
git diff v3-fix v4-execution -- AsyncLeakDemo/AsyncLeakDemoApp.swift
```

One line. *"Stage 3 fixed the architecture. Stage 4 fixed the execution. Async didn't belong in the domain — it belonged at the boundary. Once we moved it there, everything got simpler — and swappable."*

## File structure (identical across all branches)

```
AsyncLeakDemo/
  AsyncLeakDemoApp.swift              composition root
  ContentView.swift
  Domain/
    MovieTitle.swift
    ValidationError.swift
    AddFavoriteUseCase.swift          ⚠ signature changes per stage
  Repository/
    MovieRepository.swift             ⚠ protocol changes per stage
    InMemoryMovieRepository.swift     ⚠ Thread.sleep / Task.sleep / Thread.sleep
  Presentation/
    AddFavoriteView.swift             always shows ProgressView spinner
    AddFavoriteViewModel.swift
  Infrastructure/                     stages 3+ only
    Dispatcher.swift
    SwiftConcurrencyDispatcher.swift
    GCDDispatcher.swift               stage 4 only
AsyncLeakDemoTests/
  AddFavoriteUseCaseTests.swift       ⚠ THE killer slide
  FakeMovieRepository.swift           ⚠ class / actor / class
```

## Running

Open `AsyncLeakDemo.xcodeproj` in Xcode. Pick any stage branch. Build and run on an iOS 26.1+ simulator. Type a movie title (≥ 2 chars) and tap **Save** — Stage 1 will visibly freeze; Stages 2–4 won't.

## Vocabulary used in the talk

- **Async contamination** — the symptom: `async` spreading from infrastructure into domain code that has no asynchronous nature.
- **Boundary** — where async should live (composition root + dispatcher), not "wrapper" or "layer".
- **Execution strategy** — the pluggable thing in Stage 4 (Swift Concurrency vs GCD vs other), not "variant".
