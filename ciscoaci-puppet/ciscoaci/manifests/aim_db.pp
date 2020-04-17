class ciscoaci::aim_db(
  $use_openvswitch  = false,
) inherits ::ciscoaci::params
{
     include ::neutron::deps
     include ::ciscoaci::deps

     exec { 'gbp-db-sync':
       command     => '/bin/gbp-db-manage --config-file /var/lib/config-data/neutron/etc/neutron/neutron.conf upgrade head',
       logoutput   => on_failure,
       require     => Package['aci-neutron-gbp-package'],
       subscribe   => [
         Anchor['neutron::install::end'],
         Anchor['neutron::config::end'],
         Anchor['neutron::dbsync::begin'],
       ],
       notify      => Anchor['neutron::dbsync::end'],
       refreshonly => true,
       #tag    => 'neutron_plugin_cisco_aci',
     }

     exec {'aim-db-migrate':
       command  => "/usr/bin/aimctl db-migration upgrade head",
       require  => Package['aci-integration-module-package'],
       subscribe   => [
         Anchor['neutron::install::end'],
         Anchor['neutron::config::end'],
         Anchor['neutron::dbsync::begin'],
       ],
       notify  => Anchor['neutron::dbsync::end'],
       refreshonly => true
     }

     exec {'aim-config-update':
       command  => "/usr/bin/aimctl config update",
       require  => Exec['aim-db-migrate']
     }

     exec {'aim-create-infra':
       command => "/usr/bin/aimctl infra create",
       require => Exec['aim-config-update'],
     }

     exec {'aim-load-domains':
       command => "/usr/bin/aimctl manager load-domains",
       require => Exec['aim-config-update'],
     }

     exec {'sfc-db-migrate':
        command  => "/usr/bin/neutron-db-manage --subproject networking-sfc upgrade head",
        require  => Package['aci-integration-module-package'],
        subscribe   => [
          Anchor['neutron::install::end'],
          Anchor['neutron::config::end'],
          Anchor['neutron::dbsync::begin'],
        ],
        notify  => Anchor['neutron::dbsync::end'],
        refreshonly => true
     }
}
