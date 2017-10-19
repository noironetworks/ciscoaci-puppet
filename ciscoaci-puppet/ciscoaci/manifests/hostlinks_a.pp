define ciscoaci::hostlinks_a(
  $hl_a
) {
  $sw_a = $hl_a[$name]
  ciscoaci::hostlinks_b {$sw_a:
     sid => $name,
  }
}

