require 'couchrest'

require_relative '../meta'

module CipherMyUrl
  module MyDB
    module Adapters

      # This module-adapter loads at run-time by MyDB module. See db.rb.
      module Couchdb
        extend self
        DBNAME = Meta.to_ostruct.name.downcase

        def getValue(id)
          r = @db.get(id)
          return r[:last] if id == 'count'

          # clean the result by not including the redundant CouchDB staff
          v = {}
          v[:data] = r[:data]
          v[:user] = r[:user]
          v[:pwhash] = r[:pwhash]
          v
        rescue
          nil
        end
        
        def init(opt)
          @opt = opt

          u = "http#{opt[:tls] ? 's' : ''}://#{opt[:login]}:#{opt[:pw]}@#{opt[:host]}:#{opt[:port]}/#{DBNAME}"
          @db = CouchRest.database! u

          unless getValue('count')
            @db.save_doc '_id' => 'count', :last => 0
          end
        end

        def rmdb
          @db.delete!
        end

        # Return a generated slot number.
        def pack(data, user, pw)
          return nil unless slot = @db.get('count')
          slot[:last] += 1

          begin
            # make new
            @db.save_doc('_id' => slot[:last].to_s,
                         :data => data,
                         :user => user,
                         :pwhash => pw)
            # update count
            @db.save_doc('_id' => 'count',
                         '_rev' => slot['_rev'],
                         :last => slot[:last])
          rescue
            # someone else has created slot with this number
            return nil
          end
          
          slot[:last]
        end

        def del(slot)
          @db.delete_doc @db.get(slot)
          true
        rescue
          false
        end
        
      end
    end
  end
end
