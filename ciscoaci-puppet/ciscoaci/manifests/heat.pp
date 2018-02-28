class ciscoaci::heat(
   $package_ensure    = 'present',
) inherits ::ciscoaci::params
{

   package {'aci-heat-package':
     ensure  => $package_ensure,
     name    => $::ciscoaci::params::aci_heat_package,
     tag     => ['heat-package', 'openstack'],
     require => Package['heat-common']
   }

   heat_config {
     'DEFAULT/plugin_dirs':  value => "/usr/lib64/heat,/usr/lib/heat,/usr/local/lib/heat,/usr/local/lib64/heat,/usr/lib/python2.7/site-packages/gbpautomation/heat";
   }
}
