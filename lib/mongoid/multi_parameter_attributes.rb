# encoding: utf-8
module Mongoid #:nodoc:
  module MultiParameterAttributes
    def process(attrs = nil)
      if attrs
        attributes = {}
        multi_parameter_attributes = {}
      
        attrs.each_pair do |key, value|
          if /^([^\(]+)\((\d+)([ifas])\)$/ === key
            key, index = $1, $2.to_i
            value = value.send(:"to_#{$3}") if $3
            (multi_parameter_attributes[key] ||= {})[index] = value
          else
            attributes[key] = value
          end
        end
        
        multi_parameter_attributes.each_pair do |key, values|
          values = (values.keys.min..values.keys.max).map { |i| values[i] }
          klass = self.class.fields[key].try(:type)
          attributes[key] = if klass == DateTime
            instantiate_time_object(*values).to_datetime
          elsif klass == Date
            instantiate_time_object(*values).to_date
          elsif klass == Time
            instantiate_time_object(*values).to_time
          elsif klass
            klass.new *values
          else
            values
          end
        end
        
        super attributes
      else
        super
      end
    end
    
  protected
    def instantiate_time_object(*values)
      (Time.zone || Time).send(Mongoid::Config.instance.use_utc? ? :utc : :local, *values)
    end
  end
end