   define ciscoaci::setup_ovs_patch_port($source_bridge, $target_bridge, $br_dependency) {
     $patch_port_from = sprintf('%s_to_%s', $source_bridge[0,5],$target_bridge[0,5])
     $patch_port_to = sprintf('%s_to_%s', $target_bridge[0,5],$source_bridge[0,5])
     file { "$patch_port_from":
       path    => "/etc/sysconfig/network-scripts/ifcfg-$patch_port_from",
       mode    => '0644',
       content => template('ciscoaci/ovs-patch-intf.erb'),
     }
     if $br_dependency == '' {
     } else {
     exec { "bringup_intf_${source_bridge}":
       command => "/usr/sbin/ifup $patch_port_from",
       require => [File["$patch_port_from"], Vs_bridge[$br_dependency]]
     }
     }
   }
