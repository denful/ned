{ lib, config, ... }:
let
  inherit (config.ned) ctxD st;

  # ---------------------------------------------------------------------------
  # topo.users :: compS -> compS
  #
  # Contextual fan-out driver over a host's users.
  # Must be used inside a host scope (hostsT), which provides `host`.
  #
  # Wraps compS as a single contextual computation that:
  #   1. reads `host` from the active scope (sent by hostsT's ctxD)
  #   2. iterates host.users, building user objects: { name } // userAttrs
  #   3. scopes compS with { user } for each user via ctxD
  #   4. returns the concatenated per-user ST
  #
  # Inner ctxD provides both host AND user together because of fx.rotate
  # ---------------------------------------------------------------------------
  usersT =
    compS:
    st (
      { host }:
      let
        users = lib.mapAttrsToList (name: attrs: { inherit name; } // attrs) (host.users or { });
      in
      builtins.foldl' (accS: user: accS (ctxD { inherit user; } compS)) st users
    );
in
{
  ned = { inherit usersT; };
}
