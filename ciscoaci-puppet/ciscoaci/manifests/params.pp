class ciscoaci::params {
  include ::openstacklib::defaults

  if ($::osfamily == 'Redhat') {
     $aci_neutron_ml2_package = 'neutron-ml2-driver-apic'
     $aci_neutron_gbp_package = 'openstack-neutron-gbp'
     $aci_openvswitch_gbp_lib_package = 'openvswitch-gbp-lib'
     $aci_neutron_opflex_agent_package = 'neutron-opflex-agent'
     $aci_gbp_libmodel_package = 'libmodelgpb'
     $aci_integration_module_package = 'aci-integration-module'
     $aci_agent_ovs_package = 'agent-ovs'
     $aci_horizon_package = 'openstack-dashboard-gbp'
     $aci_gbpclient_package = 'python-gbpclient'
     $aci_heat_package = 'openstack-heat-gbp'
     $apicapi_package = 'apicapi'
     $aci_neutron_config_file = '/etc/neutron/plugins/ml2/ml2_conf_cisco_apic.ini'
  }
}
