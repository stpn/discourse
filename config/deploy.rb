# set :application, "discourse"
# set :rvm_type, :user

# # RVM integration
# # http://beginrescueend.com/integration/capistrano/
# # $:.unshift(File.expand_path('./lib', ENV['rvm_path']))
# require 'capistrano/rvm'
# set :rvm_type, :system                     # Defaults to: :auto
# set :rvm_ruby_version, '2.0.0-p195'      # Defaults to: 'default'
# set :rvm_custom_path, '/usr/local/rvm/bin'  # only needed if not detected

# # Bundler integration (bundle install)
# # http://gembundler.com/deploying.html
# require "capistrano/bundler"

# set :bundle_without,  [:development, :test]
# set :user, "admin"
# set :deploy_to, "/home/admin/discourse"
# set :use_sudo, true

set :rvm1_ruby_version, "2.0.0-p195"

set :application, "discourse"
set :scm, :git
set :repo_url, "git@github.com:stpn/discourse.git"
set :deploy_to, "/home/admin/discourse"
set :ssh_options, {:keys => ["/Users/stpn/.ssh/notchServer.pem"] }


set :log_level, :info
set :rvm_ruby_string, '2.0.0'
set :rvm_type, :user

set :branch, 'master'
set :user, "admin"
set :use_sudo, false
set :keep_releases, 2
set :git_shallow_clone, 1
set :deploy_via, :copy

before 'deploy', 'rvm1:install:rvm' 

# files we want symlinking to specific entries in shared.
# set :linked_files, %w{config/database.yml config/application.yml}

# which config files should be copied by deploy:setup_config
# see documentation in lib/capistrano/tasks/setup_config.cap
# for details of operations
# set(:config_files, %w(
#   nginx.conf
#   application.yml
#   database.yml
# ))

# set(:symlinks, [
#   {
#     source: "nginx.conf",
#     link: "/etc/nginx/sites-enabled/#{fetch(:full_app_name)}"
#   }
# ])



#set :whenever_command, "bundle exec whenever"
#require 'sidekiq/capistrano'



namespace :deploy do



  task :start  do
    run "cd #{current_path} && RUBY_GC_MALLOC_LIMIT=90000000 bundle exec thin -C config/thin.yml start", :pty => false
  end

  desc 'Stop thin servers'
  task :stop  do
    run "cd #{current_path} && bundle exec thin -C config/thin.yml stop"
  end

  desc 'Restart thin servers'
  task :restart do
    run "cd #{current_path} && RUBY_GC_MALLOC_LIMIT=90000000 bundle exec thin -C config/thin.yml restart"
  end

  # Sets up several shared directories for configuration and thin's sockets,
  # as well as uploading your sensitive configuration files to the serer.
  # The uploaded files are ones I've removed from version control since my
  # project is public. This task also symlinks the nginx configuration so, if
  # you change that, re-run this task.
  task :setup_config  do
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
  task :symlink_config do
    run  "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run  "ln -nfs #{shared_path}/config/newrelic.yml #{release_path}/config/newrelic.yml"
    run  "ln -nfs #{shared_path}/config/redis.yml #{release_path}/config/redis.yml"
    run  "ln -nfs #{shared_path}/config/environments/production.rb #{release_path}/config/environments/production.rb"
    run  "ln -nfs #{shared_path}/config/initializers/secret_token.rb #{release_path}/config/initializers/secret_token.rb"
  end

end


namespace :db do
  desc 'Seed your database for the first time'
  task :seed do
    run "cd #{current_path} && psql -d discourse_production < pg_dumps/production-image.sql"
  end
end

#after  'deploy:update_code', 'deploy:migrate'