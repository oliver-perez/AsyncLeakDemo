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

## Why this works — the principles in play

This demo is small enough to show on one slide, but the architecture isn't novel. It's a faithful application of five well-known ideas from the last two decades of software design. Each is named below with its source and tied to a specific type or file in this repo. The point is to give you accurate names — so when someone asks *"what pattern is this?"* you don't reach for the wrong one.

### 1. Hexagonal Architecture / Ports & Adapters

*Alistair Cockburn, 2005.*

The strongest fit for this demo. Hexagonal Architecture says: put the application core at the center, and let everything that talks to the outside world (databases, networks, threads, UI) plug into it through *ports* (interfaces) implemented by *adapters* (concrete classes).

In this repo:

- `MovieRepository` is a port. `InMemoryMovieRepository` is an adapter for it.
- `Dispatcher` is a port. `SwiftConcurrencyDispatcher` and `GCDDispatcher` are two adapters for the same port.

Stage 4 adding `GCDDispatcher` without changing the domain *is* the ports & adapters guarantee in action: same hex, different plug.

### 2. Clean Architecture's Dependency Rule

*Robert C. Martin ("Uncle Bob"), 2012 blog post / 2017 book.*

The rule: **source-code dependencies must point only inward**, toward higher-level policy. Frameworks, async runtimes, and I/O libraries are outer-ring concerns; the domain is the innermost ring and must not import them.

Open `AsyncLeakDemo/Domain/` and grep for imports — you'll find `import Foundation` and nothing else. No `Combine`, no `URLSession`, no `_Concurrency`-specific types. That's the rule satisfied. On Stage 2's branch, the same grep shows the domain still only imports Foundation, but now its *signatures* carry `async` — that's the contamination, even though the import list looks clean. The Dependency Rule is about both imports *and* signatures.

### 3. Functional Core, Imperative Shell

*Gary Bernhardt, "Boundaries" — RubyConf 2012.*

Probably the cleanest mental model for what this talk is teaching:

- **Functional core** — `Domain/AddFavoriteUseCase.swift`. Pure, deterministic, synchronous. Given the same input, returns the same output. Trivially testable, no test doubles needed beyond a fake repository that just appends to an array.
- **Imperative shell** — `AsyncLeakDemoApp.swift` (composition root) plus `Infrastructure/*Dispatcher.swift`. Where side effects, threading, and async live. Hard to test, but small.

The "boundary" word the talk uses is exactly where these two meet. Stages 1 and 3 have the same functional core; only the imperative shell changes.

### 4. SOLID — specifically SRP, DIP, and OCP

*Robert C. Martin, formalized in* Agile Software Development *(2002).*

Three of the five SOLID letters apply directly here:

- **SRP (Single Responsibility Principle)** — `Dispatcher` exists to do one thing: execute synchronous work asynchronously. `AddFavoriteUseCase` exists to do one thing: validate input and delegate persistence. Neither type has a second reason to change. Threading and validation never co-change in this repo, by design.
- **DIP (Dependency Inversion Principle)** — `AddFavoriteUseCase` depends on `any MovieRepository`, never on `InMemoryMovieRepository`. The view model depends on `any Dispatcher`, never on `Task.detached` or `DispatchQueue`. The composition root is the only place concrete types appear, and that's correct.
- **OCP (Open/Closed Principle)** — Stage 4 introduced `GCDDispatcher` without modifying any existing type. The composition root changed by one line, but composition roots are *meant* to change when you wire new things; that's not an OCP violation, that's the system being open to extension at the right seam.

The remaining two SOLID letters (LSP, ISP) aren't really exercised here — both `Dispatcher` adapters are interchangeable (LSP-clean by construction), and the protocol surface is so small there's nothing to segregate.

### 5. DDD — partial fit, named honestly

*Eric Evans,* Domain-Driven Design *(2003).*

You reached for DDD, and you weren't wrong to — but the fit is partial, and naming this *DDD* would oversell it. What this demo borrows from DDD:

- **Repository pattern** — `MovieRepository` as an abstraction over persistence.
- **Value object** — `MovieTitle` is a small immutable type defined by its value, not its identity.
- **Use case / Application Service** style — `AddFavoriteUseCase` orchestrates a single user-driven operation.

What this demo does **not** exercise (and what DDD is mostly about):

- Aggregates and aggregate roots.
- Domain events.
- Bounded contexts and context maps.
- Ubiquitous language coordinated with domain experts.

The instinct *"keep infrastructure out of the domain so the domain can be reasoned about on its own terms"* is sometimes credited to DDD in casual conversation, but it's actually **Hexagonal / Clean Architecture**. DDD is fundamentally about *modeling the problem*; Hexagonal/Clean are about *structuring the solution*. They compose well, which is why they often get conflated.

### Tying it together

All five ideas converge on the same shape: **the domain is a small, stable thing that knows nothing about how its work runs.** Hexagonal calls the seams "ports". Clean calls them "boundaries". Bernhardt calls them the line between "functional core" and "imperative shell". SOLID's DIP says to depend on the abstractions on either side of those seams.

When you keep the seams in the right places, swapping `Task.detached` for `DispatchQueue.global` is a one-line change in the composition root — because the only thing that knew about either was the composition root.
