class tripleo::profile::base::ciscoaci_compute (
  $step         = hiera('step'),
) {

  package {'python-networking-cisco':
    ensure => absent
  }

  include ::tripleo::profile::base::neutron
  #class {::ciscoaci::compute:}
}
