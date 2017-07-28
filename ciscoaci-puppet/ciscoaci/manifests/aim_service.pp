class ciscoaci::aim_service(
) inherits ::ciscoaci::params
{
    include ::neutron::deps
    include ::ciscoaci::deps

    service {'aim-aid':
        ensure => running,
        enable => true,
        tag    => ['neutron-service']
    }
  
    service {'aim-event-service-polling':
        ensure => running,
        enable => true,
        tag    => ['neutron-service']
    }
  
    service {'aim-event-service-rpc':
        ensure => running,
        enable => true,
        tag    => ['neutron-service']
    }

    service {'agent-ovs':
        ensure => running,
        enable => true,
        tag    => ['neutron-service']
    } 

    service {'neutron-opflex-agent':
        ensure => running,
        enable => true,
        tag    => ['neutron-service']
    } 

}
