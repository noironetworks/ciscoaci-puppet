define ciscoaci::hostlinks(
  $hl_a
) {
  $sid = keys($hl_a)
  notice($sid)
  ciscoaci::hostlinks_a {$sid: 
     hl_a => $hl_a
  }
}

