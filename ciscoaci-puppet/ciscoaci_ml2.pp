class tripleo::profile::base::ciscoaci_ml2 (
  $step         = Integer(hiera('step')),
) {

  package {'python-networking-cisco':
    ensure => absent
  }

  include ::tripleo::profile::base::neutron
  #if $step >= 4 {
    class {::ciscoaci::ml2:
       #sync_db => $sync_db,
    } 

  #}
}
