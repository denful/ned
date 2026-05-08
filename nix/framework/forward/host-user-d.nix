{ config, ... }:
let
  inherit (config.ned) ctx-d st;

  # host-user-d :: ST comp -> ST comp
  #
  # Driver: reads active host+user scope, maps each config item to
  # { <host.class>.users.users.<user.name> = attrs }. Class-agnostic —
  # works for nixos, darwin, or any host class without modification.
  host-user-d =
    comp-s:
    st (
      { host, user }:
      (ctx-d { inherit host user; } comp-s).map (attrs: {
        ${host.class} = {
          users.users.${user.name} = attrs;
        };
      })
    );
in
{
  ned = { inherit host-user-d; };
}
