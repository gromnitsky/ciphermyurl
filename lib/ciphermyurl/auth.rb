require 'pathname'
require 'digest/sha2'
require 'yaml'

module CipherMyUrl
  
  # How to add api keys:
  #
  # 1.1. Edit yaml file by hand
  # 1.2. Connect to a running sinatra instance with racksh
  # 1.3. Run 'apikeys_load'
  #
  # For Heroku:
  #
  # 2.1. Edit yaml on a dev machine.
  # 2.2. Push to heroku.
  # 2.3. See #1.2
  module Auth
    ROOT = Pathname.new(File.dirname(__FILE__)).parent.parent
    APIKEYS = ROOT + 'db/apikeys.yaml'

    def self.keyshash(kpubic, kprivate)
      Digest::SHA256.hexdigest(kpubic + kprivate)
    end

    def authenticated?(kpublic, kprivate)
      if @table[kpublic] && Auth.keyshash(kpublic, kprivate) == @table[kpublic][:keyshash]
        return @table[kpublic]
      end
      
      nil
    end

    def apikeys_load(file = nil)
      table_orig = nil
      Mutex.new.synchronize {
        table_orig = @table
        @table = YAML.load_file(file ? file : APIKEYS)
      }
    rescue
      @table = table_orig
      fail "cannot load apikeys db: #{$!}"
    end

    # Generate initial api keys db.
    #
    # [opt]     a result form Options.load
    # [output]  a file name
    def self.apikeys_add(opt, output)
      h = {
        opt[:webclient][:kpublic] => {
          email: opt[:webclient][:email],
          keyshash: Auth.keyshash(opt[:webclient][:kpublic], opt[:webclient][:kprivate]).encode('ascii'),
        }
      }.to_yaml

      File.readable?(output) && File.size(output) >= 4 && h = h[4..-1]
      File.open(output, 'a+') { |fp|
        fp.write "\n"
        fp.write h
      }
    end
    
    def kpublic_findBy(query)
      @table.each {|key, val|
        if query.index('@')
          # find by email
          return key if val[:email] == query
        else
          return key if val[:keyshash] == query
        end
      }
      nil
    end
    
  end
end
