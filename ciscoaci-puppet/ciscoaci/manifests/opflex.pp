class ciscoaci::opflex(
  $aci_apic_systemid,
  $aci_opflex_uplink_interface,
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
) {

   include ::ciscoaci::params

   if($::osfamily == 'Redhat') {
     $real_opflex_uplink_iface = "vlan${aci_apic_infravlan}"
   } elsif ($::osfamily == 'Debian') {
     $real_opflex_uplink_iface = "${aci_opflex_uplink_interface}.{$aci_apic_infravlan}"
   }

   if ($aci_opflex_encap_mode == 'vxlan') {
     file {'agent-conf':
       path => '/etc/opflex-agent-ovs/conf.d/opflex-agent-ovs.conf',
       mode => '0644',
       content => template('ciscoaci/opflex-agent-ovs.conf.erb'),
       require => Package['aci-agent-ovs-package'],
       tag    => 'neutron-config-file'
     }
   }
   elsif ($aci_opflex_encap_mode == 'vlan') {
     if $opflex_target_bridge_to_patch != '' {
       $v_opflex_encap_iface = sprintf('%s_to_%s', $aci_opflex_ovs_bridge[0,5],$opflex_target_bridge_to_patch[0,5])
       ciscoaci::setup_ovs_patch_port{ 'source':
         source_bridge => $aci_opflex_ovs_bridge,
         target_bridge => $opflex_target_bridge_to_patch,
         br_dependency => $aci_opflex_ovs_bridge,
       }
       ciscoaci::setup_ovs_patch_port{ 'target':
         source_bridge => $opflex_target_bridge_to_patch,
         target_bridge => $aci_opflex_ovs_bridge,
         br_dependency => $aci_opflex_ovs_bridge,
       }
       file {'agent-conf':
         path => '/etc/opflex-agent-ovs/conf.d/opflex-agent-ovs.conf',
         mode => '0644',
         content => template('ciscoaci/opflex-agent-ovs-vlan.conf.erb'),
         require => Package['aci-agent-ovs-package'],
         tag    => 'neutron-config-file'
       }
     } else {
       $v_opflex_encap_iface = $aci_opflex_uplink_interface
       file {'agent-conf':
         path => '/etc/opflex-agent-ovs/conf.d/opflex-agent-ovs.conf',
         mode => '0644',
         content => template('ciscoaci/opflex-agent-ovs-vlan.conf.erb'),
         require => Package['aci-agent-ovs-package'],
         tag    => 'neutron-config-file'
       }
     }
   }


   $netconfig_yaml = "/tmp/opflex_netconfig_yaml"
   file {'opflex_osnetconfig_yaml':
     path  => $netconfig_yaml,
     mode  => '0644',
     content  => template('ciscoaci/osnetconfig.yaml.erb')
   }
   exec {'osnetconfig_fail':
     command  => "/bin/os-net-config -v -c $netconfig_yaml",
     returns  => [0,1],
     require  => File['opflex_osnetconfig_yaml'],
   }
   
   $intf_file = "/etc/sysconfig/network-scripts/ifcfg-$real_opflex_uplink_iface"
   exec {'disable_peerdns':
     command => "/bin/echo 'PEERDNS=no' >> $intf_file",
     require => Exec['osnetconfig_fail'],
   }

   ciscoaci::setup_dhclient_file {'dummy':
     real_opflex_uplink_iface => $real_opflex_uplink_iface,
     require => Exec['osnetconfig_fail', 'disable_peerdns'],
   }

   exec {'toggle_iface':
     command  => "/sbin/ifdown $real_opflex_uplink_iface; sleep 15; /sbin/ifup $real_opflex_uplink_iface",
     require  => Ciscoaci::Setup_dhclient_file['dummy'], 
   }

   firewall {'297 vxlan 8472':
      action => 'accept',
      dport  => '8472',
      proto  => 'udp',
      state  => ['NEW'],
   }

   vs_bridge {$aci_opflex_ovs_bridge:
     ensure => present,
     external_ids => "bridge-id=$aci_opflex_ovs_bridge",
   }

   exec {'fix_bridge_openflow_version':
      command => "/usr/bin/ovs-vsctl set bridge $aci_opflex_ovs_bridge protocols=[]",
      require => [Vs_bridge[$aci_opflex_ovs_bridge]],
   }

   if ($aci_opflex_encap_mode == 'vxlan') {
      exec {'add_vxlan_port':
         command => "/usr/bin/ovs-vsctl add-port $aci_opflex_ovs_bridge $opflex_encap_iface -- set Interface $opflex_encap_iface type=vxlan options:remote_ip=flow options:key=flow options:dst_port=8472",
         unless => "/usr/bin/ovs-vsctl show | /bin/grep $opflex_encap_iface ",
         returns => [0,1,2],
         require => [File['agent-conf'], Vs_bridge[$aci_opflex_ovs_bridge]],
      }
   }

}
