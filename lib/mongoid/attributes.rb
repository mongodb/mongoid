module Mongoid #:nodoc:
  module Attributes #:nodoc:
    # Process the provided attributes casting them to their proper values if a
    # field exists for them on the +Document+.
    def process(params = nil)
      @attributes = (params || {}).with_indifferent_access
      process_attributes
    end

    protected
    def process_attributes
      @attributes.each_pair do |key, value|
        send("#{key}=", value)
      end
    end

  end
end
