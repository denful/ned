{ config, ... }:
{
  # user-hm-c :: ST {host, user} -> ST {hostName, userName, module}
  # Emits homeManager class entries from the hm field in user registry.
  fleet-demo.user-hm-c = config.fleet-demo.user-class-c "hm";
}
