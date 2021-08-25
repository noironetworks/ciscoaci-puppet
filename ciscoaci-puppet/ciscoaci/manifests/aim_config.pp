class ciscoaci::aim_config(
  $step  = hiera('step'),
  $aci_apic_systemid,
  $neutron_sql_connection,
  $aci_apic_hosts,
  $aci_apic_username,
  $aci_apic_password = '',
  $aci_apic_certname = '',
  $aci_apic_privatekey = '',
  $aci_encap_mode,
  $aci_apic_aep,
  $aci_vpc_pairs = undef,
  $aci_opflex_vlan_range = '',
  $aci_host_links = {},
  $physical_device_mappings = '',
  $aci_phys_dom_mappings = '',
  $aci_scope_names = 'False',
  $aci_scope_infra = 'False',
  $neutron_network_vlan_ranges = undef,
  $aci_aim_debug = 'False',
  $aci_provision_infra = 'False',
  $aci_provision_hostlinks = 'False',
  $aci_external_routed_domain_name = '',
  $mcast_ranges = '225.2.1.1:225.2.255.255',
  $multicast_address = '225.1.2.3'
) inherits ::ciscoaci::params
{

  #include ::ciscoaci::deps

  $default_transport_url  = os_transport_url({
        'transport' => hiera('messaging_rpc_service_name', 'rabbit'),
        'hosts'     => any2array(hiera('oslo_messaging_rpc_node_names', undef)),
        'port'      => hiera('oslo_messaging_rpc_port', '5672'),
        'username'  => hiera('oslo_messaging_rpc_user_name', 'guest'),
        'password'  => hiera('oslo_messaging_rpc_password'),
        'ssl'       => hiera('oslo_messaging_rpc_use_ssl', '0'),
  })

  aim_conf {
     'DEFAULT/debug':                             value => $aci_aim_debug;
     'DEFAULT/logging_default_format_string':     value => '"%(asctime)s.%(msecs)03d %(process)d %(thread)d %(levelname)s %(name)s [-] %(instance)s%(message)s"';
     'DEFAULT/transport_url':                     value => $default_transport_url;
     'database/connection':                       value => $neutron_sql_connection;
     'apic/apic_hosts':                           value => $aci_apic_hosts;
     'apic/apic_username':                        value => $aci_apic_username;
     'apic/apic_use_ssl':                         value => 'True';
     'apic/verify_ssl_certificate':               value => 'False';
     'apic/scope_names':                          value => $aci_scope_names;
     'aim/aim_system_id':                         value => $aci_apic_systemid;
  }  


  if !empty($aci_apic_password) {
     aim_conf{
        'apic/apic_password':                        value => $aci_apic_password;
     }
  } else {
     $private_key_file = "/etc/aim/${aci_apic_username}_private_key"

     file { $private_key_file:
       content => $aci_apic_privatekey
     }
     aim_conf{
        'apic/private_key_file':                     value => $private_key_file;
        'apic/certificate_name':                     value => $aci_apic_certname;
     }
  }

  aimctl_config {
     'DEFAULT/apic_system_id':                    value => $aci_apic_systemid;
     "apic_vmdom:$aci_apic_systemid/encap_mode":  value => $aci_encap_mode;
     "apic_vmdom:$aci_apic_systemid/mcast_ranges": value => $mcast_ranges;
     "apic_vmdom:$aci_apic_systemid/multicast_address": value => $multicast_address;
     'apic/apic_entity_profile':                  value => $aci_apic_aep;
     'apic/scope_infra':                          value => $aci_scope_infra;
     'apic/apic_provision_infra':                 value => $aci_provision_infra;
     'apic/apic_provision_hostlinks':             value => $aci_provision_hostlinks;
  }
 
  if !empty($aci_external_routed_domain_name) {
     aimctl_config {
       'apic/apic_external_routed_domain_name':     value => $aci_external_routed_domain_name;
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
  
  if !empty($aci_host_links) {
     ciscoaci::hostlinks {'xyz':
        hl_a => $aci_host_links
     }
  }

  $nvr = join(any2array($neutron_network_vlan_ranges), ',')
  if $nvr != "[]" {
     class {'ciscoaci::aim_physdoms':
       neutron_network_vlan_ranges => $neutron_network_vlan_ranges,
       aci_host_links => $aci_host_links,
       aci_phys_dom_mappings => $aci_phys_dom_mappings
     }
  }

  #if !empty($physical_device_mappings) {
  #   $hosts = hiera('neutron_plugin_compute_ciscoaci_short_node_names', '')
  #   $pmcommands = physnet_map($hosts, $physical_device_mappings, $domain)
  #}

  #file {'/etc/aim/physnet_mapping.sh':
  #  mode => '0755',
  #  content => template('ciscoaci/physnet_mapping.sh.erb'),
  #}

  file {'/etc/aim/aim_supervisord.conf':
    mode => '0644',
    content => template('ciscoaci/aim_supervisord.conf.erb'),
  }

  file {'/etc/aim/aim_healthcheck':
    mode => '0755',
    content => template('ciscoaci/aim_healthcheck.erb'),
  }

}
