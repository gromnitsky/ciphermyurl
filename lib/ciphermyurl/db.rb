require 'uri'
require 'haml'

module CipherMyUrl

  module Data
    DATA_MIN = 11
    DATA_MAX = 512
    
    extend self
    
    def valid_uri?(uri)
      return true if URI.parse(uri).scheme
      return false
    rescue
      false
    end
    
    def clean(data)
      r = data.strip
      r = valid_uri?(r) ? r : Haml::Helpers.escape_once(r)
      fail 'the input to the cipher is not appropriate' if r.size < DATA_MIN || r.size > DATA_MAX
      r
    end

    def valid_pw?(pw)
      pw.match(/^[a-zA-Z0-9]{8,64}$/) ? true : false
    end
  end

  module MyDB
    extend self

    def adapter
      return @adapter if @adapter
      fail "db adapter isn't selected"
    end

    def setAdapter(adapter_name, opt)
      case adapter_name
      when Symbol, String
        require_relative "db/#{adapter_name}"
        @adapter = MyDB::Adapters.const_get adapter_name.to_s.capitalize
        @adapter.init opt
      else
        fail "invalid adapter #{adapter_name}"
      end
    end

    def [](key)
      adapter.getValue(key)
    end

    def getCount
      adapter.getValue('count')
    end

    # Yes, I need a boolean, not actual value. Stop laughing.
    def key?(key)
      adapter.getValue(key) ? true : false
    end

    def pack(data, pw)
      fail 'invalid password' unless Data.valid_pw?(pw)
      data = Data.clean data
      
      adapter.pack(data, pw)
    end
    
  end
end
