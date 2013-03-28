class foreman::config::passenger(

  # specifiy which interface to bind passenger to eth0, eth1, ...
  $listen_on_interface = ''


) {
  include apache
  include apache::mod::passenger

  # Check the value in case the interface doesn't exist, otherwise listen on all interfaces
  if inline_template("<%= interfaces.split(',').include?(listen_on_interface) %>") == "true" {
    $listen_interface = inline_template("<%= ipaddress_${listen_on_interface} %>")
  }
  else{
    $listen_interface = '*'
  }

  # define Virtual Host
  if $foreman::use_vhost {

    apache::vhost{ "foreman.${fqdn}" :
      # Template need to be splitted for SSL/non-SSL - (also consider using a simpler
      # one for HTTPS redirection: puppetlabs/puppetlabs-apache templates/vhost-redirect.conf.erb)
      template     => 'foreman/foreman-vhost.conf.erb',
      # Port will be ignored by the template, but not by the firewall
      port         => 80,
      # just ensure that mod_rewrite is loaded
      redirect_ssl => $foreman::ssl,
      docroot      => $foreman::app_root,
    }

    if $foreman::ssl {
      apache::vhost{ "foreman_ssl.${fqdn}" :
        # Template need to be splitted for SSL/non-SSL
        template => 'foreman/foreman-vhost.conf.erb',
        # Port will be ignored by the template, but not by the firewall
        port     => 443,
        # apache::mod:ssl will be included, if ssl = true
        ssl      => $foreman::ssl,
        docroot  => $foreman::app_root,
      }
    }

  } else {
    fail "foreman::use_vhost = false is not supported by puppetlabs/apache Module!"
  }

  exec {'restart_foreman':
    command     => "/bin/touch ${foreman::app_root}/tmp/restart.txt",
    refreshonly => true,
    cwd         => $foreman::app_root,
    path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  }

  file { ["${foreman::app_root}/config.ru", "${foreman::app_root}/config/environment.rb"]:
    owner   => $foreman::user,
    require => Class['foreman::install'],
  }
}
