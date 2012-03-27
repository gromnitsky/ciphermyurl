require 'pstore'

module CipherMyUrl
  module MyDB
    module Adapters
      
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

        def pack(data, pw)
          @store.transaction {
            @store['count'] += 1
            @store[@store['count'].to_s] = {
              data: data,
              pw: pw
            }
          }
        end
        
      end

    end
  end
end
