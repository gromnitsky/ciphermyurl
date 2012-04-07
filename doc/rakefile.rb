# -*-ruby-*-

require 'pathname'
require 'pp'

module Doc
  ROOT = Pathname.new File.dirname(__FILE__)
  VARS = ROOT + 'api.vars.rest'
  META2RST =  ROOT + 'meta2rst'
  
  RST = FileList["#{ROOT}/*.rst"]
  XHTML = RST.map {|i| i.ext('xhtml') }
end

file Doc::VARS => ["#{Doc::ROOT.parent}/lib/ciphermyurl/meta.rb",
                   "#{Doc::ROOT.parent}/lib/ciphermyurl/api.rb"] do |t|
  sh "#{Doc::META2RST} > #{t.name}"
end

rule '.xhtml' => ['.rst'] do |t|
  sh "rst2html #{t.source} #{t.name}"
end

namespace 'doc' do
  task :clean do
    rm_rf Doc::VARS
    rm_rf Doc::XHTML
  end

  desc 'Make all docs'
  task :all => Doc::VARS
  task :all => Doc::XHTML
end
