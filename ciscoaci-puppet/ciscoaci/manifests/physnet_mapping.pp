define ciscoaci::physnet_mapping(
  $maps
) {
  ciscoaci::physnet_mapping_a {$maps:
    host => $name,
  }
}

define ciscoaci::physnet_mapping_a(
  $host
) {
  $map_l = split($name, ':')
  $physnet = $map_l[0]
  $interface = $map_l[1]
  $hname = sprintf("%s.%s",$host,$domain)
  $u = sprintf("%s-%s", $host,$physnet)
  exec {$u:
    command => "/bin/aimctl manager host-link-network-label-create $hname $physnet $interface",
    returns => [0,1]
  }
  notice("$physnet, $interface, $hname")
}
