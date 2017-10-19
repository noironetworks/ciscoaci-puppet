define ciscoaci::hostlinks_c(
  $arr,
  $sid
) {
  $host = $name
  $port = $arr[$name]
  notice("c $sid $host $port")
  aimctl_config {
    "apic_switch:$sid/$host": value => $port;
  }
}
