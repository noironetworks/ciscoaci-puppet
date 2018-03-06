class ciscoaci::aim_db(
) inherits ::ciscoaci::params
{
     include ::neutron::deps
     include ::ciscoaci::deps

     exec { 'apic-ml2-db-sync':
       command     => '/bin/apic-ml2-db-manage --config-file /etc/neutron/neutron.conf upgrade head',
       logoutput   => on_failure,
       require     => Package['aci-neutron-ml2-package'],
       subscribe   => [
         Anchor['neutron::install::end'],
         Anchor['neutron::config::end'],
         Anchor['neutron::dbsync::begin'],
         Exec['neutron-db-sync']
       ],
       notify      => Anchor['neutron::dbsync::end'],
       refreshonly => true
     }

     exec { 'gbp-db-sync':
       command     => '/bin/gbp-db-manage --config-file /etc/neutron/neutron.conf upgrade head',
       logoutput   => on_failure,
       require     => Package['aci-neutron-gbp-package'],
       subscribe   => [
         Anchor['neutron::install::end'],
         Anchor['neutron::config::end'],
         Anchor['neutron::dbsync::begin'],
         Exec['neutron-db-sync']
       ],
       notify      => Anchor['neutron::dbsync::end'],
       refreshonly => true
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
}
