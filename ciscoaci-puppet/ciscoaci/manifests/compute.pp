class ciscoaci::compute(
   $package_ensure    = 'present',
   $use_lldp_discovery = true,
) inherits ::ciscoaci::params
{
   include ::neutron::deps
   include ::ciscoaci::deps

   package {'aci-neutron-ml2-package':
     ensure => $package_ensure,
     name   => $::ciscoaci::params::aci_neutron_ml2_package,
     tag    => ['neutron-support-package', 'openstack']
   }

   package {'aci-neutron-gbp-package':
     ensure => $package_ensure,
     name   => $::ciscoaci::params::aci_neutron_gbp_package,
     tag    => ['neutron-support-package', 'openstack']
   }
 
   package {'aci-openvswitch-gbp-lib-package':
     ensure => $package_ensure,
     name   => $::ciscoaci::params::aci_openvswitch_gbp_lib_package,
     tag    => ['neutron-support-package', 'openstack']
   }

   package {'aci-neutron-opflex-agent-package':
     ensure => $package_ensure,
     name   => $::ciscoaci::params::aci_neutron_opflex_agent_package,
     tag    => ['neutron-support-package', 'openstack']
   }

   package {'aci-agent-ovs-package':
     ensure => $package_ensure,
     name   => $::ciscoaci::params::aci_agent_ovs_package,
     tag    => ['neutron-support-package', 'openstack']
   }

   package {'lldpd':
     ensure => $package_ensure,
     tag    => ['neutron-support-package', 'openstack']
   }

   if $use_lldp_discovery {
      $lldp_ensure = 'running'
      $lldp_enabled = true
      $host_agent_ensure = 'running'
      $host_agent_enabled = true
      $svc_agent_ensure = 'running'
      $svc_agent_enabled = true
   } else {
      $lldp_ensure = 'stopped'
      $lldp_enabled = false
      $host_agent_ensure = 'stopped'
      $host_agent_enabled = false
      $svc_agent_ensure = 'stopped'
      $svc_agent_enabled = false
   }

   service { 'lldpd':
     ensure      => $lldp_ensure,
     enable      => $lldp_enabled,
     hasstatus   => true,
     hasrestart  => true,
     require     => Package['lldpd'],
   }

   service { 'neutron-cisco-apic-host-agent':
     ensure      => $host_agent_ensure,
     enable      => $host_agent_enabled,
     hasstatus   => true,
     hasrestart  => true,
     require     => Package['aci-neutron-ml2-package'],
   }
   service { 'neutron-cisco-apic-service-agent':
     ensure      => 'stopped',
     enable      => false,
     hasstatus   => true,
     hasrestart  => true,
     require     => Package['aci-neutron-ml2-package'],
   }

  class {'ciscoaci::opflex':
  }

  service {'agent-ovs':
    ensure => running,
    enable => true,
    tag    => ['neutron-service']
  }

  service {'neutron-opflex-agent':
    ensure => running,
    enable => true,
    tag    => ['neutron-service']
  }

}
