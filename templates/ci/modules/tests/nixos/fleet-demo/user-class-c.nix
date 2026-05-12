{ ned, ... }:
let
  inherit (ned) st;
in
{
  # user-class-c :: field -> ST {host, user} -> ST {hostName, userName, module}
  # Generic emitter for user-scoped class sinks.
  # Reads `field` from user registry entry; users without the field emit nothing.
  # Usage: user-class-c "hm"   → homeManager class emitter
  #        user-class-c "maid" → maid class emitter
  fleet-demo.user-class-c = field: stream:
    stream (st.flatMap ({ host, user }:
      if user ? ${field}
      then st { hostName = host.name; userName = user.name; module = user.${field}; }
      else st.fromList [ ]
    ));
}
