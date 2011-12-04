# encoding: utf-8
module Mongoid #:nodoc:
  class Javascript
    # Constant for the file that defines all the js functions.
    FUNCTIONS = File.join(File.dirname(__FILE__), "javascript", "functions.yml")
    FUNCTION_HASH = YAML.load(File.read(FUNCTIONS))

    # Load the javascript functions and define a class method for each one,
    # that memoizes the value.
    #
    # @example Get the function.
    #   Mongoid::Javascript.aggregate
    FUNCTION_HASH.each_pair do |key, function|
      (class << self; self; end).class_eval <<-EOT
        def #{key}
          @#{key} ||= "function(obj, prev) { #{function} }"
        end
      EOT
    end
    
    # Create a compound function to perform multiple reduction actions
    # 
    # @param [ Hash ] fields
    #
    # @example Create a compound action with sum and aggregate
    #   Javascript.compound :age => [:sum, :max]
    #
    def self.compound(fields)
      functions = fields.expand_reduction_fields.map do |field, name, func|
        func = func.to_s
        if FUNCTION_HASH[func]
          FUNCTION_HASH[func].gsub("[field]", field.to_s).gsub(func, name)
        else
          func.gsub("[field]", field.to_s)
        end
      end.join("\n")
      "function(obj, prev) { #{functions} }"
    end
    
    # Create a compound function to perform multiple finalize actions
    # 
    # @param [ Hash ] fields
    #
    # @example Create a compound action with sum and aggregate
    #   Javascript.compound_finalize :age_sum => :sum, :age_max => :max
    #
    def self.compound_finalize(fields)
      functions = fields.expand_reduction_fields.map do |field, name, func|
        func = func.to_s
        if FUNCTION_HASH["#{func}_finalize"]
          FUNCTION_HASH["#{func}_finalize"].gsub(func, "#{field}_#{func}")
        else
          func
        end
      end.join("\n")
      "function(obj, prev) { #{functions} }"
    end
        
  end
end
