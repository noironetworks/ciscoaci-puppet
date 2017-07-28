class tripleo::profile::base::ciscoaci_heat (
  $step         = hiera('step'),
) {

  if $step >= 4 {
    class {::ciscoaci::heat:
    }
  }
}
