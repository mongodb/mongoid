require "spec_helper"

describe Mongoid::Fields do

  before(:all) do
    Mongoid.use_activesupport_time_zone = false
  end

  describe "#\{field}_translations" do

    let(:product) do
      Product.new
    end

    context "when the field is localized" do

      context "when translations exist" do

        before do
          product.description = "test"
          ::I18n.locale = :de
          product.description = "The best"
        end

        after do
          ::I18n.locale = :en
        end

        let(:translations) do
          product.description_translations
        end

        it "returns all the translations" do
          translations.should eq(
            { "en" => "test", "de" => "The best" }
          )
        end
      end

      context "when translations do not exist" do

        context "when no default is provided" do

          it "returns an empty hash" do
            product.description_translations.should be_empty
          end
        end

        context "when a default is provided" do

          it "returns the translations with the default" do
            product.name_translations.should eq(
              { "en" => "no translation" }
            )
          end
        end
      end
    end

    context "when the field is not localized" do

      it "does not respond to the method" do
        product.should_not respond_to(:price_translations)
      end
    end
  end

  describe "#\{field}_translations=" do

    let(:product) do
      Product.new
    end

    let(:dictionary) do
      Dictionary.new
    end

    context "when the field is localized" do

      context "when the field does not require mongoizations" do

        let(:translations) do
          { "en" => "test", "de" => "testing" }
        end

        before do
          product.description_translations = translations
        end

        it "sets the raw values of the translations" do
          product.description_translations.should eq(translations)
        end

        context "when saving the new translations" do

          before do
            product.save
          end

          it "persists the changes" do
            product.reload.description_translations.should eq(translations)
          end

          context "when updating the translations" do

            before do
              product.description_translations = { "en" => "overwritten" }
              product.save
            end

            it "persists the changes" do
              product.reload.description_translations.should eq(
                { "en" => "overwritten" }
              )
            end
          end
        end
      end

      context "when the field requires mongoization" do

        let(:translations) do
          { "en" => 1, "de" => 2 }
        end

        before do
          dictionary.description_translations = translations
        end

        it "sets the mongoized values of the translations" do
          dictionary.description_translations.should eq(
            { "en" => "1", "de" => "2" }
          )
        end

        context "when saving the new translations" do

          before do
            dictionary.save
          end

          it "persists the changes" do
            dictionary.reload.description_translations.should eq(
              { "en" => "1", "de" => "2" }
            )
          end

          context "when updating the translations" do

            before do
              dictionary.description_translations = { "en" => "overwritten" }
              dictionary.save
            end

            it "persists the changes" do
              dictionary.reload.description_translations.should eq(
                { "en" => "overwritten" }
              )
            end
          end
        end
      end
    end

    context "when the field is not localized" do

      it "does not respond to the method" do
        product.should_not respond_to(:price_translations=)
      end
    end
  end

  describe "#attribute_names" do

    context "when the document is a parent class" do

      let(:shape) do
        Shape.new
      end

      it "includes the _id field" do
        shape.attribute_names.should include("_id")
      end

      it "includes the _type field" do
        shape.attribute_names.should include("_type")
      end

      it "includes its own fields" do
        shape.attribute_names.should include("x")
      end

      it "does not return subclass fields" do
        shape.attribute_names.should_not include("radius")
      end
    end

    context "when the document is a subclass" do

      let(:circle) do
        Circle.new
      end

      it "includes the _id field" do
        circle.attribute_names.should include("_id")
      end

      it "includes the _type field" do
        circle.attribute_names.should include("_type")
      end

      it "includes the first parent field" do
        circle.attribute_names.should include("x")
      end

      it "includes the second parent field" do
        circle.attribute_names.should include("y")
      end

      it "includes the child fields" do
        circle.attribute_names.should include("radius")
      end
    end
  end

  describe ".attribute_names" do

    context "when the class is a parent" do

      it "includes the _id field" do
        Shape.attribute_names.should include("_id")
      end

      it "includes the _type field" do
        Shape.attribute_names.should include("_type")
      end

      it "includes its own fields" do
        Shape.attribute_names.should include("x")
      end

      it "does not return subclass fields" do
        Shape.attribute_names.should_not include("radius")
      end
    end

    context "when the class is a subclass" do

      it "includes the _id field" do
        Circle.attribute_names.should include("_id")
      end

      it "includes the _type field" do
        Circle.attribute_names.should include("_type")
      end

      it "includes the first parent field" do
        Circle.attribute_names.should include("x")
      end

      it "includes the second parent field" do
        Circle.attribute_names.should include("y")
      end

      it "includes the child fields" do
        Circle.attribute_names.should include("radius")
      end
    end
  end

  describe "#field" do

    before(:all) do
      Mongoid::Fields.option :custom do |model, field, value|
      end
    end

    context "when the options are valid" do

      context "when the options are all standard" do

        before do
          Band.field :acceptable, type: Boolean
        end

        after do
          Band.fields.delete("acceptable")
        end

        it "adds the field to the model" do
          Band.fields["acceptable"].should_not be_nil
        end
      end

      context "when a custom option is provided" do

        before do
          Band.field :acceptable, type: Boolean, custom: true
        end

        it "adds the field to the model" do
          Band.fields["acceptable"].should_not be_nil
        end
      end
    end

    context "when the options are not valid" do

      it "raises an error" do
        expect {
          Band.field :unacceptable, bad: true
        }.to raise_error(Mongoid::Errors::InvalidFieldOption)
      end
    end
  end

  describe "#getter" do

    context "when the field is binary" do

      let(:binary) do
        Moped::BSON::Binary.new(:md5, "testing")
      end

      let(:registry) do
        Registry.new(data: binary)
      end

      it "returns the binary data intact" do
        registry.data.should eq(binary)
      end
    end

    context "when a field is localized" do

      let(:product) do
        Product.new
      end

      context "when no locale is set" do

        before do
          product.description = "The best"
        end

        let(:description) do
          product.description
        end

        it "returns the default locale value" do
          description.should eq("The best")
        end
      end

      context "when a single locale is set" do

        before do
          ::I18n.locale = :de
          product.description = "The best"
        end

        after do
          ::I18n.locale = :en
        end

        let(:description) do
          product.description
        end

        it "returns the set locale value" do
          description.should eq("The best")
        end
      end

      context "when multiple locales are set" do

        before do
          product.description = "Cheap drinks"
          ::I18n.locale = :de
          product.description = "Cheaper drinks"
        end

        after do
          ::I18n.locale = :en
        end

        let(:description) do
          product.description
        end

        it "returns the current locale value" do
          description.should eq("Cheaper drinks")
        end
      end
    end
  end

  describe "#getter_before_type_cast" do
    let(:person) do
      Person.new
    end

    context "when the attribute has not been assigned" do

      it "delgates to the getter" do
        person.age_before_type_cast.should eq(person.age)
      end
    end

    context "when the attribute has been assigned" do

      it "returns the attribute before type cast" do
        person.age = "old"
        person.age_before_type_cast.should eq("old")
      end
    end
  end

  describe "#setter=" do

    let(:product) do
      Product.new
    end

    context "when the field is binary" do

      let(:binary) do
        Moped::BSON::Binary.new(:md5, "testing")
      end

      let(:registry) do
        Registry.new
      end

      before do
        registry.data = binary
      end

      it "returns the binary data intact" do
        registry.data.should eq(binary)
      end
    end

    context "when the field is an array" do

      before do
        product.stores = [ "kadewe", "karstadt" ]
        product.save
      end

      context "when setting the value to nil" do

        before do
          product.stores = nil
          product.save
        end

        it "allows the set" do
          product.stores.should be_nil
        end
      end

      context "when setting any of the values to nil" do

        before do
          product.stores = [ "kadewe", nil ]
          product.save
        end

        it "allows the set of nil values" do
          product.stores.should eq([ "kadewe", nil ])
        end

        it "persists the nil values" do
          product.reload.stores.should eq([ "kadewe", nil ])
        end
      end

      context "when reversing the array values" do

        before do
          product.stores = [ "karstadt", "kadewe" ]
          product.save
        end

        it "reverses the values" do
          product.stores.should eq([ "karstadt", "kadewe" ])
        end

        it "persists the changes" do
          product.reload.stores.should eq([ "karstadt", "kadewe" ])
        end
      end
    end

    context "when a field is localized" do

      context "when no locale is set" do

        before do
          product.description = "Cheap drinks"
        end

        let(:description) do
          product.attributes["description"]
        end

        it "sets the value in the default locale" do
          description.should eq({ "en" => "Cheap drinks" })
        end
      end

      context "when a locale is set" do

        before do
          ::I18n.locale = :de
          product.description = "Cheaper drinks"
        end

        after do
          ::I18n.locale = :en
        end

        let(:description) do
          product.attributes["description"]
        end

        it "sets the value in the default locale" do
          description.should eq({ "de" => "Cheaper drinks" })
        end
      end

      context "when having multiple locales" do

        before do
          product.description = "Cheap drinks"
          ::I18n.locale = :de
          product.description = "Cheaper drinks"
        end

        after do
          ::I18n.locale = :en
        end

        let(:description) do
          product.attributes["description"]
        end

        it "sets the value in both locales" do
          description.should eq(
            { "de" => "Cheaper drinks", "en" => "Cheap drinks" }
          )
        end
      end
    end
  end

  describe "#defaults" do

    context "with defaults specified as a non-primitive" do

      let(:person_one) do
        Person.new
      end

      let(:person_two) do
        Person.new
      end

      context "when provided a default array" do

        before do
          Person.field(:array_testing, type: Array, default: [])
        end

        after do
          Person.fields.delete("array_testing")
          Person.pre_processed_defaults.delete_one("array_testing")
        end

        it "returns an equal object of a different instance" do
          person_one.array_testing.object_id.should_not eq(
            person_two.array_testing.object_id
          )
        end
      end

      context "when provided a default hash" do

        before do
          Person.field(:hash_testing, type: Hash, default: {})
        end

        after do
          Person.fields.delete("hash_testing")
        end

        it "returns an equal object of a different instance" do
          person_one.hash_testing.object_id.should_not eq(
            person_two.hash_testing.object_id
          )
        end
      end

      context "when provided a default proc" do

        context "when the proc has no argument" do

          before do
            Person.field(
              :generated_testing,
              type: Float,
              default: ->{ Time.now.to_f }
            )
          end

          after do
            Person.fields.delete("generated_testing")
            Person.pre_processed_defaults.delete_one("generated_testing")
          end

          it "returns an equal object of a different instance" do
            person_one.generated_testing.object_id.should_not eq(
              person_two.generated_testing.object_id
            )
          end
        end

        context "when the proc has to be evaluated on the document" do

          before do
            Person.field(
              :rank,
              type: Integer,
              default: ->{ title? ? 1 : 2 }
            )
          end

          after do
            Person.fields.delete("rank")
            Person.post_processed_defaults.delete_one("rank")
          end

          it "yields the document to the proc" do
            Person.new.rank.should eq(2)
          end
        end
      end
    end

    context "on parent classes" do

      let(:shape) do
        Shape.new
      end

      it "does not return subclass defaults" do
        shape.pre_processed_defaults.should eq([ "_id", "x", "y", "_type" ])
      end
    end

    context "on subclasses" do

      let(:circle) do
        Circle.new
      end

      it "has the parent and child defaults" do
        circle.pre_processed_defaults.should eq([ "_id", "x", "y", "_type", "radius" ])
      end
    end
  end

  describe ".field" do

    it "returns the generated field" do
      Person.field(:testing).should equal Person.fields["testing"]
    end

    context "when the field name conflicts with mongoid's internals" do

      context "when the field is named metadata" do

        it "raises an error" do
          expect {
            Person.field(:metadata)
          }.to raise_error(Mongoid::Errors::InvalidField)
        end
      end
    end

    context "when the field is a time" do

      let!(:time) do
        Time.now
      end

      let!(:person) do
        Person.new(lunch_time: time.utc)
      end

      context "when reading the field" do

        before do
          Time.zone = "Berlin"
        end

        after do
          Time.zone = nil
        end

        it "performs the necessary time conversions" do
          person.lunch_time.to_s.should eq(time.getlocal.to_s)
        end
      end
    end

    context "when providing no options" do

      before do
        Person.field(:testing)
      end

      let(:person) do
        Person.new(testing: "Test")
      end

      it "adds a reader for the fields defined" do
        person.testing.should eq("Test")
      end

      it "adds a writer for the fields defined" do
        (person.testing = "Testy").should eq("Testy")
      end

      it "adds an existance method" do
        Person.new.testing?.should be_false
      end

      context "when overwriting an existing field" do

        before do
          Person.class_eval do
            attr_reader :testing_override_called
            def testing=(value)
              @testing_override_called = true
              super
            end
          end
          person.testing = 'Test'
        end

        it "properly overwrites the method" do
          person.testing_override_called.should be_true
        end
      end
    end

    context "when the type is an object" do

      let(:bob) do
        Person.new(reading: 10.023)
      end

      it "returns the given value" do
        bob.reading.should eq(10.023)
      end
    end

    context "when type is a boolean" do

      let(:person) do
        Person.new(terms: true)
      end

      it "adds an accessor method with a question mark" do
        person.terms?.should be_true
      end
    end

    context "when as is specified" do

      let(:person) do
        Person.new(alias: true)
      end

      before do
        Person.field :aliased, as: :alias, type: Boolean
      end

      it "uses the alias to write the attribute" do
        (person.alias = true).should be_true
      end

      it "uses the alias to read the attribute" do
        person.alias.should be_true
      end

      it "uses the alias for the query method" do
        person.should be_alias
      end

      it "uses the name to write the attribute" do
        (person.aliased = true).should be_true
      end

      it "uses the name to read the attribute" do
        person.aliased.should be_true
      end

      it "uses the name for the query method" do
        person.should be_aliased
      end

      it "creates dirty methods for the name" do
        person.should respond_to(:aliased_changed?)
      end

      it "creates dirty methods for the alias" do
        person.should respond_to(:alias_changed?)
      end

      context "when changing the name" do

        before do
          person.aliased = true
        end

        it "sets name_changed?" do
          person.aliased_changed?.should be_true
        end

        it "sets alias_changed?" do
          person.alias_changed?.should be_true
        end
      end

      context "when changing the alias" do

        before do
          person.alias = true
        end

        it "sets name_changed?" do
          person.aliased_changed?.should be_true
        end

        it "sets alias_changed?" do
          person.alias_changed?.should be_true
        end
      end

      context "when defining a criteria" do

        let(:criteria) do
          Person.where(alias: "true")
        end

        it "properly serializes the aliased field" do
          criteria.selector.should eq({ "aliased" => true })
        end
      end
    end

    context "custom options" do

      let(:handler) do
        proc {}
      end

      before do
        Mongoid::Fields.option :option, &handler
      end

      context "when option is provided" do

        it "calls the handler with the model" do
          handler.should_receive(:call).with do |model,_,_|
            model.should eql User
          end

          User.field :custom, option: true
        end

        it "calls the handler with the field" do
          handler.should_receive(:call).with do |_,field,_|
            field.should eql User.fields["custom"]
          end

          User.field :custom, option: true
        end

        it "calls the handler with the option value" do
          handler.should_receive(:call).with do |_,_,value|
            value.should eql true
          end

          User.field :custom, option: true
        end
      end

      context "when option is nil" do

        it "calls the handler" do
          handler.should_receive(:call)
          User.field :custom, option: nil
        end
      end

      context "when option is not provided" do

        it "does not call the handler" do
          handler.should_receive(:call).never

          User.field :custom
        end
      end
    end
  end

  describe "#fields" do

    context "on parent classes" do

      let(:shape) do
        Shape.new
      end

      it "includes its own fields" do
        shape.fields.keys.should include("x")
      end

      it "does not return subclass fields" do
        shape.fields.keys.should_not include("radius")
      end
    end

    context "on subclasses" do

      let(:circle) do
        Circle.new
      end

      it "includes the first parent field" do
        circle.fields.keys.should include("x")
      end

      it "includes the second parent field" do
        circle.fields.keys.should include("y")
      end

      it "includes the child fields" do
        circle.fields.keys.should include("radius")
      end
    end
  end

  describe ".replace_field" do

    let!(:original) do
      Person.field(:id_test, type: Moped::BSON::ObjectId, label: "id")
    end

    let!(:altered) do
      Person.replace_field("id_test", String)
    end

    after do
      Person.fields.delete("id_test")
    end

    let(:new_field) do
      Person.fields["id_test"]
    end

    it "sets the new type on the field" do
      new_field.type.should eq(String)
    end

    it "keeps the options from the old field" do
      new_field.options[:label].should eq("id")
    end
  end

  context "when sending an include of another module at runtime" do

    before do
      Basic.send(:include, Ownable)
    end

    context "when the class is a parent" do

      let(:fields) do
        Basic.fields
      end

      it "resets the fields" do
        fields.keys.should include("user_id")
      end
    end

    context "when the class is a subclass" do

      let(:fields) do
        SubBasic.fields
      end

      it "resets the fields" do
        fields.keys.should include("user_id")
      end
    end
  end

  context "when a setter accesses a field with a default" do

    let(:person) do
      Person.new(set_on_map_with_default: "testing")
    end

    it "sets the default value pre process" do
      person.map_with_default.should eq({ "key" => "testing" })
    end
  end

  context "when dealing with auto protection" do

    context "when auto protect ids and types is true" do

      context "when redefining as accessible" do

        before do
          Person.attr_accessible :id, :_id, :_type
        end

        after do
          Person.attr_protected :id, :_id, :_type
        end

        let(:bson_id) do
          Moped::BSON::ObjectId.new
        end

        it "allows mass assignment of id" do
          Person.new(_id: bson_id).id.should eq(bson_id)
        end

        it "allows mass assignment of type" do
          Person.new(_type: "Something")._type.should eq("Something")
        end
      end

      context "when redefining as protected" do

        before do
          Person.attr_protected :id, :_id, :_type
        end

        let(:bson_id) do
          Moped::BSON::ObjectId.new
        end

        it "protects assignment of id" do
          Person.new(_id: bson_id).id.should_not eq(bson_id)
        end

        it "protects assignment of type" do
          Person.new(_type: "Something")._type.should_not eq("Something")
        end
      end
    end

    context "when auto protecting ids and types is false" do

      before do
        Mongoid.protect_sensitive_fields = false
      end

      after do
        Mongoid.protect_sensitive_fields = true
      end

      let(:klass) do
        Class.new do
          include Mongoid::Document
        end
      end

      let(:bson_id) do
        Moped::BSON::ObjectId.new
      end

      let(:model) do
        klass.new(id: bson_id, _type: "Model")
      end

      it "allows mass assignment of id" do
        model.id.should eq(bson_id)
      end

      it "allows mass assignment of type" do
        model._type.should eq("Model")
      end
    end
  end

  context "when a field is defined as a big decimal" do

    let(:band) do
      Band.new(name: "Tool")
    end

    let(:decimal) do
      BigDecimal.new("1000000.00")
    end

    context "when setting to a big decimal" do

      before do
        band.sales = decimal
      end

      it "properly persists as a string" do
        band.attributes["sales"].should eq(decimal.to_s)
      end

      it "returns the proper big decimal" do
        band.sales.should eq(decimal)
      end
    end

    context "when setting to a string" do

      before do
        band.sales = decimal.to_s
      end

      it "properly persists as a string" do
        band.attributes["sales"].should eq(decimal.to_s)
      end

      it "returns the proper big decimal" do
        band.sales.should eq(decimal)
      end
    end

    context "when setting to an integer" do

      before do
        band.sales = decimal.to_i
      end

      it "properly persists as a string" do
        band.attributes["sales"].should eq("1000000")
      end

      it "returns the proper big decimal" do
        band.sales.should eq(decimal)
      end
    end

    context "when setting to a float" do

      before do
        band.sales = decimal.to_f
      end

      it "properly persists as a string" do
        band.attributes["sales"].should eq(decimal.to_s)
      end

      it "returns the proper big decimal" do
        band.sales.should eq(decimal)
      end
    end
  end
end
