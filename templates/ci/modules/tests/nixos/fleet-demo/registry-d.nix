{ ned, ... }:
let
  inherit (ned) static-d;

  # User registry: name, groups, ssh-keys, hm (optional home-manager config).
  # Groups drive access-c policy; ssh-keys → nixos; hm → homeManager class.
  users = [
    {
      name = "alice";
      groups = [ "admin" ];
      ssh-keys = [ "ssh-ed25519 AAAlice" ];
      hm = {
        programs.git.enable = true;
      };
    }
    {
      name = "bob";
      groups = [ "deploy" ];
      ssh-keys = [ "ssh-ed25519 AAABob" ];
      hm = {
        programs.vim.enable = true;
      };
    }
    {
      name = "charlie";
      groups = [ "ops" ];
      ssh-keys = [ "ssh-ed25519 AAACharlie" ];
      maid = {
        file.home."greet".text = "hello charlie";
      };
    }
  ];
in
{
  # registry-d :: _ -> ST {name, groups, ssh-keys}
  fleet-demo.registry-d = static-d users;
}
