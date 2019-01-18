class ciscoaci::lldp(
) {

   include ::ciscoaci::params

   file {'/etc/neutron/ciscoaci':
     ensure => 'directory',
   }

   file {'/etc/neutron/ciscoaci/ciscoaci_lldp_supervisord.conf':
     mode => '0644',
     content => template('ciscoaci/lldp_supervisord.conf.erb'),
     require => File['/etc/neutron/ciscoaci'],
   }

   file {'/etc/neutron/ciscoaci/lldp_healthcheck':
     mode => '0755',
     content => template('ciscoaci/lldp_supervisord.conf.erb'),
     require => File['/etc/neutron/ciscoaci'],
   }

}
