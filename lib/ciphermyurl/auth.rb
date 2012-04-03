require 'pathname'
require 'digest/md5'
require 'yaml'

# User after captcha has keys_hash:
# 6e7ac725191d7ea69f2555c47dd28680
# (This record always exists in the apikeys db.)
#
# How to add api keys:
#
# 1. Edit yaml file by hand
# 2. Connect to a running sinatra instance with racksh
# 3. Run 'apikeys_load'

module CipherMyUrl
  module Auth
    ROOT = Pathname.new(File.dirname(__FILE__)).parent.parent
    APIKEYS = ROOT + 'apikeys.yaml'

    def self.keys_hash(kpubic, kprivate)
      Digest::MD5.hexdigest(kpubic + kprivate)
    end
    
    BROWSER_USER_PUBLIC = '0588d4b8-7d7d-47b9-9296-ac4f043b156f'
    BROWSER_USER_PPRIVATE = '79ec4297f7385f09638e418c98f797a99dda7c3e085e5a5b2a0d5e37303e0da6'
    BROWSER_USER_KEYSHASH = Auth.keys_hash BROWSER_USER_PUBLIC, BROWSER_USER_PPRIVATE

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
          return key if val[:uuid] == query
        end
      }
      nil
    end
    
  end
end
