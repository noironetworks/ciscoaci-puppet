module Puppet::Parser::Functions
  newfunction(:physnet_map, :type => :rvalue) do |args|
    hosts = args[0]
    physmap = args[1]
    domain = args[2]
    retstr = "\n"
    hosts.each do |hname|
      physmap.each do |physnetmap|
        ml = physnetmap.split(':')
        physnet = ml[0]
        intfs = ml.drop(1)
        puts intfs
        intfs.each do |intf|
           retstr << "/bin/aimctl manager host-link-network-label-delete #{hname}.#{domain} #{physnet} #{intf} \n"
           retstr << "/bin/aimctl manager host-link-network-label-create #{hname}.#{domain} #{physnet} #{intf} \n"
        end
      end
    end
    return retstr
  end
end
