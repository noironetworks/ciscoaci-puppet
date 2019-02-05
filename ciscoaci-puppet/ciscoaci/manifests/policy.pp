class ciscoaci::policy(
) {
   $neutron_hash = loadjson('/etc/neutron/policy.json')
   $gbp_hash = loadjson('/etc/group-based-policy/policy.d/policy.json')
   $merged_hash = deep_merge($neutron_hash, $gbp_hash)

   $merged_json = inline_template("<%= @merged_hash.to_json %>")

   file {'/etc/neutron/merged-policy.json':
     content => $merged_json,
   }

   #exec {'prettyprint':
   #  command => '/bin/cat /etc/group-based-policy/policy.d/merged-policy.json.ugly | python -m json.tool > /etc/group-based-policy/policy.d/merged-policy.json',
   #  require => File['/etc/group-based-policy/policy.d/merged-policy.json.ugly'],
   #}
  
   ini_setting {'set_policy':
      ensure   => present,
      path     => '/etc/neutron/neutron.conf',
      section  => 'oslo_policy',
      setting  => 'policy_file',
      value    => '/etc/neutron/merged-policy.json',
      tag      => 'neutron_config',
   }
}
