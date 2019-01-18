class tripleo::profile::base::ciscoaci_aim (
  $bootstrap_node = hiera('bootstrap_nodeid', undef),
  $step         = Integer(hiera('step')),
) {

  class {::ciscoaci::aim_config:} 
}
