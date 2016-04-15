#
# Cookbook Name:: fb_logrotate
# Recipe:: default
#
# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2
#
# Copyright 2012-present, Facebook
#

if node.macosx?
  template '/etc/newsyslog.d/fb_bsd_newsyslog.conf' do
    source 'fb_bsd_newsyslog.conf.erb'
    mode '0644'
    owner 'root'
    group 'root'
  end
  return
end

# assume linux
package %w{logrotate pigz} do
  not_if { node.yocto? }
  action :upgrade
end

whyrun_safe_ruby_block 'munge logrotate configs' do
  block do
    node['fb_logrotate']['configs'].to_hash.each do |name, block|
      if block['overrides']
        if block['overrides']['rotation'] == 'weekly' &&
           !block['overrides']['rotate']
          node.default['fb_logrotate']['configs'][name][
            'overrides']['rotate'] = '4'
        end
        if block['overrides']['size']
          time = "size #{block['overrides']['size']}"
        elsif ['weekly', 'monthly', 'yearly'].include?(
          block['overrides']['rotation'])
          time = block['overrides']['rotation']
        end
      end
      if time
        node.default['fb_logrotate']['configs'][name]['time'] = time
      end
    end
  end
end

template '/etc/logrotate.d/fb_logrotate.conf' do
  source 'fb_logrotate.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

cookbook_file '/etc/cron.daily/logrotate' do
  only_if { node['fb_logrotate']['add_locking_to_logrotate'] }
  source 'logrotate_rpm_cron_override'
  mode '0755'
  owner 'root'
  group 'root'
end