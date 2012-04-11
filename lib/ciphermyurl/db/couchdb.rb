require 'couchrest'

module CipherMyUrl
  module MyDB
    module Adapters

      # This module-adapter loads at run-time by MyDB module. See db.rb.
      #
      # Instead of deleting slots we mark them as 'deleted', see #del.
      module Couchdb
        extend self

        DEL_MUTEX = Mutex.new

        def getValue(id)
          r = @db.get(id)
          return nil if r[:del] == true # doc was marked as 'deleted'
          
          # clean the result by not including the redundant CouchDB staff
          v = {}
          v[:data] = r[:data]
          v[:user] = r[:user]
          v[:pwhash] = r[:pwhash]
          v[:created] = r[:created]
          v
        rescue
          nil
        end

        # I beg this is not very fast.
        def getCount
          r = @db.view('app/count')
          return 0 if r['rows'].size != 1
          r['rows'].first['value']
        rescue
#          pp $!
          nil
        end

        # Create a view for counting all documents
        def viewCountCreate
          @db.save_doc({
                         '_id' => '_design/app',
                         :views => {
                           :count => {
                             :map => 'function(d) { emit(null, null) }',
                             :reduce => '_count'
                           }
                         }
                       })
        end
        
        def init(opt)
          @opt = opt

          u = "http#{opt[:tls] ? 's' : ''}://#{opt[:login]}:#{opt[:pw]}@#{opt[:host]}:#{opt[:port]}/#{opt[:dbname]}"
          @db = CouchRest.database! u

          viewCountCreate unless getCount
        end

        def rmdb
          @db.delete!
        end

        # Return a generated slot number.
        def pack(data, user, pw)
          fail "no counter in db" unless slot = getCount
          slot = (slot+1).to_s
          
          # make new
          @db.save_doc('_id' => slot,
                       :data => data,
                       :user => user,
                       :pwhash => pw,
                       :created => Time.now.utc.to_i)
          slot
        rescue
          # Probably someone else has created slot with this number.
          # That's what you get without a transactions support.
          raise "failed to create slot ##{slot}: #{$!}"
        end

        def del(id)
          DEL_MUTEX.synchronize {
            slot = @db.get(id)
            slot[:del] = true
            @db.save_doc slot
          }
        end
        
      end
    end
  end
end
