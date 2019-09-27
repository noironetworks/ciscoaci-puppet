#sample input: { "101" => { ha => "1/1", hb => "1/2" } , "102" => { hc => '1/3'} }
#{"101" =>
#             {
#               "fab11-compute-1|bond0" => "vpc-101-102/sauto-po-101-1-25-and-102-1-25",
#               "fab11-compute-2|bond0" => "vpc-101-102/sauto-po-101-1-26-and-102-1-26"
#             },
#       "102" =>
#             {
#               "fab11-compute-1|bond0" => "vpc-101-102/sauto-po-101-1-25-and-102-1-25",
#               "fab11-compute-2|bond0" => "vpc-101-102/sauto-po-101-1-26-and-102-1-26",
#             }
#      }

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
)
{
  $switch_name = $name
  $hosts_arr = $hl_a[$name]
  $host_names = keys($hosts_arr)
  #suffix switch id to avoid duplicate resources in vpc case
  $sw_host_names = suffix($host_names, ";$switch_name")

  ciscoaci::hostlinks_b{$sw_host_names:
    hl_a => $hl_a
  }
}

define ciscoaci::hostlinks_b(
  $hl_a
) {

  $host_name_l = split($name, ';')
  $host_name = $host_name_l[0]
  $switch_name = $host_name_l[1]
  $port = $hl_a[$switch_name][$host_name]
  notice("Switch name: $switch_name, host_name: $host_name, port $port")
  aimctl_config {
    "apic_switch:$switch_name/$host_name": value => $port;
  }
}
