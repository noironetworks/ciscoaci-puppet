class ciscoaci::neutron_opflex(
) {

   include ::ciscoaci::params

   service {'neutron-opflex-agent':
       ensure => running,
       enable => true,
   }
  
   file {'/etc/neutron-opflex-agent/neutron_opflex_supervisord.conf':
     mode => '0644',
     content => template('ciscoaci/neutron_opflex_supervisord.conf.erb'),
   }

   file {'/etc/neutron-opflex-agent/neutron_opflex_healthcheck':
     mode => '0755',
     content => template('ciscoaci/neutron_opflex_healthcheck.erb'),
   }

}
