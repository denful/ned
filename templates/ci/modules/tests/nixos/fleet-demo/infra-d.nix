{ ned, ... }:
let
  inherit (ned) static-d;
  hosts = [
    {
      name = "lb-prod";
      addr = "10.0.0.1";
      system = "x86_64-linux";
      environment = "prod";
      role = "lb";
      httpPort = 80;
    }
    {
      name = "web-prod-1";
      addr = "10.0.0.2";
      system = "x86_64-linux";
      environment = "prod";
      role = "web";
      httpPort = 8080;
    }
    {
      name = "web-prod-2";
      addr = "10.0.0.3";
      system = "x86_64-linux";
      environment = "prod";
      role = "web";
      httpPort = 8080;
    }
    {
      name = "web-staging";
      addr = "10.1.0.1";
      system = "x86_64-linux";
      environment = "staging";
      role = "web";
      httpPort = 8080;
    }
    {
      name = "monitor";
      addr = "10.2.0.1";
      system = "x86_64-linux";
      environment = "infra";
      role = "service";
      httpPort = 0;
    }
  ];
in
{
  fleet-demo.infra-d = static-d hosts;
}
