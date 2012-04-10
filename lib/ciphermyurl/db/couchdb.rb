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
          tries = 5
          n = nil
          begin
            unless slot = @db.get('count')
              tries = 0
              fail "no counter in db"
            end
            n = slot[:last] + 1

            # update count
            @db.save_doc('_id' => 'count',
                         '_rev' => slot['_rev'],
                         :last => n)
            # make new
            @db.save_doc('_id' => n.to_s,
                         :data => data,
                         :user => user,
                         :pwhash => pw)
          rescue
            # someone else has created slot with this number
            n += 1
            tries -= 1
#            $stderr.puts "***** TRIES=#{tries}, n=#{n}****"
            retry if tries > 0
            
            raise "failed to create a new slot: #{$!}"
          end
          
          n.to_s
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
