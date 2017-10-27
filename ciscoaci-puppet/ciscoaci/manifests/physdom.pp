define ciscoaci::physdom(
  $hosts
) {
  $pnet_l = split($name, ':')
  $pnet = $pnet_l[0]
  $physdom = sprintf("pdom_%s", $pnet)
  aimctl_config {
    "apic_physical_network:$pnet/hosts": value => $hosts;
    "apic_physical_network:$pnet/segment_type": value => 'vlan';
    "apic_physdom:$physdom/#dummy": value => 'dummy';
  }
}

