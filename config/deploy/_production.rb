# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary
# server in each group is considered to be the first
# unless any hosts have the primary property set.
# Don't declare `role :all`, it's a meta role

# setup some Capistrano roles
# role :app, %w{admin@ec2-20-21-42-51.compute-1.amazonaws.com}
# role :web, %w{admin@ec2-20-21-42-51.compute-1.amazonaws.com}
# role :db,  %w{admin@ec2-20-21-42-51.compute-1.amazonaws.com} , :primary => true

# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server
# definition into the server list. The second argument
# something that quacks like a hash can be used to set
# extended properties on the server.
# server 'ec2-20-21-42-51.compute-1.amazonaws.com', user: 'admin', roles: [:app, :web]

# you can set custom ssh options
# it's possible to pass any option but you need to keep in mind that net/ssh understand limited list of options
# you can see them in [net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start)
# set it globally
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }

set :stage, :production

server  "ec2-54-204-10-20.compute-1.amazonaws.com", user: 'admin', roles: %w{web app db}, primary: true
set :rails_env, :production

 set :ssh_options, {
   user: "admin",
   keys: %w(/Users/stpn/.ssh/notchServer.pem),
   forward_agent: false,
   auth_methods: %w(publickey)
 }

set :deploy_to, '/home/admin/discourse'

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


# and/or per server
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
# setting per server overrides global ssh_options
