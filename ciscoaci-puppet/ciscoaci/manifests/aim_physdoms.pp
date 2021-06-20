class ciscoaci::aim_physdoms(
  $neutron_network_vlan_ranges = [],
  $aci_host_links = {},
  $aci_phys_dom_mappings   = []
) inherits ::ciscoaci::params
{

  validate_network_vlan_ranges($neutron_network_vlan_ranges)
  $hosts = collect_hostnames($aci_host_links)
  $physnets = collect_physnets($neutron_network_vlan_ranges)
  ciscoaci::physdom {$physnets:
     hosts => $hosts,
     my_physdoms => $aci_phys_dom_mappings
  }

}
