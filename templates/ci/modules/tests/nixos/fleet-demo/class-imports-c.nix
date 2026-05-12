{ ned, lib, ... }:
let
  inherit (ned) when-c;
in
{
  # class-imports-c :: nixos-module -> ST {hostName,...} -> ST host -> ST {hostName, module}
  #
  # Den policy.when equivalent for class-presence guards:
  #   Den:  policy.when (ctx: ctx.host.hasAspect X) (policy.provide {class="nixos"; module=M})
  #   Ned:  class-imports-c M class-stream host-stream
  #
  # Derives emitting hostNames from class-stream, then uses when-c to inject
  # the nixos-module once per host that has class emissions.
  # Hosts with no class emissions produce no output — module not imported.
  fleet-demo.class-imports-c = nixos-module: class-stream: host-stream:
    let
      emitting = lib.genAttrs (map (e: e.hostName) class-stream.toList) (_: true);
    in
    when-c (h: emitting ? ${h.name}) host-stream (h: { hostName = h.name; module = nixos-module; });
}
