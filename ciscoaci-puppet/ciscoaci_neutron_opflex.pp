class tripleo::profile::base::ciscoaci_neutron_opflex (
  $bootstrap_node = hiera('bootstrap_nodeid', undef),
  $step         = Integer(hiera('step')),
) {
    class {::ciscoaci::neutron_opflex:}

}
