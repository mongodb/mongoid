# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Internal #:nodoc:
      # Defines the behaviour for hash fields.
      class Hash
        include Serializable
        
        def selection(object)
          serialize(object)
        end

        def serialize(object)
          if options[:sorted] == true && object.is_a?(::Hash)
            sorted_hash = {}
            object.keys.sort.each {|x| sorted_hash[x] = serialize(object[x])}
            sorted_hash
          else
            object
          end
        end
      end
    end
  end
end
