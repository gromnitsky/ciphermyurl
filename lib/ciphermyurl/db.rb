require 'uri'
require 'haml'
require 'digest/sha2'

module CipherMyUrl

  module Data
    DATA_MIN = 'http://q.we'.size # 11
    DATA_MAX = 512
    PW_MIN = 8
    PW_MAX = 64
    
    extend self
    
    def valid_uri?(uri)
      return true if URI.parse(uri).scheme
      return false
    rescue
      false
    end
    
    def clean(data)
      r = data.to_s.strip
      r = valid_uri?(r) ? r : Haml::Helpers.escape_once(r)
      raise if r.size < DATA_MIN || r.size > DATA_MAX
      r
    rescue
      fail "data must be in range [#{DATA_MIN}-#{DATA_MAX}]"
    end

    def valid_pw?(pw)
      p = pw.to_s
      unless p.match(/^[a-zA-Z0-9]{#{PW_MIN},#{PW_MAX}}$/)
        fail "password length must be in the range [#{PW_MIN}-#{PW_MAX}] and contain [a-zA-Z0-9] only"
      end
      p
    end

    def valid_slot?(slot)
      s = slot.to_s
      unless s.match(/^\d+$/)
        fail "slot must be an unsigned integer"
      end
      s
    end
  end

  # See test_cipher.rb for examples.
  module MyDB
    extend self

    def adapter
      return @adapter if @adapter
      fail "db adapter isn't selected"
    end

    def setAdapter(adapter_name, opt)
      @opt = opt
      case adapter_name
      when Symbol, String
        require_relative "db/#{adapter_name}"
        @adapter = MyDB::Adapters.const_get adapter_name.to_s.capitalize
        @adapter.init opt
      else
        fail "invalid adapter #{adapter_name}"
      end
    end

    # Delete the whole database
    def rmdb
      adapter.rmdb
    end

    def [](slot)
      adapter.getValue slot
    end

    def getCount
      adapter.getValue 'count'
    end

    # [user]  email
    # [pw]    would be hashed
    #
    # FIXME: check 'user'
    def pack(data, user, pw)
      pw = Data.valid_pw?(pw)
      data = Data.clean data
      
      adapter.pack data, user, Digest::SHA256.hexdigest(data+pw)
    end

    def del(slot)
      slot = Data.valid_slot?(slot)
      
      adapter.del slot
    end
    
  end
end
