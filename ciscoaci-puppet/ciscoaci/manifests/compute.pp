class ciscoaci::compute(
   $package_ensure    = 'present',
   $use_openvswitch = false,
   $intel_cna_nic_disable_lldp = true,
   $default_transport_url = $::os_service_default,
) inherits ::ciscoaci::params
{
   include ::neutron::deps
   include ::ciscoaci::deps

   package {'aci-neutron-gbp-package':
     ensure => $package_ensure,
     name   => $::ciscoaci::params::aci_neutron_gbp_package,
     tag    => ['neutron-support-package', 'openstack']
   }
 
   package {'aci-neutron-opflex-agent-package':
     ensure => $package_ensure,
     name   => $::ciscoaci::params::aci_neutron_opflex_agent_package,
     tag    => ['neutron-support-package', 'openstack']
   }

   package {'lldpd':
     ensure => $package_ensure,
     tag    => ['neutron-support-package', 'openstack']
   }
 
   package {'apicapi-package':
     ensure => $package_ensure,
     name   => $::ciscoaci::params::apicapi_package,
     tag    => ['neutron-support-package', 'openstack']
   }

   exec {'patchfix':
     command => "/usr/bin/touch /etc/neutron/plugins/ml2/ml2_conf_cisco_apic.ini"
   }
   service { 'neutron-cisco-apic-host-agent':
     ensure      => $host_agent_ensure,
     enable      => $host_agent_enabled,
     hasstatus   => true,
     hasrestart  => true,
     require     => [Package['aci-neutron-opflex-agent-package'], Exec['patchfix']],
   }

   if $use_openvswitch == false {
      neutron_agent_ovs {
        'securitygroup/firewall_driver': value => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver';
      }

      class {'ciscoaci::opflex':
      }
    
   } else {
      ciscoaci::setup_ovs_patch_port{ 'source':
         source_bridge => 'br-ex',
         target_bridge => 'br-int',
         br_dependency => '',
      }
      ciscoaci::setup_ovs_patch_port{ 'target':
         source_bridge => 'br-int',
         target_bridge => 'br-ex',
         br_dependency => '',
      }
      service {'neutron-opflex-agent':
        ensure => stopped,
        enable => false,
        tag    => ['neutron-service']
      }
   }

}
