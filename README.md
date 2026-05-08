# Ned - Functional Reactive Programming for Nix

[`TLDR; Take me to a code example`](./templates/ci/modules/tests/readme)

> Q: What is Ned, another [Den](https://github.com/denful/den)?  
> A:  
> - Nope, Entirely Different. 
> - Not Exactly Den 
> - Not Even Distantly-related 
> - No ETA, Deal with it 
> - No Error Diagnostics (good luck) 
> - Not Entirely Defined 
> - New Experiment, Don't ship 
> - Never Ending Disaster

Ned's [kernel.nix](kernel.nix) is based on [Functional Reactive Programming](https://cycle.js.org/streams.html) principles originally from [Cycle.js and Haskell 1.0 Dialogue](https://cycle.js.org/dialogue.html). It can be used for anything you use Nix, not necessarily NixOS configurations.


Ned [nixos test demo](templates/ci/modules/tests/nixos/simple) FRP based utilities for creating NixOS configurations since that is the most common usage of the Nix language. But these are only code examples and a way to test the kernel itself for real-world usage. You can create your own libs based on Ned's minimal kernel.

## Everything is a Stream -- Ned's core tenet

<img width="602" height="768" alt="Image" src="https://github.com/user-attachments/assets/472d6787-f90f-4849-bf8b-bfd684102a66" />

Like Den before it, Ned is also built using [`nix-effects`](https://github.com/kleisli-io/nix-effects). Ned also uses [effect rotation](https://github.com/kleisli-io/nix-effects/pull/8), scoped handlers and fn-params-as-effects to achieve [dependency injection](https://github.com/kleisli-io/nix-effects/pull/12). However, unlike Den, the primitive on Ned are nix-effects streams.

This means, Den concerns like topology transitions, class forwards, dedup, and everything else is built on stream composition, and transformations.

## Ned 0ver Stream

Ned is _feature minimal_ by design.

Since the kernel is already done, and anything else can be thought as an extension on it, I expect not to be adding more features.

However if bugs are found, templates/ added or simplifications to core utilities
are made, new releases will follow a [`Champernowne constant C10`](https://en.wikipedia.org/wiki/Champernowne_constant) [zer0ver](https://0ver.org/).


## Ned's Three Core Concepts.

- **Stream** :: `ST a`

An Stream (`ST a`) is a lazy, pull-based effectful-sequence of items `a`.

Ned `ST` type is just a wrapper around nix-effect's streams. `ST` provides a fluent API for composing and manipulating streams.

> Code convention: Names suffixed like `user-s` mean "a user stream".

- **Driver** :: `request-s -> response-s`

A driver is an stream transformation. We keep the `driver` name from `cycle.js` since it clearly designates its purpose: Drivers are responsible for performing side-effects.

In Ned, this is the correct place for installing scoped nix-effects handlers.

> Code convention: Names suffixed like `scope-d` mean "a scope driver"

- **Cycle** :: `named-source-s -> named-sink-s`

A cycle is a function taking `attrsOf stream` and returning `attrsOf stream`.

It is possible for a cycle to read from a source named `w` and write to a sink named `w`.

A driver or other cycles might _handle_ *requests* sent to the `w` sink-stream and yield *responses* to be read from the `w` source-stream.

```nix
times-c = { x }: { y = x.map (i: i * 2); }
```

> Code convention: name bindings with `-c` suffix: `times-c` means times cycle.


### That's it. Everything else is composition of these.

Ned provides `ned.st` helper to easily create and compose streams via juxtaposition: `(st 1 2 3).toList` evaluates to `[ 1 2 3 ]`.

Each call can also apply a stream *combinator*:

`(st 1 2 (stream: stream.map (i: i * 2)) 3).toList` evaluates to `[ 2 4 3 ]`


Looking for examples? For now, see [tests](templates/ci/modules/tests)
