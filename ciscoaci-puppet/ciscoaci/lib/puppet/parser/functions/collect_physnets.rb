module Puppet::Parser::Functions
  newfunction(:collect_physnets, :type => :rvalue) do |args|
    physnets = []
    pll = args[0]
    pll.each do |val|
        parr = val.split(':')
        physnets.insert(0, parr[0])
    end
    physarr = physnets.uniq
    return physarr
  end
end
