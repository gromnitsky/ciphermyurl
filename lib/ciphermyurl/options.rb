require 'yaml'
require 'pathname'

module CipherMyUrl
  
  module Options
    extend self
    
    ROOT = Pathname.new(File.dirname(__FILE__)).parent.parent
    FILE = ROOT + 'config/options.yaml'
    
    def load(file = nil)
      YAML.load_file(file ? file : FILE)
    rescue
      fail "cannot read options file: #{$!}"
    end

    
  end
end
    
