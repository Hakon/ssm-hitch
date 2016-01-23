# == Class hitch::config
#
# This class is called from hitch for service config.
#
class hitch::config(
  $frontend          = $::hitch::params::frontend,
  $backend           = $::hitch::params::backend,
  $config_root       = $::hitch::params::config_root,
  $purge_config_root = $::hitch::params::purge_config_root,
  $file_owner        = $::hitch::params::file_owner,
  $user              = $::hitch::params::user,
  $group             = $::hitch::params::group,
  $config_file       = $::hitch::params::config_file,
  $dhparams_file     = $::hitch::params::dhparams_file,
  $dhparams_content  = $::hitch::params::dhparams_content,
  $domains           = $::hitch::params::domains,
  $write_proxy_v2    = $::hitch::params::write_proxy_v2,
  $ciphers           = $::hitch::params::ciphers,
) inherits ::hitch::params {

  validate_absolute_path($config_root)
  validate_absolute_path($config_file)
  validate_absolute_path($dhparams_file)

  if $dhparams_content {
    validate_re($dhparams_content, 'BEGIN DH PARAMETERS')
  }

  file { $config_root:
    ensure  => directory,
    recurse => true,
    purge   => $purge_config_root,
    owner   => $file_owner,
    group   => $group,
    mode    => '0750',
  }

  concat { $config_file:
    ensure => present,
  }

  if $dhparams_content {
    file { $dhparams_file:
      ensure  => present,
      owner   => $file_owner,
      group   => $group,
      mode    => '0640',
      content => $dhparams_content,
    }
  }
  else {
    exec { "${title} generate dhparams":
      path    => '/usr/local/bin:/usr/bin:/bin',
      command => "openssl dhparam 2048 -out ${dhparams_file}",
      creates => $dhparams_file,
    }
    ->
    file { $dhparams_file:
      ensure => present,
      owner  => $file_owner,
      group  => $group,
      mode   => '0640',
    }
  }

  concat::fragment { "${title} config":
    content => template('hitch/hitch.conf.erb'),
    target  => $config_file,
  }

  $domain_defaults = {
    config_root   => $config_root,
    config_file   => $config_file,
    owner         => $file_owner,
    group         => $group,
    dhparams_file => $dhparams_file,
  }
  create_resources('hitch::domain', $domains, $domain_defaults)
}
