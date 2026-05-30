# frozen_string_literal: true

Fixnum = Integer unless Object.const_defined?(:Fixnum)
Bignum = Integer unless Object.const_defined?(:Bignum)

require 'mina/rails'
require 'mina/git'
require 'mina/rvm'

set :ruby_version, 'ruby-3.4.1'

set :application_name, 'GSM - Sistema de Gerenciamento de Marmitarias'
set :domain, '108.181.224.196'
set :deploy_to, '/home/staging/sgm-api'
set :repository, 'git@github.com:Jemisson/SGM-Sistema-de-Gerenciamento-de-Marmitarias.git'
set :branch, 'staging'
set :user, 'staging'
set :port, '22'
set :forward_agent, true
set :rails_env, 'production'

task :bundle_install_fixed do
  queue! %(cd "#{release_path}" && bundle config set --local deployment true)
  queue! %(cd "#{release_path}" && bundle config set --local path "#{deploy_to}/shared/bundle")
  queue! %(cd "#{release_path}" && bundle config set --local without "development test")
  queue! %(cd "#{release_path}" && bundle install --jobs 4 --retry 3)
end

task :remote_environment do
  invoke :"rvm:use[#{fetch(:ruby_version)}]"
end

task setup: :remote_environment do
  queue! %(mkdir -p "#{deploy_to}/shared/log")
  queue! %(chmod g+rx,u+rwx "#{deploy_to}/shared/log")

  queue! %(mkdir -p "#{deploy_to}/shared/storage")
  queue! %(chmod g+rx,u+rwx "#{deploy_to}/shared/storage")
  queue! %(touch "#{deploy_to}/shared/storage/index.html")

  queue! %(mkdir -p "#{deploy_to}/shared/config")
  queue! %(chmod g+rx,u+rwx "#{deploy_to}/shared/config")

  queue! %(mkdir -p "#{deploy_to}/shared/pids")
  queue! %(chmod g+rx,u+rwx "#{deploy_to}/shared/pids")

  queue! %(mkdir -p "#{deploy_to}/shared/tmp/pids")
  queue! %(chmod g+rx,u+rwx "#{deploy_to}/shared/tmp/pids")

  queue! %(mkdir -p "#{deploy_to}/shared/tmp")
  queue! %(chmod g+rx,u+rwx "#{deploy_to}/shared/tmp")

  queue! %(touch "#{deploy_to}/shared/config/database.yml")
  queue  %(echo "-----> Be sure to edit 'shared/config/database.yml'.")

  queue! %(touch "#{deploy_to}/shared/config/master.key")
  queue! %(chmod 600 "#{deploy_to}/shared/config/master.key")
  queue  %(echo "-----> Be sure to edit 'shared/config/master.key'.")

  queue! %(touch "#{deploy_to}/shared/config/application.yml")
  queue  %(echo "-----> Be sure to edit 'shared/config/application.yml'.")

  queue! %(touch "#{deploy_to}/shared/config/secrets.yml")
  queue  %(echo "-----> Be sure to edit 'shared/config/secrets.yml'.")

  queue! %(touch "#{deploy_to}/shared/log/cable.log")
  queue! %(chmod g+rx,u+rw "#{deploy_to}/shared/log/cable.log")
end

desc 'Deploys the current version to the server.'
task deploy: :remote_environment do
  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :bundle_install_fixed
    invoke :'rails:db_migrate'
    invoke :'deploy:cleanup'

    to :launch do
      queue %(echo -n '-----> Creating new restart.txt: ')
      queue "touch #{deploy_to}/shared/tmp/restart.txt"
    end
  end
end

# Server Production
task :staging do
  set :rails_env, 'staging'
  set :user, ENV.fetch('STAGING_DEPLOY_USER', 'staging')
  set :domain, ENV.fetch('STAGING_DEPLOY_HOST', '108.181.224.196')
  set :port, ENV.fetch('STAGING_DEPLOY_PORT', '22')
  set :deploy_to, ENV.fetch('STAGING_DEPLOY_TO', '/home/staging/sgm-api')
  set :branch, ENV.fetch('STAGING_DEPLOY_BRANCH', 'staging')
end

# Fix
set :term_mode, nil

set :shared_paths, [
  'public/uploads',
  'config/master.key',
  'config/database.yml',
  'log',
  'tmp',
  'storage',
  'config/application.yml',
  'config/secrets.yml'
]

desc 'Show logs rails.'
task 'logs:rails': :remote_environment do
  queue 'echo "Contents of the log file are as follows:"'
  queue "tail -f #{deploy_to}/shared/log/#{fetch(:rails_env)}.log"
end

desc 'Show logs Nginx.'
task 'logs:nginx': :remote_environment do
  queue 'echo "Contents of the log file are as follows:"'
  queue 'tail -f /opt/nginx/logs/error.log'
end
