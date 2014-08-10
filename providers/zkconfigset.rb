#
# Cookbook Name:: solrcloud
# Provider:: solrcloud_zkconfigset
#
# Copyright 2014, Virender Khatri
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

def whyrun_supported?
  true
end

action :delete do

  if node.solrcloud.manage_zkconfigsets
    execute "zk_config_set_rmr_#{new_resource.name}" do
      # TODO: Use Zookeeper gem to get the status instead using zkCli.sh
      command   "echo 'rmr /configs/#{new_resource.name}' | #{new_resource.zkcli} -server #{new_resource.zkhost} 2>&1"
      only_if   "echo 'ls /configs/#{new_resource.name}' | #{new_resource.zkcli} -server #{new_resource.zkhost} 2>&1 | egrep -o 'solrconfig.xml|schema.xml' > /dev/null"
    end
  end

  directory ::File.join(new_resource.zkconfigsets_home, new_resource.name) do
    recursive   true
    action      :delete
    only_if     { node.solrcloud.manage_zkconfigsets_source }
  end

end

action :create do

  remote_directory ::File.join(new_resource.zkconfigsets_home, new_resource.name) do
    cookbook    new_resource.zkconfigsets_cookbook
    source      new_resource.name
    owner       new_resource.user
    group       new_resource.group
    mode        0644
    files_mode  0644
    files_owner new_resource.user
    files_group new_resource.group
    notifies    :run, "execute[zk_config_set_upconfig_#{new_resource.name}]", :immediately
    only_if     { node.solrcloud.manage_zkconfigsets_source }
  end

  execute "zk_config_set_upconfig_#{new_resource.name}" do
    command     "#{new_resource.solr_zkcli} -zkhost #{new_resource.zkhost} -cmd upconfig -confdir #{::File.join(new_resource.zkconfigsets_home, new_resource.name, 'conf')} -confname #{new_resource.name} 2>&1"
    action      :nothing
    only_if     { node.solrcloud.manage_zkconfigsets }
    #only_if  "echo 'ls /configs/#{new_resource.name}' | #{new_resource.zkcli} -server #{new_resource.zkhost} 2>&1 | egrep -o 'Node does not exist: /configs/#{new_resource.name}' > /dev/null"
  end

end

