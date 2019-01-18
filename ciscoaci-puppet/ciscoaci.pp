class tripleo::profile::base::ciscoaci (
  $bootstrap_node = hiera('bootstrap_nodeid', undef),
  $step         = Integer(hiera('step')),
  $rabbit_hosts = hiera('rabbitmq_node_ips', undef),
  $rabbit_port  = hiera('neutron::rabbit_port', 5672),
) {

  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  package {'python-networking-cisco':
    ensure => absent
  }

  include ::tripleo::profile::base::neutron
  if $step >= 4 {
    class {::ciscoaci::aim:
       sync_db => $sync_db,
    } 

  }
}
