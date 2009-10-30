module Mongoid #:nodoc:
  module Attributes #:nodoc:
    # Process the provided attributes casting them to their proper values if a
    # field exists for them on the +Document+.
    def process(fields, params)
      attributes = HashWithIndifferentAccess.new(params)
      fields.values.each do |field|
        value = field.set(attributes[field.name])
        attributes[field.name] = value if value
      end
      attributes
    end

  end
end
