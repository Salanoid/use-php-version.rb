#!/usr/bin/env ruby

unless [1].include?(ARGV.size)
  puts "You need to specify version!"
  exit -1
end

version = ARGV[0]

begin
  get_current_version = `php -v`
  current_version = get_current_version.match(/[PHP]?\s*\K[\d\.]+/)[0]
rescue Errno::ENOENT
  current_version = nil
end

puts "#{current_version} is already in use" if current_version == version
return if current_version == version

`systemctl restart apache2`

if `apt list --installed | grep php`.include?(version)
  puts "Version already installed."
  `a2dismod php#{current_version}`
  `a2enmod php#{version}`
  `service apache2 restart`
  `update-alternatives --set php /usr/bin/php#{version}`
  `update-alternatives --set phar /usr/bin/phar#{version}`
  `systemctl restart apache2`
  `update-alternatives --config php`
  `systemctl restart apache2`
  puts "Swiched from #{current_version} to #{version}."
else
  `apt install php#{version}`
  `apt install php#{version}-common php#{version}-mysql php#{version}-xml php#{version}-xmlrpc php#{version}-curl php#{version}-gd php#{version}-imagick php#{version}-cli php#{version}-dev php#{version}-imap php#{version}-mbstring php#{version}-opcache php#{version}-soap php#{version}-zip php#{version}-intl -y`
  `a2dismod php#{current_version}`
  `a2enmod php#{version}`
  `service apache2 restart`
  `update-alternatives --set php /usr/bin/php#{version}`
  `update-alternatives --set phar /usr/bin/phar#{version}`
  `systemctl restart apache2`
  `update-alternatives --config php`
  `systemctl restart apache2`
  puts "Swiched from #{current_version} to #{version}."
end
sleep 0.1
`sudo a2dismod php#{current_version}`

if current_version&.present?
  if current_version.split('.').first == '5'
    `sudo a2dismod php5.0`
  elsif current_version.split('.').first == '7'
    `sudo a2dismod php7.0`
  elsif current_version.split('.').first == '8'
    `sudo a2dismod php8.0`
  end
end
`sudo a2enmod php#{version}`
`sudo systemctl restart apache2` # if this returns error try sudo apt-get purge 'php*' and run this again
