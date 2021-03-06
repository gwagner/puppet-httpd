class httpd
{
    include httpd::config

    add_user {
        "apache":
            email => 'apache@neufocus-development.dev',
            uid => '20002';
    }

    package {
        ["httpd-tools", "httpd-devel"]:
            ensure => installed,
            provider => 'yum',
            require => Yumrepo['centos-base', 'centos-updates', 'centos-extras'];
        'httpd':
            name => "httpd",
            ensure => installed,
            provider => 'yum',
            alias => 'httpd',
            require => [
                Package["httpd-tools"],
                Package["httpd-devel"],
                Yumrepo['centos-base', 'centos-updates', 'centos-extras']
            ];
    }

    file {
        'httpd-vhosts':
            mode => 755,
            owner => 'root',
            group => 'root',
            path => '/etc/httpd/virtual_hosts/',
            ensure => directory,
            require => Package['httpd'];
        'httpd-vhosts-old':
            ensure => absent,
            path => "/etc/httpd/conf.d/*_vhost.conf",
            require => Package['httpd'];
        'httpd-cgi-bin-old':
            ensure => absent,
            path => "/var/www/cgi-bin",
            force => true,
            require => Package['httpd'];
        'httpd-error-old':
            ensure => absent,
            path => "/var/www/error",
            force => true,
            require => Package['httpd'];
        'httpd-icons-old':
            ensure => absent,
            path => "/var/www/icons",
            force => true,
            require => Package['httpd'];
        'httpd-readme':
            ensure => absent,
            path => "/etc/httpd/conf.d/README",
            require => Package['httpd'];
        'httpd-svn':
            ensure => absent,
            path => "/etc/httpd/conf.d/subversion.conf*",
            require => Package['httpd'];
        'httpd-welcome':
            ensure => absent,
            path => "/etc/httpd/conf.d/welcome.conf",
            require => Package['httpd'];
        'httpd-proxy_ajp-conf':
            mode => 644,
            owner => "root",
            group => "root",
            path => "/etc/httpd/conf.d/proxy_ajp.conf",
            content => template('httpd/conf.d/proxy_ajp.erb'),
            require => Package['httpd'];
        'httpd-conf':
            mode => 644,
            owner => "root",
            group => "root",
            path => "/etc/httpd/conf/httpd.conf",
            content => template('httpd/conf/httpd.erb'),
            require => Package['httpd'];
        'httpd-logs':
            ensure => "directory",
            owner => "apache",
            group => "apache",
            path  => "/var/log/httpd";
    }

    service {
        'httpd':
            ensure => true,
            enable => true,
            hasrestart => true,
            hasstatus => true,
            subscribe => [
                Package["httpd-tools"],
                Package["httpd-devel"],
                Package['httpd'],
                File['httpd-readme'],
                File['httpd-svn'],
                File['httpd-welcome'],
                File['httpd-proxy_ajp-conf'],
                File['httpd-conf'],
                File['httpd-logs']
            ];
    }
}

define httpd::vhost (
    $directory,
    $ensure = 'present',
    $compress_output = true,
    $other_directives = '',
    $server_alias = []
){
    file{
        "${name}_vhost":
            mode => 644,
            owner => "root",
            group => "root",
            path => "/etc/httpd/virtual_hosts/${name}_vhost.conf",
            content => template("httpd/conf.d/vhost.erb"),
            notify => Service['httpd'],
            ensure => $ensure,
            require => Package['httpd'];
    }

    host {
        $name:
            ip => '127.0.0.1',
            ensure => $ensure,
            host_aliases => $server_alias,
            target => '/etc/hosts',
            require => Package['httpd'];
    }
}