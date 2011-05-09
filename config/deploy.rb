#require "bundler/capistrano"

repository = "git@github.com:secoint/demo.synergycommerce.ru.git"
application_name = "synergy-app"
user_login = "secoint"
server_name = "lithium"

dpath = "/home/hosting_#{user_login}/projects/#{application_name}"

set :application, application_name
set :scm, :git
set :repository, repository

set :user, "hosting_#{user_login}"
set :use_sudo, false
set :deploy_to, dpath

role :web, "#{server_name}.locum.ru"                          # Your HTTP server, Apache/etc
role :app, "#{server_name}.locum.ru"                          # This may be the same as your `Web` server

after "deploy:update_code", :copy_shared_files

task :copy_shared_files, roles => :app do
  db_config = "#{shared_path}/database.yml"
  run "cp #{db_config} #{release_path}/config/database.yml -f"
  #run "cp #{shared_path}/Gemfile #{release_path}/Gemfile -f"
  #run "cp #{shared_path}/Gemfile.lock #{release_path}/Gemfile.lock -f"
  #run "cp #{shared_path}/production.rb #{release_path}/config/production.rb -f"
  run "ln -s #{shared_path}/assets #{release_path}/public/assets"
  run "ln -s #{shared_path}/api #{release_path}/app/controllers/api"
end

set :unicorn_rails, "/var/lib/gems/1.8/bin/unicorn_rails"
set :bundler, "/var/lib/gems/1.8/bin/bundle"
set :rails, "/var/lib/gems/1.8/bin/rails"
set :rake, "/var/lib/gems/1.8/bin/rake"
set :unicorn_conf, "/etc/unicorn/#{application_name}.#{user_login}.rb"
set :unicorn_pid, "/var/run/unicorn/#{application_name}.#{user_login}.pid"

before "deploy:update", "deploy:setup"
after "deploy:symlink", :synergy_setup

task :synergy_setup, roles => :app do
  run ["cd #{dpath}/current",
      "#{bundler} install --path=~/.gem",
#      "#{rake} spree_compare_products:install",
#      "#{rake} spree_reviews:install",
#      "#{rake} synergy:install",
      "#{rake} synergy_default_theme:install",
      "#{rake} db:migrate RAILS_ENV=production"].join(" && ")
end

desc "Load seed & sample data"
task :synergy_seed, :roles => :app do
  run ["cd #{dpath}/current",
      "#{rake} db:seed RAILS_ENV=production AUTO_ACCEPT=1",
      "#{rake} db:sample RAILS_ENV=production AUTO_ACCEPT=1"].join(" && ")  
end

# - for unicorn - #
namespace :deploy do
  desc "Start application"
  task :start, :roles => :app do
    run "#{unicorn_rails} -Dc #{unicorn_conf}"
  end

  desc "Stop application"
  task :stop, :roles => :app do
    run "[ -f #{unicorn_pid} ] && kill -QUIT `cat #{unicorn_pid}`"
  end

  desc "Update application"
  task :update_gems, :roles => :app do
    run ["cd #{dpath}/current",
        "#{bundler} update",
        "#{rake} synergy_default_theme:install"].join(" && ")    
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "[ -f #{unicorn_pid} ] && kill -QUIT `cat #{unicorn_pid}` && #{unicorn_rails} -Dc #{unicorn_conf}"
  end
end
