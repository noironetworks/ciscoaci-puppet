class tripleo::profile::base::ciscoaci_opflex (
  $bootstrap_node = hiera('bootstrap_nodeid', undef),
  $step         = Integer(hiera('step')),
) {

  #if $step >= 3 {
    class {::ciscoaci::opflex:} 
  #}
}
