module Mongoid #:nodoc:
  module Attributes #:nodoc:
    # Process the provided attributes casting them to their proper values if a
    # field exists for them on the +Document+.
    def process(attrs = {})
      attrs.each_pair do |key, value|
        send("#{key}=", value)
      end
    end
  end
end
