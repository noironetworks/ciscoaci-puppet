class ciscoaci::aim_config(
  $step  = hiera('step'),
  $aci_apic_systemid,
  $neutron_sql_connection,
  $rabbit_password                      = $::os_service_default,
  $rabbit_port                          = $::os_service_default,
  $rabbit_user                          = $::os_service_default,
  $aci_apic_hosts,
  $aci_apic_username,
  $aci_apic_password,
  $aci_encap_mode,
  $aci_apic_aep,
  $aci_vpc_pairs = undef,
  $aci_opflex_vlan_range = '',
  $use_lldp_discovery = true,
  $aci_host_links = {},
  $physical_device_mappings = '',
  $aci_scope_names = 'False',
  $aci_scope_infra = 'False',
  $neutron_network_vlan_ranges = undef,
  $use_openvswitch = false,
  $aci_aim_debug = 'False',
) inherits ::ciscoaci::params
{

  include ::ciscoaci::deps

  $rabbit_host =  hiera('neutron::rabbit_host', undef)
  $rabbit_hosts = hiera('rabbitmq_node_ips', undef)

  if $rabbit_hosts {
     $rabbit_endpoints = suffix(any2array(normalize_ip_for_uri($rabbit_hosts)), ":${rabbit_port}")
     aim_conf { 
        'oslo_messaging_rabbit/rabbit_hosts':     value  => join($rabbit_endpoints, ',');
      }
  } else  {
     aim_conf { 
        'oslo_messaging_rabbit/rabbit_host':      value => $rabbit_host;
        'oslo_messaging_rabbit/rabbit_port':      value => $rabbit_port;
        'oslo_messaging_rabbit/rabbit_hosts':     value => "${rabbit_host}:${rabbit_port}";
     }
  }

  aim_conf {
     'DEFAULT/debug':                             value => $aci_aim_debug;
     'DEFAULT/logging_default_format_string':     value => '"%(asctime)s.%(msecs)03d %(process)d %(thread)d %(levelname)s %(name)s [-] %(instance)s%(message)s"';
     'database/connection':                       value => $neutron_sql_connection;
     'oslo_messaging_rabbit/rabbit_userid':       value => $rabbit_user;
     'oslo_messaging_rabbit/rabbit_password':     value => $rabbit_password;
     'apic/apic_hosts':                           value => $aci_apic_hosts;
     'apic/apic_username':                        value => $aci_apic_username;
     'apic/apic_password':                        value => $aci_apic_password;
     'apic/apic_use_ssl':                         value => 'True';
     'apic/verify_ssl_certificate':               value => 'False';
     'apic/scope_names':                          value => $aci_scope_names;
     'aim/aim_system_id':                         value => $aci_apic_systemid;
  }  

  aimctl_config {
     'DEFAULT/apic_system_id':                    value => $aci_apic_systemid;
     'apic/apic_entity_profile':                  value => $aci_apic_aep;
     'apic/scope_infra':                          value => $aci_scope_infra;
     'apic/apic_provision_infra':                 value => 'False';
     'apic/apic_provision_hostlinks':             value => 'False';
  }
 
  if $use_openvswitch == false {
     aimctl_config {
       "apic_vmdom:$aci_apic_systemid/encap_mode":  value => $aci_encap_mode;
     }
  }
 
  if $aci_encap_mode == 'vlan' {
    aimctl_config {
      "apic_vmdom:$aci_apic_systemid/vlan_ranges":  value => join(any2array($aci_opflex_vlan_range), ',')
    }
  }

  if $aci_vpc_pairs {
     aimctl_config {
        'apic/apic_vpc_pairs':                       value => $aci_vpc_pairs;
     }
  }
  
  if !$use_lldp_discovery {
     if !empty($aci_host_links) {
        ciscoaci::hostlinks {'xyz':
          hl_a => $aci_host_links
        }
     }
  }

  $nvr = join(any2array($neutron_network_vlan_ranges), ',')
  if $nvr != "[]" {
     class {'ciscoaci::aim_physdoms':
       neutron_network_vlan_ranges => $neutron_network_vlan_ranges,
       aci_host_links => $aci_host_links
     }
  }

  if $step >= 5 {
    if !empty($physical_device_mappings) {
       $hosts = hiera('neutron_plugin_compute_ciscoaci_short_node_names', '')
       $dummy = physnet_map($hosts, $physical_device_mappings, $domain)
    }
  }

}
