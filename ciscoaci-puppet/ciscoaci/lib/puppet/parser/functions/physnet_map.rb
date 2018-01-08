module Puppet::Parser::Functions
  newfunction(:physnet_map, :type => :rvalue) do |args|
    hosts = args[0]
    physmap = args[1]
    domain = args[2]
    hosts.each do |hname|
      physmap.each do |physnetmap|
        ml = physnetmap.split(':')
        physnet = ml[0]
        intf = ml[1]
        cmd = "/bin/aimctl manager host-link-network-label-delete #{hname}.#{domain} #{physnet} #{intf}"
        cmdc = "/bin/aimctl manager host-link-network-label-create #{hname}.#{domain} #{physnet} #{intf}"
        system(cmd)
        system(cmdc)
      end
    end
  end
end
