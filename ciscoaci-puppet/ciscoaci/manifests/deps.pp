class ciscoaci::deps {

   #anchor {'ciscoaci::stop-openvswitch-agent':}
   #-> Exec<| tag == 'stop-openvswitch-agent' |>

   Anchor['neutron::config::begin']
   -> File<| tag == 'neutron-config-file' |>
   ~> Anchor['neutron::config::end']

   Anchor['neutron::config::begin'] -> Neutron_plugin_cisco_aci<||> ~> Anchor['neutron::config::end']

   Anchor['neutron::config::begin'] -> Aim_conf<||> ~> Anchor['neutron::config::end']
   Anchor['neutron::config::begin'] -> Aimctl_config<||> ~> Anchor['neutron::config::end']

   #Anchor['neutron::service::end'] ~> Anchor['ciscoaci::stop-openvswitch-agent']
}
