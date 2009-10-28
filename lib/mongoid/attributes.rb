module Mongoid #:nodoc:
  module Attributes #:nodoc:
    # Process the provided attributes casting them to their proper values if a
    # field exists for them on the +Document+.
    def process(fields, params)
      attributes = HashWithIndifferentAccess.new(params)
      attributes.each_pair do |key, value|
        attributes[key] = fields[key].value(value) if fields[key]
      end
    end

  end
end
