   define ciscoaci::setup_dhclient_file($real_opflex_uplink_iface) {
     #$searchstr = "macaddress_${real_opflex_uplink_iface}"
     #$macaddr = inline_template("<%= scope.lookupvar(@searchstr) %>")
     #$macaddr = generate("/bin/facter macaddress_$real_opflex_uplink_iface")
     #$macaddr = generate("/bin/cat", "/sys/class/net/$real_opflex_uplink_iface/address")

      if($::osfamily == 'Redhat') {
        $cmdstr = "/bin/bash -c '_xyz=`/bin/cat /sys/class/net/${real_opflex_uplink_iface}/address`; printf \"send dhcp-client-identifier 01:%s;\" \$_xyz > /etc/dhcp/dhclient-${real_opflex_uplink_iface}.conf' "

        exec {'dhclient-file':
          command => $cmdstr,
        }

      } elsif($::osfamily == 'Debian') {
      }
   }
