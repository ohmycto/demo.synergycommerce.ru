# require './config/boot'
require 'bundler/capistrano'

set :application, 'demo.synergycommerce'
set :scm, :git
set :repository, 'git@github.com:secoint/demo.synergycommerce.ru.git'
set :deploy_to, '/work/demo'
set :user, 'synergy'
set :use_sudo, false
set :unicorn_rails, 'bundle exec unicorn'
set :unicorn_conf, "#{shared_path}/config/unicorn.rb"
set :unicorn_pid, "#{shared_path}/pids/unicorn.pid"

role :web, 'vs01.secoint.ru'
role :app, 'vs01.secoint.ru'
role :db, 'vs01.secoint.ru', :primary => true

namespace(:customs) do
  task :config, :roles => :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end

  task :symlink, :roles => :app do
    run "ln -s #{shared_path}/assets #{release_path}/public/assets"
  end
end

namespace :deploy do
  desc 'Start application'
  task :start, :roles => :app do
    run "cd #{current_path} && MAGICK_THREAD_LIMIT=1 #{unicorn_rails} -Dc #{unicorn_conf} -E production"
  end

  desc 'Stop application'
  task :stop, :roles => :app do
    run "[ -f #{unicorn_pid} ] && kill -QUIT `cat #{unicorn_pid}`"
  end

  desc 'Restart Application'
  task :restart, :roles => :app do
    stop
    start
  end
end

after 'deploy:finalize_update', 'customs:config'
after 'deploy:create_symlink', 'customs:symlink'
after 'deploy', 'deploy:cleanup'
after 'deploy', 'deploy:migrate'

