class ciscoaci::aim_physdoms(
  $neutron_network_vlan_ranges = [],
  $aci_host_links = {}
) inherits ::ciscoaci::params
{

  validate_network_vlan_ranges($neutron_network_vlan_ranges)
  $hosts = collect_hostnames($aci_host_links)
  ciscoaci::physdom {$neutron_network_vlan_ranges:
     hosts => $hosts
  }

}
