require 'couchrest'

module CipherMyUrl
  module MyDB
    module Adapters

      # This module-adapter loads at run-time by MyDB module. See db.rb.
      module Couchdb
        extend self

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

          u = "http#{opt[:tls] ? 's' : ''}://#{opt[:login]}:#{opt[:pw]}@#{opt[:host]}:#{opt[:port]}/#{opt[:dbname]}"
          @db = CouchRest.database! u

#          $stderr.puts "*****#{getValue('count')}****"
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

          tries = 5
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
#            $stderr.puts "***** TRIES: #{tries}****"
            slot[:last] += 1
            tries -= 1
            retry if tries > 0
            
            return nil
          end
          
          slot[:last].to_s
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
