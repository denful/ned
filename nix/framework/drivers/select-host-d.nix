{
  # select-host-d :: name -> ST -> ST
  # Filter stream of { host, … } items to those where host.name == name.
  ned.select-host-d = name: stream-s: stream-s.filter (item: item.host.name == name);
}
