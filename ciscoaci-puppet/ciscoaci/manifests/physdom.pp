define ciscoaci::physdom(
  $hosts,
  $my_physdoms
) {
  #$pnet_l = split($name, ':')
  #$pnet = $pnet_l[0]
  $physdom = collect_physdoms($my_physdoms, $name)
  aimctl_config {
    #"apic_physical_network:$pnet/hosts": value => $hosts;
    #"apic_physical_network:$pnet/segment_type": value => 'vlan';
    "apic_physdom:$physdom/encap_mode": value => 'vlan';
  }
}

