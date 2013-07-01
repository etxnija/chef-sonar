#
# Cookbook Name:: sonar
# Recipe:: default
#
# Copyright 2011, Christian Trabold
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "java"

package "unzip"
sonar_distribution = "sonar-#{node['sonar']['version']}"

local_sonar_dir = "/opt/#{sonar_distribution}"

sonar_file = "#{sonar_distribution}.zip"

dist_file_location = "#{node['sonar']['mirror']}/#{sonar_file}"

# Get the zip file
remote_file "/opt/#{sonar_file}" do
  source "#{dist_file_location}"
  mode "0644"
  not_if { ::File.exists?("#{local_sonar_dir}/#{sonar_file}")}
end

# Expand the zip
execute "unzip /opt/#{sonar_file} -d /opt/" do
  not_if { ::File.directory? ("/opt/#{sonar_distribution}")}  
end

node['sonar'['plugins']].each_pair do |plugin , source|
#Get the plugins for .Net
#http://search.maven.org/remotecontent?filepath=org/codehaus/sonar-plugins/dotnet/distribution/2.1/distribution-2.1.zip
  remote_file "/opt/#{sonar_distribution}/extensions/plugins/#{plugin}.zip" do
    source "#{source}"
    mode "0644"
    not_if { ::File.exists?("/opt/#{sonar_distribution}/extensions/plugins/#{plugin}.zip")}
  end
  # Expand the zip
  execute "unzip -j /opt/#{sonar_distribution}/extensions/plugins/dotnet.zip -d /opt/#{sonar_distribution}/extensions/plugins/" do
    not_if { ::File.exists?("/opt/#{sonar_distribution}/extensions/plugins/dotnet.zip")}
  end
end

link "/opt/sonar" do
  to "/opt/sonar-#{node['sonar']['version']}"
end

service "sonar" do
  stop_command "sh /opt/sonar/bin/#{node['sonar']['os_kernel']}/sonar.sh stop"
  start_command "sh /opt/sonar/bin/#{node['sonar']['os_kernel']}/sonar.sh start"
  status_command "sh /opt/sonar/bin/#{node['sonar']['os_kernel']}/sonar.sh status"
  restart_command "sh /opt/sonar/bin/#{node['sonar']['os_kernel']}/sonar.sh restart"
  action :start
end

template "sonar.properties" do
  path "/opt/sonar/conf/sonar.properties"
  source "sonar.properties.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    :options => node['sonar']['options']
  )
  notifies :restart, resources(:service => "sonar")
end
