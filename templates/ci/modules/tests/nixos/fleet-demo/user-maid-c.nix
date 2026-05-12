{ config, ... }:
{
  # user-maid-c :: ST {host, user} -> ST {hostName, userName, module}
  # Emits maid class entries from the maid field in user registry.
  fleet-demo.user-maid-c = config.fleet-demo.user-class-c "maid";
}
