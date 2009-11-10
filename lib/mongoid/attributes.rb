module Mongoid #:nodoc:
  module Attributes #:nodoc:
    # Process the provided attributes casting them to their proper values if a
    # field exists for them on the +Document+.
    def process(params)
      @attributes = HashWithIndifferentAccess.new(params)
      process_fields
      process_associations
    end

    protected
    def process_fields
      fields.values.each do |field|
        value = field.set(@attributes[field.name])
        @attributes[field.name] = value if value
      end
    end

    def process_associations
      @attributes.each_pair do |key, value|
        @attributes[key] = send("#{key}=", value) if value.is_a?(Document)
      end
    end

  end
end
