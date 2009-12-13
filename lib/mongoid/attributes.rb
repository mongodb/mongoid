# encoding: utf-8
module Mongoid #:nodoc:
  module Attributes

    # Process the provided attributes casting them to their proper values if a
    # field exists for them on the +Document+. This will be limited to only the
    # attributes provided in the suppied +Hash+ so that no extra nil values get
    # put into the document's attributes.
    def process(attrs = {})
      attrs.each_pair do |key, value|
        send("#{key}=", value)
      end
    end

    # Read a value from the +Document+ attributes. If the value does not exist
    # it will return nil.
    #
    # Options:
    #
    # name: The name of the attribute to get.
    #
    # Example:
    #
    # <tt>person.read_attribute(:title)</tt>
    def read_attribute(name)
      fields[name].get(@attributes[name])
    end

    # Remove a value from the +Document+ attributes. If the value does not exist
    # it will fail gracefully.
    #
    # Options:
    #
    # name: The name of the attribute to remove.
    #
    # Example:
    #
    # <tt>person.remove_attribute(:title)</tt>
    def remove_attribute(name)
      @attributes.delete(name)
    end

    # Write a single attribute to the +Document+ attribute +Hash+. This will
    # also fire the before and after update callbacks, and perform any
    # necessary typecasting.
    #
    # Options:
    #
    # name: The name of the attribute to update.
    # value: The value to set for the attribute.
    #
    # Example:
    #
    # <tt>person.write_attribute(:title, "Mr.")</tt>
    #
    # This will also cause the observing +Document+ to notify it's parent if
    # there is any.
    def write_attribute(name, value)
      run_callbacks(:before_update)
      @attributes[name] = fields[name].set(value)
      run_callbacks(:after_update)
      notify
    end

    # Writes the supplied attributes +Hash+ to the +Document+. This will only
    # overwrite existing attributes if they are present in the new +Hash+, all
    # others will be preserved.
    #
    # Options:
    #
    # attrs: The +Hash+ of new attributes to set on the +Document+
    #
    # Example:
    #
    # <tt>person.write_attributes(:title => "Mr.")</tt>
    #
    # This will also cause the observing +Document+ to notify it's parent if
    # there is any.
    def write_attributes(attrs)
      process(attrs)
      notify
    end

  end
end
