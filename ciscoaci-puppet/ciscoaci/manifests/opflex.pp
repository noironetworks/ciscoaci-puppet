class ciscoaci::opflex(
  $aci_apic_systemid,
  $aci_opflex_uplink_interface,
  $opflex_enable_bond_watch,
  $aci_apic_infra_subnet_gateway = '10.0.0.30',
  $aci_apic_infra_anycast_address = '10.0.0.32',
  $aci_apic_infravlan = '4093',
  $aci_opflex_ovs_bridge = 'br-fabric',
  $aci_opflex_encap_mode = 'vxlan',

  $opflex_log_level = 'debug2',
  $opflex_peer_port = '8009',
  $opflex_ssl_mode = 'encrypted',
  $opflex_endpoint_dir = '/var/lib/opflex-agent-ovs/endpoints',
  $opflex_encap_iface = 'br-fab_vxlan0',
  $opflex_remote_port = '8472',
  $opflex_virtual_router = 'true',
  $opflex_router_advertisement = 'false',
  $opflex_virtual_router_mac = '00:22:bd:f8:19:ff',
  $opflex_virtual_dhcp_enabled = 'true',
  $opflex_virtual_dhcp_mac = '00:22:bd:f8:19:ff',
  $opflex_cache_dir = '/var/lib/opflex-agent-ovs/ids',
  $opflex_target_bridge_to_patch = 'br-ex',
  $neutron_external_bridge = 'br-ex',
  $opflex_interface_type = 'linux',
  $opflex_interface_mtu = '1600',
  $opflex_nat_mtu_size = '1600',
) {

   include ::ciscoaci::params

   package {'aci-agent-ovs-package':
       ensure => $package_ensure,
       name   => $::ciscoaci::params::aci_agent_ovs_package,
       notify => Service['opflex-agent'],
       tag    => ['neutron-support-package', 'openstack']
   }

   service {'opflex-agent':
       ensure => running,
       enable => true,
       notify => Service['mcast-daemon'],
   }

   service {'mcast-daemon':
       ensure => running,
       enable => true,
   }

   service {'neutron-opflex-agent':
       ensure => running,
       enable => true,
   }

   $real_opflex_uplink_iface = "${aci_opflex_uplink_interface}.${$aci_apic_infravlan}"

   if ($aci_opflex_encap_mode == 'vxlan') {
     file {'agent-conf':
       path => '/etc/opflex-agent-ovs/conf.d/opflex-agent-ovs.conf',
       mode => '0644',
       content => template('ciscoaci/opflex-agent-ovs.conf.erb'),
       require => Package['aci-agent-ovs-package'],
       notify => Service['opflex-agent','mcast-daemon'],
     }
   }
   elsif ($aci_opflex_encap_mode == 'vlan') {
     if $opflex_target_bridge_to_patch != '' {
       $v_opflex_encap_iface = sprintf('%s_to_%s', $aci_opflex_ovs_bridge[0,5],$opflex_target_bridge_to_patch[0,5])
#       ciscoaci::setup_ovs_patch_port{ 'source':
#         source_bridge => $aci_opflex_ovs_bridge,
#         target_bridge => $opflex_target_bridge_to_patch,
#         br_dependency => $aci_opflex_ovs_bridge,
#       }
#       ciscoaci::setup_ovs_patch_port{ 'target':
#         source_bridge => $opflex_target_bridge_to_patch,
#         target_bridge => $aci_opflex_ovs_bridge,
#         br_dependency => $aci_opflex_ovs_bridge,
#       }
       file {'agent-conf':
         path => '/etc/opflex-agent-ovs/conf.d/opflex-agent-ovs.conf',
         mode => '0644',
         content => template('ciscoaci/opflex-agent-ovs-vlan.conf.erb'),
         require => Package['aci-agent-ovs-package'],
         notify => Service['opflex-agent','mcast-daemon'],
       }
     } else {
       $v_opflex_encap_iface = $aci_opflex_uplink_interface
       file {'agent-conf':
         path => '/etc/opflex-agent-ovs/conf.d/opflex-agent-ovs.conf',
         mode => '0644',
         content => template('ciscoaci/opflex-agent-ovs-vlan.conf.erb'),
         require => Package['aci-agent-ovs-package'],
         notify => Service['opflex-agent','mcast-daemon'],
       }
     }
   }

#   ciscoaci::setup_dhclient_file {'dummy':
#     interface_name => $real_opflex_uplink_iface,
#     opflex_uplink_iface => $aci_opflex_uplink_interface,
#   }


   file {'/etc/opflex-agent-ovs/opflex_supervisord.conf':
     mode => '0644',
     content => template('ciscoaci/opflex_supervisord.conf.erb'),
   }

   file {'/etc/opflex-agent-ovs/opflex_healthcheck':
     mode => '0755',
     content => template('ciscoaci/opflex_healthcheck.erb'),
   }

}
