define ciscoaci::hostlinks(
  $hl_a
) {
  $sid = keys($hl_a)
  ciscoaci::hostlinks_a {$sid: 
     hl_a => $hl_a
  }
}


define ciscoaci::hostlinks_a(
  $hl_a
) {
  $sw_a = $hl_a[$name]
  ciscoaci::hostlinks_b {$sw_a:
     sid => $name,
  }
}

define ciscoaci::hostlinks_b(
  $sid
) {
  $hkeys = keys($name)
  ciscoaci::hostlinks_c {$hkeys:
     arr => $name,
     sid  => $sid,
  }
}


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
