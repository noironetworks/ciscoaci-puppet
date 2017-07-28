class tripleo::profile::base::ciscoaci_compute (
  $step         = hiera('step'),
) {

  package {'python-networking-cisco':
    ensure => absent
  }

  include ::tripleo::profile::base::neutron
  if $step >= 4 {
    class {::ciscoaci::compute:
    }
  }
}
