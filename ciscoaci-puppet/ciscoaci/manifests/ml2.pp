class ciscoaci::ml2(
   $aci_apic_systemid,
   $package_ensure    = 'present',
   $aci_mechanism_drivers = 'apic_aim',
   $aci_optimized_metadata = true,
   $neutron_network_vlan_ranges = undef,
   $sync_db = false,
   $opflex_endpoint_request_timeout = 10,
   $opflex_nat_mtu_size = 0,
   $enable_keystone_notification_purge = true,
   $type_drivers = "opflex,local,flat,vlan,gre,vxlan",
   $tenant_network_types = "opflex",
   $extension_drivers = "apic_aim,port_security",
   $gbp_extension_drivers = "aim_extension,proxy_group,apic_allowed_vm_name,apic_segmentation_label",
   $use_openvswitch = false,
   $intel_cna_nic_disable_lldp = true,
   $aci_external_routed_domain = "",
) inherits ::ciscoaci::params
{
   include ::neutron::deps
   include ::ciscoaci::deps
   include ::ciscoaci::params

   package {'apicapi-package':
     ensure => $package_ensure,
     name   => $::ciscoaci::params::apicapi_package,
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
   package {'networking-sfc-package':
       ensure => $package_ensure,
       name   => $::ciscoaci::params::networking_sfc_package,
       tag    => ['neutron-support-package', 'openstack']
   }

   package {'aci-integration-module-package':
     ensure => $package_ensure,
     name   => $::ciscoaci::params::aci_integration_module_package,
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

   service { 'neutron-cisco-apic-host-agent':
       ensure      => $host_agent_ensure,
       enable      => $host_agent_enabled,
       hasstatus   => true,
       hasrestart  => true,
       require     => Package['aci-neutron-opflex-agent-package'],
   }

   $keystone_auth_url = hiera('keystone::endpoint::admin_url')
   $keystone_admin_username = 'admin'
   $keystone_admin_password = hiera('keystone::roles::admin::password')
   neutron_plugin_cisco_aci{
     'DEFAULT/apic_system_id':                  value => $aci_apic_systemid;
     'ml2/type_drivers':                        value => $type_drivers;
     'ml2/tenant_network_types':                value => $tenant_network_types;
     'ml2/mechanism_drivers':                   value => $aci_mechanism_drivers;
     'ml2/extension_drivers':                   value => $extension_drivers; 
     'ml2_apic_aim/enable_optimized_metadata':  value => $aci_optimized_metadata;
     'ml2_apic_aim/enable_keystone_notification_purge': value => $enable_keystone_notification_purge;
     'apic_aim_auth/auth_plugin':               value => 'v3password';
     'apic_aim_auth/auth_url':                  value => "$keystone_auth_url/v3";
     'apic_aim_auth/username':                  value => $keystone_admin_username;
     'apic_aim_auth/password':                  value => $keystone_admin_password;
     'apic_aim_auth/user_domain_name':          value => 'default';
     'apic_aim_auth/project_domain_name':       value => 'default';
     'apic_aim_auth/project_name':              value => 'admin';
     'group_policy/policy_drivers':             value => 'aim_mapping';
     'group_policy/extension_drivers':          value => $gbp_extension_drivers;
     'opflex/endpoint_request_timeout':         value => $opflex_endpoint_request_timeout;
     'opflex/nat_mtu_size':                     value => $opflex_nat_mtu_size;
   }

   if lstrip($aci_external_routed_domain) != "" {
      $l3domdn = join(["uni/l3dom-" , $aci_external_routed_domain])
      neutron_plugin_cisco_aci {
         'ml2_apic_aim/l3_domain_dn':      value => $l3domdn;
      }
   }

   neutron_plugin_cisco_aci {
     'sfc/drivers':    value => 'aim';
     'flowclassifier/drivers': value => 'aim';
   }

   $ned = join(any2array($extension_drivers), ',')
      if $ned != "[]" {
     neutron_plugin_cisco_aci{
       'ml2/extension_drivers': value => $ned;
     }
   }

   $nvr = join(any2array($neutron_network_vlan_ranges), ',')
   if $nvr != "[]" {
     neutron_plugin_cisco_aci{
       'ml2_type_vlan/network_vlan_ranges': value => $nvr;
     }
   }

  file { '/etc/neutron/plugins/ml2':
     ensure => directory,
     tag => 'neutron-config-file',
  }

  file { '/etc/neutron/plugins/ml2/ml2_conf_cisco_apic.ini':
    ensure  => file,
    owner   => 'root',
    group   => 'neutron',
    require => File['/etc/neutron/plugins/ml2'],
    mode    => '0640',
    tag     => 'neutron-config-file',
  }

  file { '/etc/neutron/plugin.ini':
     ensure => link,
     target => $::ciscoaci::params::aci_neutron_config_file,
     require => File['/etc/neutron/plugins/ml2/ml2_conf_cisco_apic.ini'],
     tag => 'neutron-config-file',
  }

  class {'ciscoaci::policy':
  }

}
