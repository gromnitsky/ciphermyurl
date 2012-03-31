# -*-ruby-*-

require 'rake'
require 'rake/clean'
require 'rake/testtask'

gem 'rdoc'
require 'rdoc/task'

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
