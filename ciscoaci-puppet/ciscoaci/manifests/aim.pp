class ciscoaci::aim(
   $aci_apic_systemid,
   $package_ensure    = 'present',
   $use_lldp_discovery = true,
   $aci_optimized_metadata = true,
   $neutron_network_vlan_ranges = undef,
   $sync_db = false,
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

   package {'aci-integration-module-package':
     ensure => $package_ensure,
     name   => $::ciscoaci::params::aci_integration_module_package,
     tag    => ['neutron-support-package', 'openstack']
   }

   package {'aci-agent-ovs-package':
     ensure => $package_ensure,
     name   => $::ciscoaci::params::aci_agent_ovs_package,
     tag    => ['neutron-support-package', 'openstack']
   }

   package {'aci-gbpclient-package':
     ensure => $package_ensure,
     name   => $::ciscoaci::params::aci_gbpclient_package,
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
     ensure      => $svc_agent_ensure,
     enable      => $svc_agent_enabled,
     hasstatus   => true,
     hasrestart  => true,
     require     => Package['aci-neutron-ml2-package'],
   }

   $keystone_auth_url = hiera('keystone::endpoint::admin_url')
   $keystone_admin_username = 'admin'
   $keystone_admin_password = hiera('keystone::roles::admin::password')
   neutron_plugin_cisco_aci{
     'DEFAULT/apic_system_id':                  value => $aci_apic_systemid;
     'ml2/type_drivers':                        value => "opflex,local,flat,vlan,gre,vxlan";
     'ml2/tenant_network_types':                value => "opflex";
     'ml2/mechanism_drivers':                   value => "apic_aim";
     'ml2/extension_drivers':                   value => "apic_aim,port_security";
     'ml2_apic_aim/enable_optimized_metadata':  value => $aci_optimized_metadata;
     'apic_aim_auth/auth_plugin':               value => 'v3password';
     'apic_aim_auth/auth_url':                  value => "$keystone_auth_url/v3";
     'apic_aim_auth/username':                  value => $keystone_admin_username;
     'apic_aim_auth/password':                  value => $keystone_admin_password;
     'apic_aim_auth/user_domain_name':          value => 'default';
     'apic_aim_auth/project_domain_name':       value => 'default';
     'apic_aim_auth/project_name':              value => 'admin';
     'group_policy/policy_drivers':             value => 'aim_mapping';
     'group_policy/extension_drivers':          value => 'aim_extension,proxy_group,apic_allowed_vm_name,apic_segmentation_label';
   }

   $nvr = join(any2array($neutron_network_vlan_ranges), ',')
   if $nvr != '' {
     neutron_plugin_cisco_aci{
       'ml2_type_vlan/network_vlan_ranges': value => $nvr;
     }
   }

  #plugin.ini
  if $::osfamily == 'Debian' {
    file_line { '/etc/default/neutron-server:NEUTRON_PLUGIN_CONFIG':
      path  => '/etc/default/neutron-server',
      match => '^NEUTRON_PLUGIN_CONFIG=(.*)$',
      line  => "NEUTRON_PLUGIN_CONFIG=${::ciscoaci::params::aci_neutron_config_file}",
      tag   => 'neutron-file-line',
    }
  }

  # In RH, this link is used to start Neutron process but in Debian, it's used only
  # to manage database synchronization.
  if defined(File['/etc/neutron/plugin.ini']) {
    File <| path == '/etc/neutron/plugin.ini' |> { target => $::ciscoaci::params::aci_neutron_config_file }
  }
  else {
    file {'/etc/neutron/plugin.ini':
      ensure => link,
      target => $::ciscoaci::params::aci_neutron_config_file,
      tag    => 'neutron-config-file'
    }
  }

  class {'ciscoaci::policy':
    require => Package['aci-neutron-gbp-package']
  }

  #dbsync
  if $sync_db {
     class {'ciscoaci::aim_db': 
     }
  }

  #aimconfig
  class {'ciscoaci::aim_config':
  }

  class {'ciscoaci::opflex':
  }

  class {'ciscoaci::aim_service':
  }

}
