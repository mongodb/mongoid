# encoding: utf-8
module Mongoid #:nodoc:
  module MultiParameterAttributes
    module Errors
      # Raised when an error occurred while doing a mass assignment to an attribute through the
      # <tt>attributes=</tt> method. The exception has an +attribute+ property that is the name of the
      # offending attribute.
      class AttributeAssignmentError < Mongoid::Errors::MongoidError
        attr_reader :exception, :attribute
        def initialize(message, exception, attribute)
          @exception = exception
          @attribute = attribute
          @message = message
        end
      end

      # Raised when there are multiple errors while doing a mass assignment through the +attributes+
      # method. The exception has an +errors+ property that contains an array of AttributeAssignmentError
      # objects, each corresponding to the error while assigning to an attribute.
      class MultiparameterAssignmentErrors < Mongoid::Errors::MongoidError
        attr_reader :errors
        def initialize(errors)
          @errors = errors
        end
      end
    end

    def process(attrs = nil)
      if attrs
        errors = []
        attributes = {}
        multi_parameter_attributes = {}

        attrs.each_pair do |key, value|
          if key =~ /^([^\(]+)\((\d+)([if])\)$/
            key, index = $1, $2.to_i
            (multi_parameter_attributes[key] ||= {})[index] = value.empty? ? nil : value.send("to_#{$3}")
          else
            attributes[key] = value
          end
        end

        multi_parameter_attributes.each_pair do |key, values|
          begin
            values = (values.keys.min..values.keys.max).map { |i| values[i] }
            klass = self.class.fields[key].try(:type)
            attributes[key] = instantiate_object(klass, values)
          rescue => e
            errors << Errors::AttributeAssignmentError.new("error on assignment #{values.inspect} to #{key}", e, key)
          end
        end

        unless errors.empty?
          raise Errors::MultiparameterAssignmentErrors.new(errors), "#{errors.size} error(s) on assignment of multiparameter attributes"
        end

        super attributes
      else
        super
      end
    end

  protected

    def instantiate_object(klass, values_with_empty_parameters)
      return nil if values_with_empty_parameters.all? { |v| v.nil? }
      
      values = values_with_empty_parameters.collect { |v| v.nil? ? 1 : v }
      
      if klass == DateTime || klass == Date || klass == Time
        klass.send(:convert_to_time, values)
      elsif klass
        klass.new *values
      else
        values
      end
    end

  end
end
