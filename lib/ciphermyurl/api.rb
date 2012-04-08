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

      user = authenticated?(req[:kpublic], req[:kprivate])
      raise ApiUnauthorizedError, "invalid public or private key" unless user

      data = req
      data[:email] = user[:email]
      data
    end
    
    # req is a hash { data: '...', pw: '...', kpublic: '...', kprivate: '...' }
    def valid_packRequest?(req)
      return if req[:data] && req[:pw] && req[:kpublic] && req[:kprivate]
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
    
    # req is a hash { 'slot' => '...', 'pw' => '...' }
    def delRequestRead(req)
      valid_delRequest?(req)
    end

    def valid_delRequest?(req)
      valid_unpackRequest?(req)
    end
    
    # data is a hash { slot: '...', pw: '...' }
    def del(req)
      Data.valid_slot?(req ? req[:slot] : nil) rescue raise ApiBadRequestError, $!
      
      data = CipherMyUrl::MyDB[req[:slot]]
      return false unless data

      raise ApiUnauthorizedError, "invalid password" unless pwEqual?(req[:pw], data)

      CipherMyUrl::MyDB.del req[:slot]
    end
    
  end
end
