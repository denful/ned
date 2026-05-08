{ lib, config, ... }:
let
  inherit (config.ned) ctx-d st;

  # ---------------------------------------------------------------------------
  # topo.users :: comp-s -> comp-s
  #
  # Contextual fan-out driver over a host's users.
  # Must be used inside a host scope (hosts-t), which provides `host`.
  #
  # Wraps comp-s as a single contextual computation that:
  #   1. reads `host` from the active scope (sent by hosts-t's ctx-d)
  #   2. iterates host.users, building user objects: { name } // user-attrs
  #   3. scopes comp-s with { user } for each user via ctx-d
  #   4. returns the concatenated per-user ST
  #
  # Inner ctx-d provides both host AND user together because of fx.rotate
  # ---------------------------------------------------------------------------
  users-t =
    comp-s:
    st (
      { host }:
      let
        users = lib.mapAttrsToList (name: attrs: { inherit name; } // attrs) (host.users or { });
      in
      builtins.foldl' (acc-s: user: acc-s (ctx-d { inherit user; } comp-s)) st users
    );
in
{
  ned = { inherit users-t; };
}
