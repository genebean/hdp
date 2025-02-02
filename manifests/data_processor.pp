# Simple class to enable the HDP data processor
#
# @summary Simple class to enable the HDP data processor
#
# @param [HDP::Url] hdp_url
#   The url to send data to.
#
# @param [Array[HDP::Url]] extra_hdp_urls
#   Extra HDP urls to send data to.
#   Most common use case is 1 hdp.
#
# @param [Boolean] enable_reports
#   Enable sending reports to HDP
#
# @param [Boolean] manage_routes
#   Enable managing the HDP routes file
#
# @param [String[1]] facts_terminus
#
# @param [String[1]] facts_cache_terminus
#
# @param [Boolean] collect_resources
#
# @param [String[1]] keep_node_re
#
# @param [String[1]] reports
#   A string containg the list of report processors to enable
#
# @example Configuration via Hiera with default port
#   ---
#   hdp::data_processor::hdp_url: 'https://hdp.example.com/in'
#   hdp::data_processor::pe_console: 'pe-console.example.com'
#
# @example Configuration via Hiera with custom port
#   ---
#   hdp::data_processor::hdp_url: 'https://hdp.example.com:9091/in'
#   hdp::data_processor::pe_console: 'pe-console.example.com'
#
# @example Configuration in a manifest with default port
#   # Settings applied to both a master and compilers
#   class { 'profile::masters_and_compilers':
#     class { 'hdp::data_processor':
#       hdp_url  => 'https://hdp.example.com/in',
#       pe_console => 'pe-console.example.com',
#     }
#   }
#
# @example Configuration in a manifest with custom port
#   # Settings applied to both a master and compilers
#   class { 'profile::masters_and_compilers':
#     class { 'hdp::data_processor':
#       hdp_url  => 'https://hdp.example.com:9091/in',
#       pe_console => 'pe-console.example.com',
#     }
#   }
#
# @example Send data to two HDP servers
#   ---
#   hdp::data_processor::hdp_url:
#     - 'https://hdp-prod.example.com:9091/in'
#     - 'https://hdp-staging.example.com:9091/in'
#
class hdp::data_processor (
  HDP::Url $hdp_url,
  Array[HDP::Url] $extra_hdp_urls = [],
  Boolean $enable_reports = true,
  Boolean $manage_routes = true,
  Boolean $collect_resources = true,
  String[1] $facts_terminus = 'hdp',
  String[1] $facts_cache_terminus = 'hdp',
  String[1] $reports = 'puppetdb,hdp',
  String[1] $keep_node_re = '.*',
) {
  if $collect_resources {
    include hdp::resource_collector
  }

  file { '/etc/puppetlabs/hdp':
    ensure => directory,
    mode   => '0755',
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
  }

  if $manage_routes {
    file { '/etc/puppetlabs/hdp/hdp_routes.yaml':
      ensure  => file,
      owner   => pe-puppet,
      group   => pe-puppet,
      mode    => '0640',
      content => epp('hdp/hdp_routes.yaml.epp', {
          'facts_terminus'       => $facts_terminus,
          'facts_cache_terminus' => $facts_cache_terminus,
      }),
      notify  => Service['pe-puppetserver'],
    }

    ini_setting { 'enable hdp_routes.yaml':
      ensure  => present,
      path    => '/etc/puppetlabs/puppet/puppet.conf',
      section => 'master',
      setting => 'route_file',
      value   => '/etc/puppetlabs/hdp/hdp_routes.yaml',
      require => File['/etc/puppetlabs/hdp/hdp_routes.yaml'],
      notify  => Service['pe-puppetserver'],
    }
  }

  file { '/etc/puppetlabs/puppet/hdp.yaml':
    ensure  => file,
    owner   => pe-puppet,
    group   => pe-puppet,
    mode    => '0640',
    content => epp('hdp/hdp.yaml.epp', {
        'hdp_urls'   => Array($hdp_url, true) + $extra_hdp_urls,
        'keep_nodes' => $keep_node_re,
    }),
    notify  => Service['pe-puppetserver'],
  }
}
