require 'pathname'
require 'digest/sha2'
require 'yaml'

module CipherMyUrl
  
  # How to add api keys:
  #
  # 1. Edit yaml file by hand
  # 2. Connect to a running sinatra instance with racksh
  # 3. Run 'apikeys_load'
  module Auth
    ROOT = Pathname.new(File.dirname(__FILE__)).parent.parent
    APIKEYS = ROOT + 'db/apikeys.yaml'
    
    require ROOT + 'config/crypto'
    include Crypto

    def self.keys_hash(kpubic, kprivate)
      Digest::SHA256.hexdigest(kpubic + kprivate)
    end
    
    BROWSER_USER_KEYSHASH = Auth.keys_hash BROWSER_USER_PUBLIC, BROWSER_USER_PRIVATE

    def authenticated?(keys_hash)
      @table[keys_hash]
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

    def getBrowserUser
      authenticated? BROWSER_USER_KEYSHASH
    end

    def keyshash_findBy(query)
      @table.each {|key, val|
        if query.index('@')
          # find by email
          return key if val[:email] == query
        else
          return key if val[:kpublic] == query
        end
      }
      nil
    end
    
  end
end
