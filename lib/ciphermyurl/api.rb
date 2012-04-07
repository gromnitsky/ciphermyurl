require 'json'
require 'net/http'

require_relative 'db'
require_relative 'auth'

module CipherMyUrl

  class ApiException < Exception
  end
  class ApiBadRequestError < ApiException
  end
  class ApiUnauthorizedError < ApiException
  end
  class ApiInvalidSlotError < ApiException
  end

  module Api
    include Auth
    extend self

    VERSION = '0.0.1'

    # [pw]    password in plain text
    # [data]  value from MyDB[slot]
    def pwEqual?(pw, data)
      data[:pwhash] == Digest::SHA256.hexdigest(data[:data]+pw)
    end
    
    
    def packRequestRead(io)
      req = {}
      begin
        req = JSON.parse io.read, symbolize_names: true
        valid_packRequest?(req)
      rescue
        raise ApiBadRequestError, $!
      end

      user = authenticated?(req[:keyshash])
      raise ApiUnauthorizedError, "keyshash is missing in the our DB" unless user

      data = req
      data[:email] = user[:email]
      data
    end
    
    # req is a hash { data: '...', pw: '...', keyshash: '...' }
    def valid_packRequest?(req)
      return if req[:data] && req[:pw] && req[:keyshash]
      raise ApiBadRequestError, 'validation of JSON failed'
    end
    
    # data is a hash { data: '...', email: '...', pw: '...' }
    # Checking for nils.
    def pack(data)
      CipherMyUrl::MyDB.pack data[:data], data[:email], data[:pw]
    end

    # ---
    
    # req is a hash { 'slot' => '...', 'pw' => '...' }
    def unpackRequestRead(req)
      valid_unpackRequest?(req)
    end

    def valid_unpackRequest?(req)
      if req && req['slot'] && req['pw']
        r = {}
        r[:slot] = req['slot'].to_s
        r[:pw] = req['pw'].to_s
        r
      else
        raise ApiBadRequestError, 'slot and password are both required'
      end
    end
    
    # req is a hash { slot: '...', pw: '...' }
    def unpack(req)
      Data.valid_slot?(req ? req[:slot] : nil) rescue raise ApiBadRequestError, $!
      
      data = CipherMyUrl::MyDB[req[:slot]]
      raise ApiInvalidSlotError, "no such slot" unless data

      unless pwEqual?(req[:pw], data)
        raise ApiUnauthorizedError, "invalid password"
      end

      data[:data]
    end
    
    # ---
    
    # req is a hash { 'slot' => '...', 'keyshash' => '...' }
    def delRequestRead(req)
      valid_delRequest?(req)
    end

    def valid_delRequest?(req)
      if req && req['slot'] && req['keyshash']
        r = {}
        r[:slot] = req['slot'].to_s
        r[:keyshash] = req['keyshash'].to_s
        r
      else
        raise ApiBadRequestError, 'slot and keyshash are both required'
      end
    end
    
    # data is a hash { slot: '...', keyshash: '...' }
    def del(req)
      Data.valid_slot?(req ? req[:slot] : nil) rescue raise ApiBadRequestError, $!
      
      data = CipherMyUrl::MyDB[req[:slot]]
      return false unless data

      raise ApiException, 'Auth DB is corrupted' unless keyshash = keyshash_findBy(data[:user])
      raise ApiUnauthorizedError, "invalid keyshash" unless keyshash == req[:keyshash]

      CipherMyUrl::MyDB.del req[:slot]
    end
    
  end
end
