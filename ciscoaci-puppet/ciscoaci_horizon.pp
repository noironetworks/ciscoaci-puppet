class tripleo::profile::base::ciscoaci_horizon (
  $step         = hiera('step'),
) {

  if $step >= 3 {
    class {::ciscoaci::horizon:
    }
  }
}
