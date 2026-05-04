# Ned is a Nix configuration library.

> Q: Is Ned related-to/replacing [Den](https://github.com/denful/den)?  
> A:

- Nope, Entirely Different.
- Not Exactly Den
- Not Even Distantly-related
- No ETA, Deal with it
- No Error Diagnostics (good luck)
- Not Entirely Defined
- New Experiment, Don't ship
- Never Ending Disaster

Ned is based on [Functional Reactive Programming](https://cycle.js.org/streams.html) principles originally from [Haskell 1.0 Dialogue](https://cycle.js.org/dialogue.html).

## Everything is a Stream

<img width="602" height="768" alt="Image" src="https://github.com/user-attachments/assets/472d6787-f90f-4849-bf8b-bfd684102a66" />

Like Den, Ned is also built over a [`nix-effects`](https://github.com/kleisli-io/nix-effects) kernel. Ned also uses effect rotation, scoped handlers and fn-params-as-effects to achieve dependency injection. However, unlike Den, the primitive on Ned are nix-effects streams.

Topology transitions, class forwards, everything else is built on stream composition and transformations.

## Core Types.

Understanding these types will make it easy to understand how everything fits together in Ned.

### `ST a` :: wraps `fx.stream a` with fluent API

Ned provides `ned.st` helper to easily create a stream: `(st 1 2 3).toList` evaluates to `[ 1 2 3 ]`.

Each ST call can also take a stream *combinator*:

`(st 1 2 (ST.map (i: i * 2))).toList` evaluates to `[ 2 4 ]`

> SourceCode Refence: `ned.st`.
> 
> Code convention: name bindings with `S` suffix: `userS` means a users stream.


### `Driver` :: `requestS -> responseS`

A driver is just a stream transformation, we keep the name from `cycle.js` tradition. To mean, the place where _effectful computations_ happen. In Ned, Drivers are the place to install _scoped effect rotation_ on streams for dependency injection.

> SourceCode Refence: `ned.scopeD`, `ned.drive.*`.
>
> Code convention: name bindings with `D` suffix: `scopeD` means a scope driver.

### `Cycle` :: `sources -> sinks`

A Cycle is a function from named-streams into named-streams.

```nix
doubleC = { x, y }: { 
  z = 
   (x.zip y)
   .map({ fst, snd }: fst * snd); 
}
```

> Code convention: name bindings with `C` suffix: `doubleC` means double cycle.


That's it. Everything else is composition of these.

> Looking for examples? For now, see tests.nix