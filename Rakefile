# -*-ruby-*-

require 'rake'
require 'rake/clean'
require 'rake/testtask'
gem 'rdoc'
require 'rdoc/task'
require 'securerandom'
require 'yaml'

require_relative 'doc/rakefile'
require_relative 'lib/ciphermyurl/options'
require_relative 'lib/ciphermyurl/db'

DB_APIKEYS = 'db/apikeys.yaml'
DB_PSTORE = 'db/data.marshall'
DB_WELCOME_MSG = File.read 'db/welcome.txt'
CSS = 'public/style.css'
OPTIONS = 'config/options.yaml'

opt = CipherMyUrl::Options.load

Rake::TestTask.new do |i|
  i.test_files = FileList['test/test_*.rb']
end

RDoc::Task.new('html') do |i|
  i.main = 'doc/README.rdoc'
  i.rdoc_files = FileList['*.rb', 'config/*.rb', 'doc/*',
                          'lib/**/*.rb', 'vendor/*rb']
  i.rdoc_files.exclude('doc/rakefile.rb')
end


task :clean_css do
  rm_rf CSS
end

desc "Our CSS"
file CSS => 'public/bootstrap' do |t|
  sh "lessc #{t.prerequisites.first}/main.less -o #{t.name}"
end


task :clean_config_sinatra do
  rm_rf 'config/sinatra.rb'
end

desc 'Generate production/development env (BE CAREFUL)'
file 'config/sinatra.rb' => 'config/sinatra.rb.example' do |t|
  cp(t.prerequisites.first.to_s, t.name)
end

task :clean_options do
  rm_rf OPTIONS
end

desc 'Generate options (BE CAREFUL)'
file OPTIONS => "#{OPTIONS}.example" do |t|
  cp(t.prerequisites.first.to_s, t.name)
end

desc 'Add api keys to db'
file DB_APIKEYS => OPTIONS do |t|
  puts 'Writing ' + t.name
  
  require_relative 'lib/ciphermyurl/auth'
  CipherMyUrl::Auth.apikeys_add opt, t.name
end


namespace 'db' do
  task :clean_fixtures do
    rm_rf DB_PSTORE if opt[:db][:adapter] == :pstore
    # FIXME: delete couchdb db
  end

  desc 'Clean & fill the DB with minimum requred data'
  task fixtures: [OPTIONS, :clean_fixtures] do
    if opt[:db][:adapter] == :pstore
      CipherMyUrl::MyDB.setAdapter :pstore, file: DB_PSTORE
    else
      # FIXME: couchdb
      CipherMyUrl::MyDB.setAdapter(opt[:db][:adapter],
                                   login: opt[:db][:login],
                                   pw: opt[:db][:pw])
    end
    
    CipherMyUrl::MyDB.pack DB_WELCOME_MSG, 'john.doe@example.com', '12345678'
#    pp CipherMyUrl::MyDB['1']
  end
end


task default: [CSS, 'doc:all']
task clean: [:clean_css, 'doc:clean']
task clobber: [:clean_options, :clean_config_sinatra]

desc "Some initial configuration"
task init: [DB_APIKEYS, 'config/sinatra.rb', 'db:fixtures', CSS]
