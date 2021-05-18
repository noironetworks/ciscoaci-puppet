class ciscoaci::neutron_opflex(
)
{
   include ::ciscoaci::params
   include ::ciscoaci::opflex_params

   $opflex_notification_socket = $::ciscoaci::opflex_params::opflex_notification_socket
   $opflex_inspect_socket = $::ciscoaci::opflex_params::opflex_inspect_socket

   service {'neutron-opflex-agent':
       ensure => running,
       enable => true,
   }
      
   file {'/etc/neutron/neutron_opflex_supervisord.conf':
     mode => '0644',
     content => template('ciscoaci/neutron_opflex_supervisord.conf.erb'),
   }

   file {'/etc/neutron/neutron_opflex_healthcheck':
     mode => '0755',
     content => template('ciscoaci/neutron_opflex_healthcheck.erb'),
   }

   file {'/etc/neutron/neutron_opflex.conf':
     mode => '0644',
     content => template('ciscoaci/neutron_opflex.conf.erb'),
   }
}
