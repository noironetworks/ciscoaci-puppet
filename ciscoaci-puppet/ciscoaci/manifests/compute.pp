class ciscoaci::compute(
   $package_ensure    = 'present',
   $use_lldp_discovery = true,
   $use_openvswitch = false,
   $intel_cna_nic_disable_lldp = true,
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
 
   package {'aci-neutron-opflex-agent-package':
     ensure => $package_ensure,
     name   => $::ciscoaci::params::aci_neutron_opflex_agent_package,
     tag    => ['neutron-support-package', 'openstack']
   }

   if $use_openvswitch == false {
     package {'aci-agent-ovs-package':
       ensure => $package_ensure,
       name   => $::ciscoaci::params::aci_agent_ovs_package,
       tag    => ['neutron-support-package', 'openstack']
     }
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
      if $intel_cna_nic_disable_lldp == true {
         $script = "#!/bin/bash
if [ -d '/sys/kernel/debug/i40e' ]; then
  for i in `ls /sys/kernel/debug/i40e` ; do
     echo lldp stop >> /sys/kernel/debug/i40e/\${i}/command
  done
fi
"

        file {'scriptfile':
          path => "/tmp/nic.sh",
          mode => "0755",
          content => $script
        }

        exec {'disableniclldp':
          command => '/tmp/nic.sh ',
          require => File['scriptfile']
        }
      }
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
     require     => Package['aci-neutron-opflex-agent-package','aci-neutron-ml2-package'],
   }

   if $use_openvswitch == false {
      neutron_agent_ovs {
        'securitygroup/firewall_driver': value => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver';
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
