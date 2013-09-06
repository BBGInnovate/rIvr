require 'bundler/capistrano'
set :user, 'ubuntu'
set :domain, 'ivr.bbg.gov'
set :applicationdir, "/data/ivr"

set :application, "ivr"


# set :scm, :git # You can set :scm explicitly or Capistrano will make an intelligent guess based on known version control directory names
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

set :scm, 'git'
set :repository,  "git@ivr_git:/home/git/dashboard.git"
# git ls-remote git@ivr_git:/home/git/dashboard.git
set :git_enable_submodules, 1 # if you have vendored rails
set :branch, 'master'
set :git_shallow_clone, 1
set :scm_verbose, true
set :rails_env, "staging"
ssh_options[:keys] = %w(/Users/lliu/.ssh/id_rsa)
ssh_options[:forward_agent] = true
  
role :web, domain
role :app, domain
role :db,  domain, :primary => true
 
# deploy config
set :deploy_to, '/data/ivr'
set :deploy_via, :export

# cap deploy:setup
#This should setup the following directories
#/data/ivr/current
#/data/ivr/shared
#/data/ivr/releases
# cap deploy:check


# Passenger
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end



# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end