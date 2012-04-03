require 'pstore'

module CipherMyUrl
  module MyDB
    
    module Adapters
      # This module-adapter loads at run-time by MyDB module. See db.rb.
      module Pstore
        extend self

        def getValue(key)
          @store.transaction(true) {
            @store[key]
          }
        rescue
          nil
        end
        
        def init(opt)
          # thread-safe
          @store = PStore.new(opt[:file], true)
          @store.ultra_safe = true

          unless getValue('count')
            @store.transaction { @store['count'] = 0 }
          end
        end

        # Return a generated slot number.
        def pack(data, user, pw)
          slot = nil
          
          @store.transaction {
            @store['count'] += 1
            slot = @store['count'].to_s
            @store[slot] = {
              data: data,
              user: user,
              pwhash: pw
            }
          }

          slot
        end

        def del(slot)
          r = false
          @store.transaction {
            # Hash#delete return a deleted key value, and we need just a
            # boolean
            r = true unless @store.delete(slot)
          }
          r
        end
        
      end
    end
    
  end
end
