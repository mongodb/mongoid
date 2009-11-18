module Mongoid #:nodoc:
  module Attributes #:nodoc:
    # Process the provided attributes casting them to their proper values if a
    # field exists for them on the +Document+. This will be limited to only the
    # attributes provided in the suppied +Hash+ so that no extra nil values get
    # put into the document's attributes.
    def process(attrs = {})
      attrs.each_pair do |key, value|
        send("#{key}=", value)
      end
    end
  end
end
