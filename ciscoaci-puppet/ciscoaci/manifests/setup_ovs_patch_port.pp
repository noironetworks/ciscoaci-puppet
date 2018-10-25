   define ciscoaci::setup_ovs_patch_port($source_bridge, $target_bridge, $br_dependency, $source_patch_name ='', $target_patch_name='') {
     if $source_patch_name == '' {
        $patch_port_from = sprintf('%s_to_%s', $source_bridge[0,5],$target_bridge[0,5])
     } else {
        $patch_port_from = $source_patch_name
     }

     if $target_patch_name == '' {
        $patch_port_to = sprintf('%s_to_%s', $target_bridge[0,5],$source_bridge[0,5])
     } else {
        $patch_port_to = $target_patch_name
     }

     file { "$patch_port_from":
       path    => "/etc/sysconfig/network-scripts/ifcfg-$patch_port_from",
       mode    => '0644',
       content => template('ciscoaci/ovs-patch-intf.erb'),
     }
     if $br_dependency == '' {
       exec { "bringup_intf_${patch_port_from}":
          command => "/usr/sbin/ifup $patch_port_from",
       }
     } else {
       exec { "bringup_intf_${source_bridge}":
          command => "/usr/sbin/ifup $patch_port_from",
          require => [File["$patch_port_from"], Vs_bridge[$br_dependency]]
       }
     }
   }
