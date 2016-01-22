# == Define hitch::domain
#
# This define installs pem files to the config root, and configures
# them in the hitch config file
#
define hitch::domain (
  $ensure           = present,
  $cacert_content   = undef,
  $cacert_source    = undef,
  $cert_content     = undef,
  $cert_source      = undef,
  $config_root      = $::hitch::config::config_root,
  $config_file      = $::hitch::config::config_file,
  $owner            = $::hitch::config::file_owner,
  $group            = $::hitch::config::group,
  $dhparams_file    = $::hitch::config::dhparams_file,
  $dhparams_content = undef,
  $dhparams_source  = undef,
  $key_content      = undef,
  $key_source       = undef,
)
{

  # Parameter validation

  validate_re($ensure, ['^present$', '^absent$'])

  # Exactly one of $key_source and $key_content
  if ($key_content and $key_source) or (! $key_content and ! $key_source) {
    fail("Hitch::Domain[${title}]: Please provide key_source or key_domain")
  }
  if $key_content {
    validate_re($key_content, 'PRIVATE KEY')
    $_key_content="${key_content}\n"
  }

  # Exactly one of $cert_content and $cert_source
  if ($cert_content and $cert_source) or (!$cert_content and !$cert_source) {
    fail("Hitch::Domain[${title}]: Please provide cert_source or cert_domain")
  }
  if $cert_content {
    validate_re($cert_content, 'CERTIFICATE')
    $_cert_content="${cert_content}\n"
  }

  # One or zero of $cacert_content or $cacert_source
  if ($cacert_content and $cacert_source) {
    fail("Hitch::Domain[${title}]: Please do not specify both cacert_source and cacert_domain")
  }
  if $cacert_content {
    validate_re($cacert_content, 'CERTIFICATE')
    $_cacert_content="${cacert_content}\n"
  }

  # One of $dhparams_content or $dhparams_source, with fallback to
  # $::hitch::dhparams_file
  if ($dhparams_content and $dhparams_source) {
    fail("Hitch::Domain[${title}]: Please do not specify both dhparams_source and dhparams_domain")
  }
  if $dhparams_content {
    validate_re($dhparams_content, 'DH PARAMETERS')
    $_dhparams_content="${dhparams_content}\n"
  }

  if ! defined(Class['hitch::config']) {
    fail('You must include the hitch::config class before using hitch::domain')
  }

  if defined(Class['hitch::service']) {
    $service_notify = [Class['hitch::service']]
  } else {
    $service_notify = []
  }

  validate_absolute_path($config_file)

  $pem_file="${config_root}/${title}.pem"
  validate_absolute_path($pem_file)


  # Add a line to the hitch config file
  concat::fragment { "hitch::domain ${title}":
    target  => $config_file,
    content => "pem-file = \"${pem_file}\"\n",
    notify  => $service_notify,
  }

  # Create the pem file, with (optional) ca certificate chain, a
  # certificate, a key, and finally the dh parameters
  concat { $pem_file:
    ensure => $ensure,
    mode   => '0640',
    owner  => $::hitch::file_owner,
    group  => $::hitch::group,
    notify => $service_notify,
  }

  concat::fragment {"${title} key":
    content => $_key_content,
    source  => $key_source,
    target  => $pem_file,
    order   => '01',
  }

  concat::fragment {"${title} cert":
    content => $_cert_content,
    source  => $cert_source,
    target  => $pem_file,
    order   => '02',
  }

  if ($cacert_content or $cacert_source) {
    concat::fragment {"${title} cacert":
      content => $_cacert_content,
      source  => $cacert_source,
      target  => $pem_file,
      order   => '03',
    }
  }

  if ! $dhparams_content {
    if $dhparams_source {
      $_dhparams_source = $dhparams_source
    }
    else {
      $_dhparams_source = $dhparams_file
      File[$dhparams_file] -> Concat::Fragment["${title} dhparams"]
    }
  }

  if ($dhparams_content or $_dhparams_source) {
    concat::fragment {"${title} dhparams":
      content => $_dhparams_content,
      source  => $_dhparams_source,
      target  => $pem_file,
      order   => '04',
    }
  }
}
