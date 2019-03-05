class tripleo::profile::base::ciscoaci_ml2 (
  $step         = Integer(hiera('step')),
) {

  package {'python-networking-cisco':
    ensure => absent
  }

  include ::tripleo::profile::base::neutron
  class {::ciscoaci::ml2: } 

}
