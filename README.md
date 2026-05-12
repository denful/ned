<p align="right">
  <a href="https://dendritic.oeiuwq.com/sponsor"><img src="https://img.shields.io/badge/sponsor-vic-white?logo=githubsponsors&logoColor=white&labelColor=%23FF0000" alt="Sponsor Vic"/></a>
  <a href="https://deepwiki.com/denful/ned"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki"></a>
  <a href="https://github.com/denful/den/releases"><img src="https://img.shields.io/github/v/release/denful/ned?style=plastic&logo=github&color=purple"/></a>
  <a href="https://dendritic.oeiuwq.com"><img src="https://img.shields.io/badge/Dendritic-Nix-informational?logo=nixos&logoColor=white" alt="Dendritic Nix"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/denful/ned" alt="License"/></a>
  <a href="https://github.com/denful/ned/actions"><img src="https://github.com/denful/ned/actions/workflows/test.yml/badge.svg" alt="CI Status"/></a>
</p>

> ned and [vic](https://bsky.app/profile/oeiuwq.bsky.social)'s [dendritic libs](https://dendritic.oeiuwq.com) made for you with Love++ and AI--. If you like my work, consider [sponsoring](https://dendritic.oeiuwq.com/sponsor)

# Ned - Functional Reactive Programming for Nix

Ned is a minimal [kernel.nix](kernel.nix) that brings [stream-based](https://cycle.js.org/streams.html) functional-reactive programming into Nix.

[`TLDR; Take me to a code example`](./templates/ci/modules/tests/readme)

## Overview


Ned is inspired by [Cycle.js and Haskell 1.0 Dialogue](https://cycle.js.org/dialogue.html), and a follow-up to @vic's [previous](https://github.com/vic/laminar_cycle) [FRP](https://github.com/vic/cyclone) [libraries](https://laminar.dev/) for Scala, now for the Nix world.

Ned's stream-based, FRP kernel can be used for anything you use Nix, not necessarily NixOS configurations.

Our [NixOS tests](templates/ci/modules/tests/nixos) are examples of stream-based NixOS configurations since that is the most common usage of the Nix language. However, these are only code examples and a way to test the kernel itself for real-world usage. You can create your own libraries based on Ned's minimal kernel. Ned is **not** intended to be full featured NixOS configuration framework like [Den](https://github.com/denful/den) is.

## Everything is a Stream -- Ned's Core Tenet


<img width="602" height="768" alt="Image" src="https://github.com/user-attachments/assets/472d6787-f90f-4849-bf8b-bfd684102a66" />


Like Den before it, Ned is also built on [`nix-effects`](https://github.com/kleisli-io/nix-effects). It also uses [effect rotation](https://github.com/kleisli-io/nix-effects/pull/8), scoped handlers, and fn-params-as-effects to achieve [dependency injection](https://github.com/kleisli-io/nix-effects/pull/12). However, unlike Den, the primitives in Ned are nix-effects streams.

This means that Den concerns like topology transitions, class forwards, deduplication, and everything else can be expressd with just stream composition and transformations.

## Ned 0ver Stream

Ned is **feature minimal** by design.

Since the kernel is already complete, and anything else can be thought of as an extension on it, I don't expect to add more features.

However, if bugs are found, templates are added, or simplifications to core utilities are made, new releases will follow a [`Champernowne constant C10`](https://en.wikipedia.org/wiki/Champernowne_constant) [zer0ver](https://0ver.org/).


## Ned's Three Core Concepts

- **Stream** :: `ST a`

A Stream (`ST a`) is a lazy, pull-based effectful sequence of items `a`.

Ned's `ST` type is just a wrapper around nix-effects streams. `ST` provides a fluent API for composing and manipulating streams.

> **Code convention:** Names suffixed like `user-s` mean "a user stream".

- **Driver** :: `request-s -> response-s`

A driver is a stream transformation. We keep the `driver` name from `cycle.js` since it clearly designates its purpose: Drivers are responsible for performing side-effects.

In Ned, this is the correct place for installing scoped nix-effects handlers.

> **Code convention:** Names suffixed like `scope-d` mean "a scope driver".

- **Cycle** :: `named-source-s -> named-sink-s`

A cycle is a function taking `attrsOf stream` and returning `attrsOf stream`.

It's possible for a cycle to read from a source named `w` and write to a sink named `w`.

A driver or other cycles might _handle_ *requests* sent to the `w` sink-stream and yield *responses* to be read from the `w` source-stream.

```nix
times-c = { x }: { y = x.map (i: i * 2); }
```

> **Code convention:** Name bindings with `-c` suffix: `times-c` means times cycle.

### That's It. Everything Else is Composition of These.

Ned provides `ned.st` helper to easily create and compose streams via juxtaposition: `(st 1 2 3).toList` evaluates to `[ 1 2 3 ]`.

Each call can also apply a stream *combinator*:

`(st 1 2 (stream: stream.map (i: i * 2)) 3).toList` evaluates to `[ 2 4 3 ]`

Looking for examples? For now, see [tests](templates/ci/modules/tests).

