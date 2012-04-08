# -*-ruby-*-

require 'rake'
require 'rake/clean'
require 'rake/testtask'
gem 'rdoc'
require 'rdoc/task'
require 'securerandom'
require 'yaml'

require_relative 'doc/rakefile'
require_relative 'lib/ciphermyurl/db'

DB_APIKEYS = 'db/apikeys.yaml'
DB_PSTORE = 'db/data.marshall'
DB_WELCOME_MSG = File.read 'db/welcome.txt'
CSS = 'public/style.css'

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


namespace 'db' do
  task :clean_fixtures do
    rm_rf DB_PSTORE
  end

  desc 'Clean & fill the DB with minimum requred data'
  task fixtures: :clean_fixtures do
    CipherMyUrl::MyDB.setAdapter :pstore, file: DB_PSTORE
    CipherMyUrl::MyDB.pack DB_WELCOME_MSG, 'john.doe@example.com', '12345678'
#  pp CipherMyUrl::MyDB['1']
  end
end


task :clean_config_sinatra do
  rm_rf 'config/sinatra.rb'
end

desc 'Generate production/development env (BE CAREFUL)'
file 'config/sinatra.rb' => 'config/sinatra.rb.example' do |t|
  cp(t.prerequisites.first.to_s, t.name)
end

desc 'Generate application crypto hashes (BE CAREFUL)'
file 'config/crypto.rb' => 'config/crypto.rb.example' do |t|
  s = File.read t.prerequisites.first
  s.gsub! /(BROWSER_USER_PUBLIC) = 'SET THIS'/, "\\1 = '#{SecureRandom.uuid}'"
  s.gsub! /(BROWSER_USER_PRIVATE) = 'SET THIS'/, "\\1 = '#{SecureRandom.hex(64)}'"
  puts 'Writing ' + t.name
  File.open(t.name, 'w+') { |fp| fp.write s }
end

desc 'Generate api keys db (BE CAREFULL)'
file DB_APIKEYS => ['config/crypto.rb'] do |t|
  require_relative 'lib/ciphermyurl/auth'

  h = {
    CipherMyUrl::Auth::BROWSER_USER_KEYSHASH.encode('ascii') => {
      email: 'john.doe@example.com',
      kpublic: CipherMyUrl::Auth::BROWSER_USER_PUBLIC,
      kprivate: CipherMyUrl::Auth::BROWSER_USER_PRIVATE,
    }
  }.to_yaml
  puts 'Writing ' + t.name
  File.open(t.name, 'w+') { |fp| fp.write h }
end

task :clean_crypto do
  rm_rf 'config/crypto.rb'
end

task default: ['public/style.css', 'doc:all']
task clean: [:clean_css, 'doc:clean']
task clobber: [:clean_crypto, :clean_config_sinatra]

desc "Some initial configuration"
task init: [DB_APIKEYS, 'config/sinatra.rb', 'db:fixtures', 'public/style.css']
