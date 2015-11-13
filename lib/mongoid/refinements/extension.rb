# encoding: utf-8
module Mongoid
  module Refinements

    # Defines refinements around extending objects with new behaviour.
    #
    # @since 6.0.0
    module Extension

      # The object id extended JSON constant.
      #
      # @since 6.0.0
      OID = '$oid'.freeze

      refine ActiveSupport::TimeWithZone do

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   date_time.mongoize
        #
        # @return [ Time ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize
          ::ActiveSupport::TimeWithZone.mongoize(self)
        end
      end

      refine ActiveSupport::TimeWithZone.singleton_class do

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   TimeWithZone.demongoize(object)
        #
        # @param [ Time ] object The time from Mongo.
        #
        # @return [ TimeWithZone ] The object as a date.
        #
        # @since 6.0.0
        def demongoize(object)
          return nil if object.blank?
          ::Time.demongoize(object).in_time_zone
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   TimeWithZone.mongoize("2012-1-1")
        #
        # @param [ Object ] object The object to convert.
        #
        # @return [ Time ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize(object)
          ::Time.mongoize(object)
        end
      end

      refine Array do

        # Get the array of args as arguments for a find query.
        #
        # @example Get the array as find args.
        #   [ 1, 2, 3 ].as_find_arguments
        #
        # @return [ Array ] The array of args.
        #
        # @since 6.0.0
        def as_find_arguments
          flat_map{ |a| a.as_find_arguments }.uniq{ |a| a.to_s }
        end

        # Check if the array is part of a blank relation criteria.
        #
        # @example Is the array blank criteria?
        #   [].blank_criteria?
        #
        # @return [ true, false ] If the array is blank criteria.
        #
        # @since 6.0.0
        def blank_criteria?
          any?{ |a| a.blank_criteria? }
        end

        # Delete the first object in the array that is equal to the supplied
        # object and return it. This is much faster than performing a standard
        # delete for large arrays ince it attempt to delete multiple in the
        # other.
        #
        # @example Delete the first object.
        #   [ "1", "2", "1" ].delete_one("1")
        #
        # @param [ Object ] object The object to delete.
        #
        # @return [ Object ] The deleted object.
        #
        # @since 2.1.0
        def delete_one(object)
          position = index(object)
          position ? delete_at(position) : nil
        end

        # Evolve the array into an array of object ids.
        #
        # @example Evolve the array to object ids.
        #   [ id ].evolve_object_id
        #
        # @return [ Array<BSON::ObjectId> ] The converted array.
        #
        # @since 6.0.0
        def evolve_object_id
          map!{ |o| o.evolve_object_id }; self
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   object.mongoize
        #
        # @return [ Array ] The object.
        #
        # @since 6.0.0
        def mongoize
          ::Array.mongoize(self)
        end

        # Mongoize the array into an array of object ids.
        #
        # @example Evolve the array to object ids.
        #   [ id ].mongoize_object_id
        #
        # @return [ Array<BSON::ObjectId> ] The converted array.
        #
        # @since 6.0.0
        def mongoize_object_id
          map!{ |o| o.mongoize_object_id }.compact!; self
        end

        # Converts the array for storing as a time.
        #
        # @example Convert the array to a time.
        #   [ 2010, 1, 1 ].mongoize_time
        #
        # @return [ Time ] The time.
        #
        # @since 6.0.0
        def mongoize_time
          ::Time.configured.local(*self)
        end

        # Is the array a set of multiple arguments in a method?
        #
        # @example Is this multi args?
        #   [ 1, 2, 3 ].multi_arged?
        #
        # @return [ true, false ] If the array is multi args.
        #
        # @since 6.0.0
        def multi_arged?
          !first.is_a?(Hash) && first.resizable? || size > 1
        end

        # Is the object's size changable?
        #
        # @example Is the object resizable?
        #   [].resizable?
        #
        # @return [ true ] true.
        #
        # @since 6.0.0
        def resizable?; true; end
      end

      refine Array.singleton_class do

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Array.mongoize([ 1, 2, 3 ])
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Array ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize(object)
          if object.is_a?(::Array)
            evolve(object).collect{ |obj| obj.class.mongoize(obj) }
          else
            evolve(object)
          end
        end

        # Convert the provided object to a propery array of foreign keys.
        #
        # @example Mongoize the object.
        #   Array.mongoize_fk(constraint, object)
        #
        # @param [ Constraint ] constraint The metadata constraint.
        # @param [ Object ] object The object to convert.
        #
        # @return [ Array ] The array of ids.
        #
        # @since 6.0.0
        def mongoize_fk(constraint, object)
          if object.resizable?
            object.blank? ? object : constraint.convert(object)
          else
            object.blank? ? [] : constraint.convert(Array(object))
          end
        end

        # Is the object's size changable?
        #
        # @example Is the object resizable?
        #   Array.resizable?
        #
        # @return [ true ] true.
        #
        # @since 6.0.0
        def resizable?; true; end
      end

      refine BigDecimal do

        # Convert the big decimal to an $inc-able value.
        #
        # @example Convert the big decimal.
        #   bd.to_inc
        #
        # @return [ Float ] The big decimal as a float.
        #
        # @since 6.0.0
        def to_inc
          to_f
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   object.mongoize
        #
        # @return [ Object ] The object.
        #
        # @since 6.0.0
        def mongoize
          to_s
        end
      end

      refine BigDecimal.singleton_class do

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Object.demongoize(object)
        #
        # @param [ Object ] object The object to demongoize.
        #
        # @return [ Object ] The object.
        #
        # @since 6.0.0
        def demongoize(object)
          if object
            object.numeric? ? ::BigDecimal.new(object.to_s) : object
          end
        end

        # Mongoize an object of any type to how it's stored in the db as a big
        # decimal.
        #
        # @example Mongoize the object.
        #   BigDecimal.mongoize(123)
        #
        # @param [ Object ] object The object to Mongoize
        #
        # @return [ String ] The mongoized object.
        #
        # @since 6.0.0
        def mongoize(object)
          object ? object.to_s : object
        end
      end

      refine BSON::ObjectId do

        # Evolve the object id.
        #
        # @example Evolve the object id.
        #   object_id.evolve_object_id
        #
        # @return [ BSON::ObjectId ] self.
        #
        # @since 6.0.0
        def evolve_object_id; self; end
        alias :mongoize_object_id :evolve_object_id
      end

      refine BSON::ObjectId.singleton_class do

        # Evolve the object into a mongo-friendly value to query with.
        #
        # @example Evolve the object.
        #   ObjectId.evolve(id)
        #
        # @param [ Object ] object The object to evolve.
        #
        # @return [ BSON::ObjectId ] The object id.
        #
        # @since 6.0.0
        def evolve(object)
          object.evolve_object_id
        end

        # Convert the object into a mongo-friendly value to store.
        #
        # @example Convert the object.
        #   ObjectId.mongoize(id)
        #
        # @param [ Object ] object The object to convert.
        #
        # @return [ BSON::ObjectId ] The object id.
        #
        # @since 6.0.0
        def mongoize(object)
          object.mongoize_object_id
        end
      end

      refine Date do

        # Convert the date into a time.
        #
        # @example Convert the date to a time.
        #   date.__mongoize_time__
        #
        # @return [ Time ] The converted time.
        #
        # @since 6.0.0
        def mongoize_time
          ::Time.configured.local(year, month, day)
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   date.mongoize
        #
        # @return [ Time ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize
          ::Date.mongoize(self)
        end
      end

      refine Date.singleton_class do

        # Constant for epoch - used when passing invalid times.
        DATE_EPOCH = ::Date.new(1970, 1, 1).freeze

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Date.demongoize(object)
        #
        # @param [ Time ] object The time from Mongo.
        #
        # @return [ Date ] The object as a date.
        #
        # @since 6.0.0
        def demongoize(object)
          ::Date.new(object.year, object.month, object.day) if object
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Date.mongoize("2012-1-1")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Time ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize(object)
          unless object.blank?
            begin
              time = object.mongoize_time
              ::Time.utc(time.year, time.month, time.day)
            rescue ArgumentError
              DATE_EPOCH
            end
          end
        end
      end

      refine DateTime do

        # Mongoize the date time into a time.
        #
        # @example Mongoize the date time.
        #   date_time.mongoize_time
        #
        # @return [ Time ] The mongoized time.
        #
        # @since 6.0.0
        def mongoize_time
          return to_time if utc? && Mongoid.use_utc?
          if Mongoid.use_activesupport_time_zone?
            in_time_zone(::Time.zone).to_time
          else
            time = to_time
            time.respond_to?(:getlocal) ? time.getlocal : time
          end
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   date_time.mongoize
        #
        # @return [ Time ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize
          ::DateTime.mongoize(self)
        end
      end

      refine DateTime.singleton_class do

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   DateTime.demongoize(object)
        #
        # @param [ Time ] object The time from Mongo.
        #
        # @return [ DateTime ] The object as a date.
        #
        # @since 6.0.0
        def demongoize(object)
          ::Time.demongoize(object).try(:to_datetime)
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   DateTime.mongoize("2012-1-1")
        #
        # @param [ Object ] object The object to convert.
        #
        # @return [ Time ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize(object)
          ::Time.mongoize(object)
        end
      end

      refine FalseClass do

        # Get the value of the object as a mongo friendy sort value.
        #
        # @example Get the object as sort criteria.
        #   false.sortable
        #
        # @return [ Integer ] 0.
        #
        # @since 6.0.0
        def sortable
          0
        end

        # Is the passed value a boolean?
        #
        # @example Is the value a boolean type?
        #   false.is_a?(Boolean)
        #
        # @param [ Class ] other The class to check.
        #
        # @return [ true, false ] If the other is a boolean.
        #
        # @since 6.0.0
        def is_a?(other)
          if other == ::Boolean || other.class == ::Boolean
            return true
          end
          super(other)
        end
      end

      refine Float do

        # Convert the float into a time.
        #
        # @example Convert the float into a time.
        #   1335532685.117847.__mongoize_time__
        #
        # @return [ Time ] The float as a time.
        #
        # @since 6.0.0
        def mongoize_time
          ::Time.at(self)
        end

        # Is the float a number?
        #
        # @example Is the object a number?.
        #   object.numeric?
        #
        # @return [ true ] Always true.
        #
        # @since 6.0.0
        def numeric?
          true
        end
      end

      refine Float.singleton_class do

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Float.mongoize("123.11")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ String ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize(object)
          unless object.blank?
            __numeric__(object).to_f rescue 0.0
          else
            nil
          end
        end
        alias :demongoize :mongoize
      end

      refine Hash do

        # Check if the hash is part of a blank relation criteria.
        #
        # @example Is the hash blank criteria?
        #   {}.blank_criteria?
        #
        # @return [ true, false ] If the hash is blank criteria.
        #
        # @since 6.0.0
        def blank_criteria?
          self == { "_id" => { "$in" => [] }}
        end

        # Consolidate the key/values in the hash under an atomic $set.
        #
        # @example Consolidate the hash.
        #   { name: "Placebo" }.consolidate
        #
        # @return [ Hash ] A new consolidated hash.
        #
        # @since 6.0.0
        def consolidate(klass)
          consolidated = {}
          each_pair do |key, value|
            if key =~ /\$/
              value.each_pair do |_key, _value|
                value[_key] = (key == "$rename") ? _value.to_s : mongoize_for(key, klass, _key, _value)
              end
              (consolidated[key] ||= {}).merge!(value)
            else
              (consolidated["$set"] ||= {}).merge!(key => mongoize_for(key, klass, key, value))
            end
          end
          consolidated
        end

        # Deletes an id value from the hash.
        #
        # @example Delete an id value.
        #   {}.delete_id
        #
        # @return [ Object ] The deleted value, or nil.
        #
        # @since 6.0.0
        def delete_id
          delete("_id") || delete("id") || delete(:id) || delete(:_id)
        end

        # Evolves each value in the hash to an object id if it is convertable.
        #
        # @example Convert the hash values.
        #   { field: id }.evolve_object_id
        #
        # @return [ Hash<String, BSON::ObjectId> ] The converted hash.
        #
        # @since 6.0.0
        def evolve_object_id
          update_values{ |v| v.evolve_object_id }
        end

        # Get the id attribute from this hash, whether it's prefixed with an
        # underscore or is a symbol.
        #
        # @example Extract the id.
        #   { :_id => 1 }.extract_id
        #
        # @return [ Object ] The value of the id.
        #
        # @since 6.0.0
        def extract_id
          self["_id"] || self["id"] || self[:id] || self[:_id]
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   object.mongoize
        #
        # @return [ Hash ] The object.
        #
        # @since 6.0.0
        def mongoize
          ::Hash.mongoize(self)
        end

        # Mongoize for the klass, key and value.
        #
        # @example Mongoize for the klass, field and value.
        #   {}.mongoize_for(Band, "name", "test")
        #
        # @param [ Class ] klass The model class.
        # @param [ String, Symbol ] The field key.
        # @param [ Object ] value The value to mongoize.
        #
        # @return [ Object ] The mongoized value.
        #
        # @since 3.1.0
        def mongoize_for(operator, klass, key, value)
          field = klass.fields[key.to_s]
          if field
            val = field.mongoize(value)
            if Mongoid::Persistable::LIST_OPERATIONS.include?(operator) && field.resizable?
              val = val.first if !value.is_a?(Array)
            end
            val
          else
            value
          end
        end

        # Mongoizes each value in the hash to an object id if it is convertable.
        #
        # @example Convert the hash values.
        #   { field: id }.mongoize_object_id
        #
        # @return [ Hash ] The converted hash.
        #
        # @since 6.0.0
        def mongoize_object_id
          if id = self[OID]
            BSON::ObjectId.from_string(id)
          else
            update_values{ |v| v.mongoize_object_id }
          end
        end

        # Fetch a nested value via dot syntax.
        #
        # @example Fetch a nested value via dot syntax.
        #   { "name" => { "en" => "test" }}.nested_value("name.en")
        #
        # @param [ String ] string the dot syntax string.
        #
        # @return [ Object ] The matching value.
        #
        # @since 3.0.15
        def nested_value(string)
          keys = string.split(".")
          value = self
          keys.each do |key|
            nested = value[key] || value[key.to_i]
            value = nested
          end
          value
        end

        # Can the size of this object change?
        #
        # @example Is the hash resizable?
        #   {}.resizable?
        #
        # @return [ true ] true.
        #
        # @since 6.0.0
        def resizable?
          true
        end

        # Convert this hash to a criteria. Will iterate over each keys in the
        # hash which must correspond to method on a criteria object. The hash
        # must also include a "klass" key.
        #
        # @example Convert the hash to a criteria.
        #   { klass: Band, where: { name: "Depeche Mode" }.to_criteria
        #
        # @return [ Criteria ] The criteria.
        #
        # @since 3.0.7
        def to_criteria
          criteria = Criteria.new(delete(:klass) || delete("klass"))
          each_pair do |method, args|
            criteria = criteria.__send__(method, args)
          end
          criteria
        end
      end

      refine Hash.singleton_class do

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Hash.mongoize([ 1, 2, 3 ])
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Hash ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize(object)
          return if object.nil?
          evolve(object).update_values { |value| value.mongoize }
        end

        # Can the size of this object change?
        #
        # @example Is the hash resizable?
        #   Hash.resizable?
        #
        # @return [ true ] true.
        #
        # @since 6.0.0
        def resizable?
          true
        end
      end

      refine Integer do

        # Returns the integer as a time.
        #
        # @example Convert the integer to a time.
        #   1335532685.mongoize_time
        #
        # @return [ Time ] The converted time.
        #
        # @since 6.0.0
        def mongoize_time
          ::Time.at(self)
        end

        # Is the integer a number?
        #
        # @example Is the object a number?.
        #   object.numeric?
        #
        # @return [ true ] Always true.
        #
        # @since 6.0.0
        def numeric?
          true
        end

        # Is the object not to be converted to bson on criteria creation?
        #
        # @example Is the object unconvertable?
        #   object.unconvertable_to_bson?
        #
        # @return [ true ] If the object is unconvertable.
        #
        # @since 6.0.0
        def unconvertable_to_bson?
          true
        end
      end

      refine Integer.singleton_class do

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   BigDecimal.mongoize("123.11")
        #
        # @return [ String ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize(object)
          unless object.blank?
            __numeric__(object).to_i rescue 0
          else
            nil
          end
        end
        alias :demongoize :mongoize
      end

      refine Module do

        # Redefine the method. Will undef the method if it exists or simply
        # just define it.
        #
        # @example Redefine the method.
        #   Object.re_define_method("exists?") do
        #     self
        #   end
        #
        # @param [ String, Symbol ] name The name of the method.
        # @param [ Proc ] block The method body.
        #
        # @return [ Method ] The new method.
        #
        # @since 6.0.0
        def re_define_method(name, &block)
          undef_method(name) if method_defined?(name)
          define_method(name, &block)
        end
      end

      refine Mongoid::Boolean.singleton_class do

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Boolean.evolve("123.11")
        #
        # @return [ String ] The object evolved.
        #
        # @since 6.0.0
        def evolve(object)
          ::Boolean.evolve(object)
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Boolean.mongoize("123.11")
        #
        # @return [ String ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize(object)
          ::Boolean.evolve(object)
        end
      end

      refine NilClass do


        # Try to form a setter from this object.
        #
        # @example Try to form a setter.
        #   object.setter
        #
        # @return [ nil ] Always nil.
        #
        # @since 6.0.0
        def setter; self; end

        # Get the name of a nil collection.
        #
        # @example Get the nil name.
        #   nil.collectionize
        #
        # @return [ String ] A blank string.
        #
        # @since 6.0.0
        def collectionize
          to_s.collectionize
        end
      end

      refine Object do

        # Convert the object to args for a find query.
        #
        # @example Convert the object to args.
        #   object.as_find_arguments
        #
        # @return [ Object ] self.
        #
        # @since 6.0.0
        def as_find_arguments; self; end

        # Check if the object is part of a blank relation criteria.
        #
        # @example Is the object blank criteria?
        #   "".blank_criteria?
        #
        # @return [ true, false ] If the object is blank criteria.
        #
        # @since 6.0.0
        def blank_criteria?; false; end

        # Do or do not, there is no try. -- Yoda.
        #
        # @example Do or do not.
        #   object.do_or_do_not(:use, "The Force")
        #
        # @param [ String, Symbol ] name The method name.
        # @param [ Array ] *args The arguments.
        #
        # @return [ Object, nil ] The result of the method call or nil if the
        #   method does not exist.
        #
        # @since 6.0.0
        def do_or_do_not(name, *args)
          send(name, *args) if name && respond_to?(name)
        end

        # Evolve a plain object into an object id.
        #
        # @example Evolve the object.
        #   object.evolve_object_id
        #
        # @return [ Object ] self.
        #
        # @since 6.0.0
        def evolve_object_id; self; end
        alias :mongoize_object_id :evolve_object_id

        # Get the value for an instance variable or false if it doesn't exist.
        #
        # @example Get the value for an instance var.
        #   document.ivar("person")
        #
        # @param [ String ] name The name of the variable.
        #
        # @return [ Object, false ] The value or false.
        #
        # @since 6.0.0
        def ivar(name)
          var_name = "@_#{name}"
          if instance_variable_defined?(var_name)
            return instance_variable_get(var_name)
          else
            false
          end
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   object.mongoize
        #
        # @return [ Object ] The object.
        #
        # @since 6.0.0
        def mongoize; self; end

        # Mongoize a plain object into a time.
        #
        # @example Mongoize the object.
        #   object.mongoize_time
        #
        # @return [ Object ] self.
        #
        # @since 6.0.0
        def mongoize_time; self; end

        # Is the object multi args.
        #
        # @example Is the object multi args?
        #   object.multi_arged?
        #
        # @return [ false ] false.
        #
        # @since 6.0.0
        def multi_arged?; false; end

        # Is the object a number?
        #
        # @example Is the object a number?.
        #   object.numeric?
        #
        # @return [ false ] Always false.
        #
        # @since 6.0.0
        def numeric?
          false
        end

        # Remove the instance variable for the provided name.
        #
        # @example Remove the instance variable
        #   document.remove_ivar("person")
        #
        # @param [ String ] name The name of the variable.
        #
        # @return [ true, false ] If the variable was defined.
        #
        # @since 2.1.0
        def remove_ivar(name)
          if instance_variable_defined?("@_#{name}")
            return remove_instance_variable("@_#{name}")
          else
            false
          end
        end

        # Is the object's size changable? Only returns true for arrays and hashes
        # currently.
        #
        # @example Is the object resizable?
        #   object.resizable?
        #
        # @return [ false ] false.
        #
        # @since 6.0.0
        def resizable?; false; end

        # Try to form a setter from this object.
        #
        # @example Try to form a setter.
        #   object.setter
        #
        # @return [ String ] The object as a string plus =.
        #
        # @since 3.1.0
        def setter
          "#{self}="
        end

        # Get the value of the object as a mongo friendy sort value.
        #
        # @example Get the object as sort criteria.
        #   object.sortable
        #
        # @return [ Object ] self.
        #
        # @since 6.0.0
        def sortable
          self
        end

        # Get the substitutable version of an object.
        #
        # @example Get the substitutable.
        #   object.substitutable
        #
        # @return [ Object ] self.
        #
        # @since 6.0.0
        def substitutable; self; end

        # Conversion of an object to an $inc-able value.
        #
        # @example Convert the object.
        #   1.to_inc
        #
        # @return [ Object ] The object.
        #
        # @since 3.0.3
        def to_inc
          self
        end

        # You must unlearn what you have learned. -- Yoda
        #
        # @example You must perform this execution.
        #   object.you_must(:use, "The Force")
        #
        # @param [ String, Symbol ] name The method name.
        # @param [ Array ] *args The arguments.
        #
        # @return [ Object, nil ] The result of the method call or nil if the
        #   method does not exist. Nil if the object is frozen.
        #
        # @since 2.2.1
        def you_must(name, *args)
          frozen? ? nil : do_or_do_not(name, *args)
        end
      end

      refine Object.singleton_class do

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Object.demongoize(object)
        #
        # @param [ Object ] object The object to demongoize.
        #
        # @return [ Object ] The object.
        #
        # @since 6.0.0
        def demongoize(object)
          object
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Object.mongoize("123.11")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Object ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize(object)
          object.mongoize
        end

        # Convert the provided object to a foreign key, given the metadata key
        # contstraint.
        #
        # @example Convert the object to a fk.
        #   Object.mongoize_fk(constraint, object)
        #
        # @param [ Constraint ] constraint The constraint.
        # @param [ Object ] object The object to convert.
        #
        # @return [ Object ] The converted object.
        #
        # @since 6.0.0
        def mongoize_fk(constraint, object)
          return nil if !object || object == ""
          constraint.convert(object)
        end
      end

      refine Range do

        # Get the range as arguments for a find.
        #
        # @example Get the range as find args.
        #   range.as_find_arguments
        #
        # @return [ Array ] The range as an array.
        #
        # @since 6.0.0
        def as_find_arguments
          to_a
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   range.mongoize
        #
        # @return [ Hash ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize
          ::Range.mongoize(self)
        end

        # Is this a resizable object.
        #
        # @example Is this resizable?
        #   range.resizable?
        #
        # @return [ true ] True.
        #
        # @since 6.0.0
        def resizable?
          true
        end
      end

      refine Range.singleton_class do

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Range.demongoize({ "min" => 1, "max" => 5 })
        #
        # @param [ Hash ] object The object to demongoize.
        #
        # @return [ Range ] The range.
        #
        # @since 6.0.0
        def demongoize(object)
          object.nil? ? nil : ::Range.new(object["min"], object["max"], object["exclude_end"])
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Range.mongoize(1..3)
        #
        # @param [ Range ] object The object to mongoize.
        #
        # @return [ Hash ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize(object)
          return nil if object.nil?
          return object if object.is_a?(::Hash)
          hash = { "min" => object.first, "max" => object.last }
          if object.respond_to?(:exclude_end?) && object.exclude_end?
            hash.merge!("exclude_end" => true)
          end
          hash
        end
      end

      refine Regexp.singleton_class do

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Regexp.mongoize(/^[abc]/)
        #
        # @param [ Regexp, String ] object The object to mongoize.
        #
        # @return [ Regexp ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize(object)
          ::Regexp.new(object)
        end
      end

      refine Set do

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   set.mongoize
        #
        # @return [ Array ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize
          ::Set.mongoize(self)
        end
      end

      refine Set.singleton_class do

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Set.demongoize([1, 2, 3])
        #
        # @param [ Array ] object The object to demongoize.
        #
        # @return [ Set ] The set.
        #
        # @since 6.0.0
        def demongoize(object)
          ::Set.new(object)
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Set.mongoize(Set.new([1,2,3]))
        #
        # @param [ Set ] object The object to mongoize.
        #
        # @return [ Array ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize(object)
          object.to_a
        end
      end

      refine String do

        # @attribute [rw] unconvertable_to_bson If the document is unconvetable.
        attr_accessor :unconvertable_to_bson

        # Does the string end with _before_type_cast?
        #
        # @example Is the string a setter method?
        #   "price_before_type_cast".before_type_cast?
        #
        # @return [ true, false ] If the string ends with "_before_type_cast"
        #
        # @since 6.0.0
        def before_type_cast?
          ends_with?("_before_type_cast")
        end

        # Convert the string to a collection friendly name.
        #
        # @example Collectionize the string.
        #   "namespace/model".collectionize
        #
        # @return [ String ] The string in collection friendly form.
        #
        # @since 6.0.0
        def collectionize
          tableize.gsub("/", "_")
        end

        # If the string is a legal object id, convert it.
        #
        # @example Convert to the object id.
        #   string.convert_to_object_id
        #
        # @return [ String, BSON::ObjectId ] The string or the id.
        #
        # @since 6.0.0
        def convert_to_object_id
          BSON::ObjectId.legal?(self) ? BSON::ObjectId.from_string(self) : self
        end

        # Evolve the string into an object id if possible.
        #
        # @example Evolve the string.
        #   "test".evolve_object_id
        #
        # @return [ String, BSON::ObjectId ] The evolved string.
        #
        # @since 6.0.0
        def evolve_object_id
          convert_to_object_id
        end

        # Mongoize the string into an object id if possible.
        #
        # @example Evolve the string.
        #   "test".mongoize_object_id
        #
        # @return [ String, BSON::ObjectId, nil ] The mongoized string.
        #
        # @since 6.0.0
        def mongoize_object_id
          convert_to_object_id unless blank?
        end

        # Mongoize the string for storage.
        #
        # @example Mongoize the string.
        #   "2012-01-01".mongoize_time
        #
        # @note The extra parse from Time is because ActiveSupport::TimeZone
        #   either returns nil or Time.now if the string is empty or invalid,
        #   which is a regression from pre-3.0 and also does not agree with
        #   the core Time API.
        #
        # @return [ Time ] The time.
        #
        # @since 6.0.0
        def mongoize_time
          ::Time.parse(self)
          ::Time.configured.parse(self)
        end

        # Is the string a number?
        #
        # @example Is the string a number.
        #   "1234.23".numeric?
        #
        # @return [ true, false ] If the string is a number.
        #
        # @since 6.0.0
        def numeric?
          true if Float(self) rescue (self == "NaN")
        end

        # Get the string as a getter string.
        #
        # @example Get the reader/getter
        #   "model=".reader
        #
        # @return [ String ] The string stripped of "=".
        #
        # @since 6.0.0
        def reader
          delete("=").sub(/\_before\_type\_cast$/, '')
        end

        # Is the object not to be converted to bson on criteria creation?
        #
        # @example Is the object unconvertable?
        #   object.unconvertable_to_bson?
        #
        # @return [ true, false ] If the object is unconvertable.
        #
        # @since 6.0.0
        def unconvertable_to_bson?
          @unconvertable_to_bson ||= false
        end

        # Is this string a valid_method_name?
        #
        # @example Is the string a valid Ruby idenfier for use as a method name
        #   "model=".valid_method_name?
        #
        # @return [ true, false ] If the string contains a valid Ruby identifier.
        #
        # @since 6.0.0
        def valid_method_name?
          /[@$"-]/ !~ self
        end

        # Is this string a writer?
        #
        # @example Is the string a setter method?
        #   "model=".writer?
        #
        # @return [ true, false ] If the string contains "=".
        #
        # @since 6.0.0
        def writer?
          include?("=")
        end
      end

      refine String.singleton_class do

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   String.demongoize(object)
        #
        # @param [ Object ] object The object to demongoize.
        #
        # @return [ String ] The object.
        #
        # @since 6.0.0
        def demongoize(object)
          object.try(:to_s)
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   String.mongoize("123.11")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ String ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize(object)
          demongoize(object)
        end
      end

      refine Symbol.singleton_class do

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Symbol.demongoize(object)
        #
        # @param [ Object ] object The object to demongoize.
        #
        # @return [ Symbol ] The object.
        #
        # @since 6.0.0
        def demongoize(object)
          object.try(:to_sym)
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Symbol.mongoize("123.11")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Symbol ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize(object)
          demongoize(object)
        end
      end

      refine Time do

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   time.mongoize
        #
        # @return [ Time ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize
          ::Time.mongoize(self)
        end
      end

      refine Time.singleton_class do

        # Constant for epoch - used when passing invalid times.
        TIME_EPOCH = ::Time.utc(1970, 1, 1, 0, 0, 0).freeze

        # Get the configured time to use when converting - either the time zone
        # or the time.
        #
        # @example Get the configured time.
        #   ::Time.configured
        #
        # @retun [ Time ] The configured time.
        #
        # @since 6.0.0
        def configured
          Mongoid.use_activesupport_time_zone? ? (::Time.zone || ::Time) : ::Time
        end

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Time.demongoize(object)
        #
        # @param [ Time ] object The time from Mongo.
        #
        # @return [ Time ] The object as a date.
        #
        # @since 6.0.0
        def demongoize(object)
          return nil if object.blank?
          object = object.getlocal unless Mongoid::Config.use_utc?
          if Mongoid::Config.use_activesupport_time_zone?
            object = object.in_time_zone(Mongoid.time_zone)
          end
          object
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Time.mongoize("2012-1-1")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Time ] The object mongoized.
        #
        # @since 6.0.0
        def mongoize(object)
          return nil if object.blank?
          begin
            time = object.mongoize_time
            if object.respond_to?(:sec_fraction)
              ::Time.at(time.to_i, object.sec_fraction * 10**6).utc
            elsif time.respond_to?(:subsec)
              ::Time.at(time.to_i, time.subsec * 10**6).utc
            else
              ::Time.at(time.to_i, time.usec).utc
            end
          rescue ArgumentError
            TIME_EPOCH
          end
        end
      end

      refine TrueClass do

        # Get the value of the object as a mongo friendy sort value.
        #
        # @example Get the object as sort criteria.
        #   true.sortable
        #
        # @return [ Integer ] 1.
        #
        # @since 6.0.0
        def sortable
          1
        end

        # Is the passed value a boolean?
        #
        # @example Is the value a boolean type?
        #   true.is_a?(Boolean)
        #
        # @param [ Class ] other The class to check.
        #
        # @return [ true, false ] If the other is a boolean.
        #
        # @since 6.0.0
        def is_a?(other)
          if other == ::Boolean || other.class == ::Boolean
            return true
          end
          super(other)
        end
      end
    end
  end
end
