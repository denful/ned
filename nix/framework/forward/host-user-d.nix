{ config, ... }:
let
  inherit (config.priv) ctxD st;

  # hostUserD :: ST comp -> ST comp
  #
  # Driver: reads active host+user scope, maps each config item to
  # { <host.class>.users.users.<user.name> = attrs }. Class-agnostic —
  # works for nixos, darwin, or any host class without modification.
  hostUserD =
    compS:
    st (
      { host, user }:
      (ctxD { inherit host user; } compS).map (attrs: {
        ${host.class} = {
          users.users.${user.name} = attrs;
        };
      })
    );
in 
{
  priv = { inherit hostUserD; };
}