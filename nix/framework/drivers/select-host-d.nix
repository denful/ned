{
  # selectHostD :: name -> ST -> ST
  # Filter stream of { host, … } items to those where host.name == name.
  priv.selectHostD = name: streamS: streamS.filter (item: item.host.name == name);
}