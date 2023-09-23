module Puppet::Parser::Functions
  newfunction(:collect_physdoms, :type => :rvalue) do |args|
    pll = args[0]
    physn = args[1]
    physdom = ''
    pll.each do |val|
        my_split = val.split(':')
        if(my_split[0] == physn)
          return(my_split[1])
        end
    end
    return ("pdom_" + physn)
  end
end

