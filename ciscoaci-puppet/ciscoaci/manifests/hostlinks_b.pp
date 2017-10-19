define ciscoaci::hostlinks_b(
  $sid
) {
  $hkeys = keys($name)
  ciscoaci::hostlinks_c {$hkeys:
     arr => $name,
     sid  => $sid,
  }
}
