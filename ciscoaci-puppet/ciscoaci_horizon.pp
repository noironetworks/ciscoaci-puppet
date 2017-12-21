class tripleo::profile::base::ciscoaci_horizon (
  $step         = hiera('step'),
) {

  if $step >= 4 {
    class {::ciscoaci::horizon:
    }
  }
}
