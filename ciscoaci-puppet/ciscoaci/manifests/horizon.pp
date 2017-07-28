class ciscoaci::horizon(
   $package_ensure    = 'present',
) inherits ::ciscoaci::params
{

   package {'aci-horizon-package':
     ensure  => $package_ensure,
     name    => $::ciscoaci::params::aci_horizon_package,
     tag     => ['horizon-package', 'openstack'],
     require => Package['horizon']
   }
}
