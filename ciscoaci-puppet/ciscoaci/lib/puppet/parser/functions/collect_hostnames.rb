module Puppet::Parser::Functions
  newfunction(:collect_hostnames, :type => :rvalue) do |args|
    hosts = []
    hla = args[0]
    hla.each do |key, list|
      list.each do |val|
        val.each do |hname, port|
          hosts.insert(0, hname)
        end
      end
    end
    harr = hosts.uniq
    return harr.join(",")
  end
end
