#
# Cookbook Name:: wp-jenkins
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

yum_package "java-1.8.0-openjdk-devel" do
  action :install
end

execute "install-jenkins-repo" do
  command <<-_EOH_
    wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
    rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key
  _EOH_
  action :run
  not_if { ::File.exists?("/etc/yum.repos.d/jenkins.repo") }
end
 	
package "jenkins" do
  action :install
end
 
service "jenkins" do
  action [:enable, :start]
end

group "wheel" do
  action [:modify]
  members ["jenkins"]
  append true
end


%w[ php-pear php-devel].each do |pkg|
  package "#{pkg}" do
    action :install
  end
end

%w{ pear.phpmd.org pear.pdepend.org pear.phing.info}.each do |channel|
  php_pear_channel channel do
    action :discover
  end
end

php_pear "PHP_PMD" do
  #version node['phpmd']['version']
  channel "phpmd"
  options "--alldeps"
  action :install
end

php_pear "phing" do
  channel "phing"
  options "-a --force"
  action :install
end

# execute "install-phpmd" do
#   user "root"
#   command %{composer global require 'phpmd/phpmd:*'}
# end

execute "install-jenkins-cli" do
  command <<-EOH
    wget http://#{node[:ipaddress]}:8080/jnlpJars/jenkins-cli.jar -P /home/vagrant
    alias jcli='java -jar /home/vagrant/jenkins-cli.jar -s http://#{node[:ipaddress]}:8080'
    jcli install-plugin php
    jcli install-plugin phing
    jcli install-plugin cloverphp
    jcli restart
  EOH
  action :run
  not_if { ::File.exists?("/home/vagrant/jenkins-cli.jar") }
end

template "/etc/sudoers.d/jenkins" do
  source "jenkins.erb"
  owner "root"
  group "root"
  mode "0440"
  action :create
end

