{ ned, ... }:
let
  inherit (ned) st;

  # Access policy: which groups get access per environment and per host.
  # by-environment: all hosts in env get these users.
  # by-host: additional groups for specific hosts (additive, not replace).
  access-policy = {
    by-environment = {
      prod    = [ "admin" ];
      staging = [ "admin" "deploy" ];
    };
    by-host = {
      lb-prod = [ "ops" ];
    };
  };

  has-group = groups: user: builtins.any (g: builtins.elem g groups) user.groups;

  # granted-groups :: host -> [group-name]
  granted-groups = host:
    let by-env  = access-policy.by-environment.${host.environment} or [];
        by-host = access-policy.by-host.${host.name} or [];
    in by-env ++ by-host;
in
{
  # access-c :: ST host -> ST user -> ST {host, user}
  # Two-stream interface: host-stream × user-stream → granted pairs.
  # Collects user registry internally; main-c needs no knowledge of pairing.
  fleet-demo.access-c = host-stream: user-stream:
    let all-users = user-stream.toList;
    in host-stream (st.flatMap (host:
      st.filterList (has-group (granted-groups host)) all-users
        (user: st { inherit host user; })
    ));
}
