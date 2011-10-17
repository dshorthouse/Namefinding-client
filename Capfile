require 'bundler/capistrano'


load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

load 'config/deploy' # remove this line to skip loading any of the default tasks


after  'deploy:update_code', 'neti_config:symlink', 'taxon_config:symlink'

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

namespace :neti_config do
  desc "Make symlink to NetiNeti server config"
  task :symlink, :roles => :app do
    run "ln -nfs #{shared_path}/config/netineti_config.yml #{release_path}/config/netineti_config.yml"
  end
end

namespace :taxon_config do
  desc "Make symlink to NetiNeti server config"
  task :symlink, :roles => :app do
    run "ln -nfs #{shared_path}/config/taxon_config.yml #{release_path}/config/taxon_config.yml"
  end
end