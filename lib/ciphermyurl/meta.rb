require 'ostruct'

module CipherMyUrl
  module Meta # :nodoc:
    NAME = 'CipherMyUrl'
    VERSION = '0.0.1'
    API_VERSION = '0.0.1'
    AUTHOR = 'Alexander Gromnitsky'
    EMAIL = 'alexander.gromnitsky@gmail.com'
    HOMEPAGE = 'http://github.com/gromnitsky/' + NAME

    def self.to_ostruct
      o = OpenStruct.new
      Meta.constants.each do |idx|
        name = idx.to_s.downcase
        o.new_ostruct_member name
        o.send "#{name}=", Meta.const_get(idx)
      end
      
      o.extend Enumerable
      def o.each &block
        @table.each &block
      end
      
      o
    end

  end
end
