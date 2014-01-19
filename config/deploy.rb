# This is a set of sample deployment recipes for deploying via Capistrano.
# One of the recipes (deploy:symlink_nginx) assumes you have an nginx configuration
# file at config/nginx.conf. You can make this easily from the provided sample
# nginx configuration file.
#
# For help deploying via Capistrano, see this thread:
# http://meta.discourse.org/t/deploy-discourse-to-an-ubuntu-vps-using-capistrano/6353



require 'rvm/capistrano'
#set :rvm_ruby_string, ENV['GEM_HOME'].gsub(/.*\//,"") 
set :rvm_type, :user
set :rvm_ruby_string, '2.0.0-p195'

require 'bundler/capistrano'
require 'sidekiq/capistrano'
# Repo Settings
# You should change this to your fork of discourse
set :repository, 'git@github.com:stpn/discourse.git'
set :deploy_via, :remote_cache
set :branch, fetch(:branch, 'master')
set :scm, :git
ssh_options[:forward_agent] = true

# General Settings
set :deploy_type, :deploy
default_run_options[:pty] = true

# Server Settings
set :user, 'admin'
set :use_sudo, false
set :rails_env, :production

role :app, 'ec2-54-204-10-20.compute-1.amazonaws.com', primary: true
role :db,  'ec2-54-204-10-20.compute-1.amazonaws.com', primary: true
role :web, 'ec2-54-204-10-20.compute-1.amazonaws.com', primary: true

# Application Settings
set :application, 'discourse'
set :deploy_to, "/home/admin/#{application}"
ssh_options[:keys] = ["#{ENV['HOME']}/.ssh/notchServer.pem"]


# # Perform an initial bundle
# after "deploy:setup" do
#   run "cd #{current_path} && bundle install"
# end

# Tasks to start/stop/restart thin
namespace :deploy do
  desc 'Start thin servers'
  task :start, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && RUBY_GC_MALLOC_LIMIT=90000000 bundle exec thin -C config/thin.yml start", :pty => false
  end

  desc 'Stop thin servers'
  task :stop, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && bundle exec thin -C config/thin.yml stop"
  end

  desc 'Restart thin servers'
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && RUBY_GC_MALLOC_LIMIT=90000000 bundle exec thin -C config/thin.yml restart"
  end


 # Sets up several shared directories for configuration and thin's sockets,
  # as well as uploading your sensitive configuration files to the serer.
  # The uploaded files are ones I've removed from version control since my
  # project is public. This task also symlinks the nginx configuration so, if
  # you change that, re-run this task.
  task :setup_config, roles: :app do
    run  "mkdir -p #{shared_path}/config/initializers"
    run  "mkdir -p #{shared_path}/config/environments"
    run  "mkdir -p #{shared_path}/sockets"
    put  File.read("config/database.yml"), "#{shared_path}/config/database.yml"
    put  File.read("config/redis.yml"), "#{shared_path}/config/redis.yml"
    put  File.read("config/environments/production.rb"), "#{shared_path}/config/environments/production.rb"
    put  File.read("config/initializers/secret_token.rb"), "#{shared_path}/config/initializers/secret_token.rb"
    sudo "ln -nfs #{release_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
    puts "Now edit the config files in #{shared_path}."
  end

  # Symlinks all of your uploaded configuration files to where they should be.
  task :symlink_config, roles: :app do
    run  "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run  "ln -nfs #{shared_path}/config/newrelic.yml #{release_path}/config/newrelic.yml"
    run  "ln -nfs #{shared_path}/config/redis.yml #{release_path}/config/redis.yml"
    run  "ln -nfs #{shared_path}/config/environments/production.rb #{release_path}/config/environments/production.rb"
    run  "ln -nfs #{shared_path}/config/initializers/secret_token.rb #{release_path}/config/initializers/secret_token.rb"
  end
  
end

# Symlink config/nginx.conf to /etc/nginx/sites-enabled. Make sure to restart
# nginx so that it picks up the configuration file.
namespace :config do
  task :nginx, roles: :app do
    puts "Symlinking your nginx configuration..."
    sudo "ln -nfs #{release_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
  end
end

after "deploy:setup", "config:nginx"

# Seed your database with the initial production image. Note that the production
# image assumes an empty, unmigrated database.
namespace :db do
  desc 'Seed your database for the first time'
  task :seed do
    run "cd #{current_path} && psql -d discourse_production < pg_dumps/production-image.sql"
  end
end

# Migrate the database with each deployment
after  'deploy:update_code', 'deploy:migrate'
