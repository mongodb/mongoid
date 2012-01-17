# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash #:nodoc:

      # Expands complex criterion into mongodb selectors.
      module ReductionHelpers

        # Expand the reduction fields into a 3-column matrix.
        #
        # @example Convert the criterion.
        #   {}.expand_reduction_fields
        #
        # @return [ Array ] Array of arrays of fields.
        def expand_reduction_fields
          fields = []
          each do |k, v|
            case v.class.name
            when "Array"
              v.each{|func| fields << [k, "#{k}_#{func}".gsub('.', '_'), func]}
            when "Symbol"
              fields << [k, "#{k}_#{v}".gsub('.', '_'), v]
            when "String"
              fields << [k, k.to_s, v]
            else
              puts v.class.name
              raise ArgumentError, "Unable to expand reduction field for function: #{v}"
            end
          end
          fields
        end
      end
    end
  end
end
