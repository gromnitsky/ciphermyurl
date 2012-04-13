require 'pp'
require 'fileutils'
include FileUtils

require_relative '../lib/ciphermyurl/meta'
require 'minitest/autorun'

def cd_to_tests
  case File.basename(Dir.pwd)
  when CipherMyUrl::Meta::NAME.downcase
    # test probably is executed from the Rakefile
    Dir.chdir('test')
    $stderr.puts('*** chdir to ' + Dir.pwd)
  when 'test'
    # we are in the test directory, there is nothing special to do
  else
    fail "running tests from '#{Dir.pwd}' isn't supported: #{$!}"
  end
end
