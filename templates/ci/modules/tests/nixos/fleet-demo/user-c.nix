{ ned, ... }:
let
  inherit (ned) map-c;

  ssh-module = { host, user }: {
    hostName = host.name;
    userName = user.name;
    module   = {
      isNormalUser                    = true;
      openssh.authorizedKeys.keys     = user.ssh-keys;
    };
  };
in
{
  # user-c :: ST {host, user} -> ST {hostName, userName, module}
  # Emits user class entries: bare per-user NixOS config (no users.users.* wrapper).
  # forward-user in main-c routes these to users.users.${userName} on the host.
  fleet-demo.user-c = map-c ssh-module;
}
