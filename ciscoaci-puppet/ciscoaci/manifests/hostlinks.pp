#sample input: { "101" => { ha => "1/1", hb => "1/2" } , "102" => { hc => '1/3'} }

define ciscoaci::hostlinks(
  $hl_a
) {
  notice("$hl_a")
  $sid = keys($hl_a)
  ciscoaci::hostlinks_a {$sid: 
     hl_a => $hl_a
  }
}


define ciscoaci::hostlinks_a(
  $hl_a
) {
  $sw_a = $hl_a[$name]
  $host_name_keys = keys($sw_a)

  ciscoaci::hostlinks_b {$host_name_keys:
     sid => $name,
     sw_a => $sw_a,
     hl_a => $hl_a,
  }
}

define ciscoaci::hostlinks_b(
  $sid,
  $sw_a,
  $hl_a,
) {
  $port = $hl_a[$sid][$name]
 
  aimctl_config {
    "apic_switch:$sid/$name": value => $port;
  }
}

