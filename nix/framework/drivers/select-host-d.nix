{
  # selectHostD :: name -> ST -> ST
  # Filter stream of { host, … } items to those where host.name == name.
  ned.selectHostD = name: streamS: streamS.filter (item: item.host.name == name);
}
