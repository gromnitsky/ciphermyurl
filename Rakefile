# -*-ruby-*-

require 'rake'
require 'rake/clean'
require 'rake/testtask'
gem 'rdoc'
require 'rdoc/task'

require_relative 'doc/rakefile'
require_relative 'lib/ciphermyurl/db'

DB_PSTORE = 'db/data.marshall'
DB_WELCOME_MSG = File.read 'db/welcome.txt'
CSS = 'public/style.css'

Rake::TestTask.new do |i|
  i.test_files = FileList['test/test_*.rb']
end

class RDoc::Options
  def template_dir_for template
    '/home/alex/Desktop/' + template
  end
end

RDoc::Task.new('html') do |i|
  i.template = 'lightfish'
  i.main = 'doc/README.rdoc'
  i.rdoc_files = FileList['doc/*', 'lib/**/*.rb', '*.rb']
#  i.rdoc_files.exclude("lib/**/some-nasty-staff")
end


task :clean_css do
  rm_rf CSS
end

desc "Our CSS"
file CSS => 'public/bootstrap' do |t|
  sh "lessc #{t.prerequisites.first}/main.less -o #{t.name}"
end


task :clean_fixtures do
  rm_rf DB_PSTORE
end

desc 'Fill the DB with minimum requred data'
task fixtures: :clean_fixtures do
  CipherMyUrl::MyDB.setAdapter :pstore, file: DB_PSTORE
  CipherMyUrl::MyDB.pack DB_WELCOME_MSG, 'john.doe@example.com', '12345678'
#  pp CipherMyUrl::MyDB['1']
end

task default: ['public/style.css', :fixtures, 'doc:all']
task clean: [:clean_css, :clean_fixtures, 'doc:clean']
