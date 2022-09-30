# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Fields do
  config_override :use_activesupport_time_zone, false

  describe "#\{field}_translations" do

    let(:product) do
      Product.new
    end

    context "when the field is localized" do

      context "when translations exist" do
        with_default_i18n_configs

        before do
          I18n.locale = :en
          product.description = "test"
          I18n.locale = :de
          product.description = "The best"
        end

        let(:translations) do
          product.description_translations
        end

        it "returns all the translations" do
          expect(translations).to eq(
            { "en" => "test", "de" => "The best" }
          )
        end

        it "returns translations as a HashWithIndifferentAccess" do
          expect(translations[:en]).to eq("test")
        end
      end

      context "when translations do not exist" do

        context "when no default is provided" do

          it "returns an empty hash" do
            expect(product.description_translations).to be_empty
          end
        end

        context "when a default is provided" do

          it "returns the translations with the default" do
            expect(product.name_translations).to eq(
              { "en" => "no translation" }
            )
          end
        end
      end

      it "should have alias method #\{field}_t" do
        expect(product.method(:name_t)).to eq product.method(:name_translations)
      end
    end

    context "when the field is not localized" do

      it "does not respond to the method" do
        expect(product).to_not respond_to(:price_translations)
      end

      it "does not respond to the alias method" do
        expect(product).to_not respond_to(:price_t)
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
          expect(product.description_translations).to eq(translations)
        end

        context "when saving the new translations" do

          before do
            product.save!
          end

          it "persists the changes" do
            expect(product.reload.description_translations).to eq(translations)
          end

          context "when updating the translations" do

            before do
              product.description_translations = { "en" => "overwritten" }
              product.save!
            end

            it "persists the changes" do
              expect(product.reload.description_translations).to eq(
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
          expect(dictionary.description_translations).to eq(
            { "en" => "1", "de" => "2" }
          )
        end

        context "when saving the new translations" do

          before do
            dictionary.save!
          end

          it "persists the changes" do
            expect(dictionary.reload.description_translations).to eq(
              { "en" => "1", "de" => "2" }
            )
          end

          context "when updating the translations" do

            before do
              dictionary.description_translations = { "en" => "overwritten" }
              dictionary.save!
            end

            it "persists the changes" do
              expect(dictionary.reload.description_translations).to eq(
                { "en" => "overwritten" }
              )
            end
          end
        end
      end

      it "should have alias method #\{field}_t=" do
        expect(product.method(:name_t=)).to eq product.method(:name_translations=)
      end
    end

    context "when the field is not localized" do

      it "does not respond to the method" do
        expect(product).to_not respond_to(:price_translations=)
      end

      it "does not respond to the alias method" do
        expect(product).to_not respond_to(:price_t=)
      end
    end
  end

  describe "#aliased_fields" do

    let(:person) do
      Person.new
    end

    context "when the document is subclassed" do

      it "does not include the child aliases" do
        expect(person.aliased_fields.keys).to_not include("spec")
      end
    end
  end

  describe "#attribute_names" do

    context "when the document is a parent class" do

      let(:shape) do
        Shape.new
      end

      it "includes the _id field" do
        expect(shape.attribute_names).to include("_id")
      end

      it "includes the _type field" do
        expect(shape.attribute_names).to include("_type")
      end

      it "includes its own fields" do
        expect(shape.attribute_names).to include("x")
      end

      it "does not return subclass fields" do
        expect(shape.attribute_names).to_not include("radius")
      end
    end

    context "when the document is a subclass" do

      let(:circle) do
        Circle.new
      end

      it "includes the _id field" do
        expect(circle.attribute_names).to include("_id")
      end

      it "includes the _type field" do
        expect(circle.attribute_names).to include("_type")
      end

      it "includes the first parent field" do
        expect(circle.attribute_names).to include("x")
      end

      it "includes the second parent field" do
        expect(circle.attribute_names).to include("y")
      end

      it "includes the child fields" do
        expect(circle.attribute_names).to include("radius")
      end
    end
  end

  describe ".attribute_names" do

    context "when the class is a parent" do

      it "includes the _id field" do
        expect(Shape.attribute_names).to include("_id")
      end

      it "includes the _type field" do
        expect(Shape.attribute_names).to include("_type")
      end

      it "includes its own fields" do
        expect(Shape.attribute_names).to include("x")
      end

      it "does not return subclass fields" do
        expect(Shape.attribute_names).to_not include("radius")
      end
    end

    context "when the class is a subclass" do

      it "includes the _id field" do
        expect(Circle.attribute_names).to include("_id")
      end

      it "includes the _type field" do
        expect(Circle.attribute_names).to include("_type")
      end

      it "includes the first parent field" do
        expect(Circle.attribute_names).to include("x")
      end

      it "includes the second parent field" do
        expect(Circle.attribute_names).to include("y")
      end

      it "includes the child fields" do
        expect(Circle.attribute_names).to include("radius")
      end
    end
  end

  describe "#field" do

    before(:all) do
      Mongoid::Fields.option :custom do |model, field, value|
      end
    end

    context "when providing a root Boolean type" do

      let(:klass) do
        Class.new do
          include Mongoid::Document
        end
      end

      it "converts to Mongoid::Boolean" do
        expect(klass.field(:test, type: Mongoid::Boolean).type).to be(Mongoid::Boolean)
      end
    end

    context "when using symbol types" do

      let(:klass) do
        Class.new do
          include Mongoid::Document
        end
      end

      it "converts :array to Array" do
        expect(klass.field(:test, type: :array).type).to be(Array)
      end

      it "converts :big_decimal to BigDecimal" do
        expect(klass.field(:test, type: :big_decimal).type).to be(BigDecimal)
      end

      it "converts :binary to BSON::Binary" do
        expect(klass.field(:test, type: :binary).type).to be(BSON::Binary)
      end

      it "converts :boolean to Mongoid::Boolean" do
        expect(klass.field(:test, type: :boolean).type).to be(Mongoid::Boolean)
      end

      it "converts :date to Date" do
        expect(klass.field(:test, type: :date).type).to be(Date)
      end

      it "converts :date_time to DateTime" do
        expect(klass.field(:test, type: :date_time).type).to be(DateTime)
      end

      it "converts :float to Float" do
        expect(klass.field(:test, type: :float).type).to be(Float)
      end

      it "converts :hash to Hash" do
        expect(klass.field(:test, type: :hash).type).to be(Hash)
      end

      it "converts :integer to Integer" do
        expect(klass.field(:test, type: :integer).type).to be(Integer)
      end

      it "converts :object_id to BSON::ObjectId" do
        expect(klass.field(:test, type: :object_id).type).to be(BSON::ObjectId)
      end

      it "converts :range to Range" do
        expect(klass.field(:test, type: :range).type).to be(Range)
      end

      it "converts :regexp to Rexegp" do
        expect(klass.field(:test, type: :regexp).type).to be(Regexp)
      end

      it "converts :set to Set" do
        expect(klass.field(:test, type: :set).type).to be(Set)
      end

      it "converts :string to String" do
        expect(klass.field(:test, type: :string).type).to be(String)
      end

      it "converts :symbol to Symbol" do
        expect(klass.field(:test, type: :symbol).type).to be(Symbol)
      end

      it "converts :time to Time" do
        expect(klass.field(:test, type: :time).type).to be(Time)
      end

      context 'when using an unknown symbol' do
        it 'raises InvalidFieldType' do
          lambda do
            klass.field(:test, type:  :bogus)
          end.should raise_error(Mongoid::Errors::InvalidFieldType, /defines a field 'test' with an unknown type value :bogus/)
        end
      end

      context 'when using an unknown string' do
        it 'raises InvalidFieldType' do
          lambda do
            klass.field(:test, type:  'bogus')
          end.should raise_error(Mongoid::Errors::InvalidFieldType, /defines a field 'test' with an unknown type value "bogus"/)
        end
      end
    end

    context "when the options are valid" do

      context "when the options are all standard" do

        before do
          Band.field :acceptable, type: Mongoid::Boolean
        end

        after do
          Band.fields.delete("acceptable")
        end

        it "adds the field to the model" do
          expect(Band.fields["acceptable"]).to_not be_nil
        end
      end

      context "when a custom option is provided" do

        before do
          Band.field :acceptable, type: Mongoid::Boolean, custom: true
        end

        it "adds the field to the model" do
          expect(Band.fields["acceptable"]).to_not be_nil
        end
      end
    end

    context "when the Symbol type is used" do

      before do
        Mongoid::Warnings.class_eval do
          @symbol_type_deprecated = false
        end
      end

      after do
        Label.fields.delete("should_warn")
      end

      it "warns that the BSON symbol type is deprecated" do
        expect(Mongoid.logger).to receive(:warn)

        Label.field :should_warn, type: Symbol
      end

      it "warns on first use of Symbol type only" do
        expect(Mongoid.logger).to receive(:warn).once

        Label.field :should_warn, type: Symbol
      end

      context 'when using Symbol field type in multiple classes' do
        after do
          Truck.fields.delete("should_warn")
        end

        it "warns on first use of Symbol type only" do
          expect(Mongoid.logger).to receive(:warn).once

          Label.field :should_warn, type: Symbol
          Truck.field :should_warn, type: Symbol
        end
      end
    end

    context "when the options are not valid" do

      it "raises an error" do
        expect {
          Label.field :unacceptable, bad: true
        }.to raise_error(Mongoid::Errors::InvalidFieldOption)
      end
    end
  end

  describe "#getter" do

    context "when the field is binary" do

      let(:binary) do
        BSON::Binary.new("testing", :md5)
      end

      let(:registry) do
        Registry.new(data: binary)
      end

      it "returns the binary data intact" do
        expect(registry.data).to eq(binary)
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
          expect(description).to eq("The best")
        end
      end

      context "when a single locale is set" do
        with_default_i18n_configs

        before do
          I18n.locale = :de
          product.description = "The best"
        end

        let(:description) do
          product.description
        end

        it "returns the set locale value" do
          expect(description).to eq("The best")
        end
      end

      context "when multiple locales are set" do
        with_default_i18n_configs

        before do
          I18n.locale = :end
          product.description = "Cheap drinks"
          I18n.locale = :de
          product.description = "Cheaper drinks"
        end

        let(:description) do
          product.description
        end

        it "returns the current locale value" do
          expect(description).to eq("Cheaper drinks")
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
        expect(person.age_before_type_cast).to eq(person.age)
      end
    end

    context "when the attribute has been assigned" do

      it "returns the attribute before type cast" do
        person.age = "42"
        expect(person.age_before_type_cast).to eq("42")
      end
    end

    context "when reloading" do

      let(:product) do
        Product.create!(price: '1')
      end

      before do
        product.reload
      end

      it "resets the attributes_before_type_cast to the attributes hash" do
        expect(product.attributes_before_type_cast).to eq(product.attributes)
      end

      it "the *_before_type_cast method returns the demongoized value" do
        expect(product.price_before_type_cast).to eq(1)
      end
    end

    context "when reloading and writing a demongoizable value" do

      let(:product) do
        Product.create!.tap do |product|
          Product.collection.update_one({ _id: product.id }, { :$set => { price: '1' }})
        end
      end

      before do
        product.reload
      end

      it "resets the attributes_before_type_cast to the attributes hash" do
        expect(product.attributes_before_type_cast).to eq(product.attributes)
      end

      it "the *_before_type_cast method returns the mongoized value" do
        expect(product.price_before_type_cast).to eq('1')
      end
    end

    context "when reading from the db" do

      let(:product) do
        Product.create!(price: '1')
      end

      let(:from_db) do
        Product.find(product.id)
      end

      it "resets the attributes_before_type_cast to the attributes hash" do
        expect(from_db.attributes_before_type_cast).to eq(from_db.attributes)
      end

      it "the *_before_type_cast method returns the demongoized value" do
        expect(from_db.price_before_type_cast).to eq(1)
      end
    end

    context "when reading from the db after writing a demongoizable value" do

      let(:product) do
        Product.create!.tap do |product|
          Product.collection.update_one({ _id: product.id }, { :$set => { price: '1' }})
        end
      end

      let(:from_db) do
        Product.find(product.id)
      end

      it "resets the attributes_before_type_cast to the attributes hash" do
        expect(from_db.attributes_before_type_cast).to eq(from_db.attributes)
      end

      it "the *_before_type_cast method returns the mongoized value" do
        expect(from_db.price_before_type_cast).to eq('1')
      end
    end

    context "when making a new model" do

      context "when using new with no options" do
        let(:product) { Product.new }

        it "sets the attributes_before_type_cast to the attributes hash" do
          expect(product.attributes_before_type_cast).to eq(product.attributes)
        end
      end

      context "when using new with options" do
        let(:product) { Product.new(price: '1') }

        let(:abtc) do
          product.attributes.merge('price' => '1')
        end

        it "has the attributes before type cast" do
          expect(product.attributes_before_type_cast).to eq(abtc)
        end
      end

      context "when persisting the model" do
        let(:product) { Product.new(price: '1') }

        let(:abtc) do
          product.attributes.merge('price' => '1')
        end

        before do
          expect(product.attributes_before_type_cast).to eq(abtc)
          product.save!
        end

        it "resets the attributes_before_type_cast to the attributes" do
          expect(product.attributes_before_type_cast).to eq(product.attributes)
        end
      end

      context "when using create! without options" do
        let(:product) { Product.create! }

        it "resets the attributes_before_type_cast to the attributes" do
          expect(product.attributes_before_type_cast).to eq(product.attributes)
        end
      end

      context "when using create! with options" do
        let(:product) { Product.create!(price: '1') }

        it "resets the attributes_before_type_cast to the attributes" do
          expect(product.attributes_before_type_cast).to eq(product.attributes)
        end
      end
    end
  end

  describe "#setter=" do

    let(:product) do
      Product.new
    end

    context "when setting via the setter" do

      it "returns the set value" do
        expect(product.price = 10).to eq(10)
      end
    end

    context "when setting via send" do

      it "returns the set value" do
        expect(product.send(:price=, 10)).to eq(10)
      end
    end

    context "when the field is binary" do

      let(:binary) do
        BSON::Binary.new("testing", :md5)
      end

      let(:registry) do
        Registry.new
      end

      before do
        registry.data = binary
      end

      it "returns the binary data intact" do
        expect(registry.data).to eq(binary)
      end
    end

    context "when the field is an array" do

      before do
        product.stores = [ "kadewe", "karstadt" ]
        product.save!
      end

      context "when setting the value to nil" do

        before do
          product.stores = nil
          product.save!
        end

        it "allows the set" do
          expect(product.stores).to be_nil
        end
      end

      context "when setting any of the values to nil" do

        before do
          product.stores = [ "kadewe", nil ]
          product.save!
        end

        it "allows the set of nil values" do
          expect(product.stores).to eq([ "kadewe", nil ])
        end

        it "persists the nil values" do
          expect(product.reload.stores).to eq([ "kadewe", nil ])
        end
      end

      context "when reversing the array values" do

        before do
          product.stores = [ "karstadt", "kadewe" ]
          product.save!
        end

        it "reverses the values" do
          expect(product.stores).to eq([ "karstadt", "kadewe" ])
        end

        it "persists the changes" do
          expect(product.reload.stores).to eq([ "karstadt", "kadewe" ])
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
          expect(description).to eq({ "en" => "Cheap drinks" })
        end
      end

      context "when a locale is set" do
        with_default_i18n_configs

        before do
          I18n.locale = :de
          product.description = "Cheaper drinks"
        end

        let(:description) do
          product.attributes["description"]
        end

        it "sets the value in the default locale" do
          expect(description).to eq({ "de" => "Cheaper drinks" })
        end
      end

      context "when having multiple locales" do
        with_default_i18n_configs

        before do
          I18n.locale = :en
          product.description = "Cheap drinks"
          I18n.locale = :de
          product.description = "Cheaper drinks"
        end

        let(:description) do
          product.attributes["description"]
        end

        it "sets the value in both locales" do
          expect(description).to eq(
            { "de" => "Cheaper drinks", "en" => "Cheap drinks" }
          )
        end
      end
    end

    context "when the field needs to be mongoized" do

      before do
        product.price = "1"
        product.save!
      end

      it "mongoizes the value" do
        expect(product.price).to eq(1)
      end

      it "stores the value in the mongoized form" do
        expect(product.attributes_before_type_cast["price"]).to eq(1)
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
          Person.field(:array_testing, type: Array, default: [], overwrite: true)
        end

        after do
          Person.fields.delete("array_testing")
          Person.pre_processed_defaults.delete_one("array_testing")
        end

        it "returns an equal object of a different instance" do
          expect(person_one.array_testing.object_id).to_not eq(
            person_two.array_testing.object_id
          )
        end
      end

      context "when provided a default hash" do

        before do
          Person.field(:hash_testing, type: Hash, default: {}, overwrite: true)
        end

        after do
          Person.fields.delete("hash_testing")
        end

        it "returns an equal object of a different instance" do
          expect(person_one.hash_testing.object_id).to_not eq(
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
              default: ->{ Time.now.to_f },
              overwrite: true
            )
          end

          after do
            Person.fields.delete("generated_testing")
            Person.pre_processed_defaults.delete_one("generated_testing")
          end

          it "returns an equal object of a different instance" do
            expect(person_one.generated_testing.object_id).to_not eq(
              person_two.generated_testing.object_id
            )
          end
        end

        context "when the proc has to be evaluated on the document" do

          before do
            Person.field(
              :rank,
              type: Integer,
              default: ->{ title? ? 1 : 2 },
              overwrite: true
            )
          end

          after do
            Person.fields.delete("rank")
            Person.post_processed_defaults.delete_one("rank")
          end

          it "yields the document to the proc" do
            expect(Person.new.rank).to eq(2)
          end
        end
      end
    end

    context "on parent classes" do

      let(:shape) do
        Shape.new
      end

      it "does not return subclass defaults" do
        expect(shape.pre_processed_defaults).to eq([ "_id", "x", "y" ])
        expect(shape.post_processed_defaults).to eq([ "_type" ])
      end
    end

    context "on subclasses" do

      let(:circle) do
        Circle.new
      end

      it "has the parent and child defaults" do
        expect(circle.pre_processed_defaults).to eq([ "_id", "x", "y", "radius" ])
        expect(circle.post_processed_defaults).to eq([ "_type" ])
      end
    end
  end

  describe ".field" do

    it "returns the generated field" do
      expect(Person.field(:testing)).to eq(Person.fields["testing"])
    end

    context "when the field name conflicts with mongoid's internals" do

      [:_association, :invalid].each do |meth|
        context "when the field is named #{meth}" do

          it "raises an error" do
            expect {
              Person.field(meth)
            }.to raise_error(Mongoid::Errors::InvalidField, /Defining a field named '#{meth}' is not allowed/)
          end
        end
      end
    end

    context "when field already exist and validate_duplicate is enable" do
      context 'when exception is enabled' do
        config_override :duplicate_fields_exception, true

        it "raises an error" do
          expect {
            Person.field(:title)
          }.to raise_error(Mongoid::Errors::InvalidField)
        end
      end

      context 'when exception is disabled' do
        config_override :duplicate_fields_exception, false
        it "doesn't raise an error" do
          expect {
            Class.new(Person)
          }.to_not raise_error
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
        time_zone_override "Berlin"

        it "performs the necessary time conversions" do
          expect(person.lunch_time.to_s).to eq(time.getlocal.to_s)
        end
      end
    end

    context "when providing no options" do

      before do
        Person.field(:testing, overwrite: true)
      end

      let(:person) do
        Person.new(testing: "Test")
      end

      it "adds a reader for the fields defined" do
        expect(person.testing).to eq("Test")
      end

      it "adds a writer for the fields defined" do
        (person.testing = expect("Testy")).to eq("Testy")
      end

      it "adds an existence method" do
        expect(Person.new.testing?).to be false
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
          expect(person.testing_override_called).to be true
        end
      end
    end

    context "when the type is an object" do

      let(:bob) do
        Person.new(reading: 10.023)
      end

      it "returns the given value" do
        expect(bob.reading).to eq(10.023)
      end
    end

    context "when type is a boolean" do

      let(:person) do
        Person.new(terms: true)
      end

      it "adds an accessor method with a question mark" do
        expect(person.terms?).to be true
      end
    end

    context "when as is specified" do

      let(:person) do
        Person.new(alias: true)
      end

      before do
        Person.field :aliased, as: :alias, type: Mongoid::Boolean, overwrite: true
      end

      it "uses the alias to write the attribute" do
        expect(person.alias = true).to be true
      end

      it "uses the alias to read the attribute" do
        expect(person.alias).to be true
      end

      it "uses the alias for the query method" do
        expect(person).to be_alias
      end

      it "uses the name to write the attribute" do
        expect(person.aliased = true).to be true
      end

      it "uses the name to read the attribute" do
        expect(person.aliased).to be true
      end

      it "uses the name for the query method" do
        expect(person).to be_aliased
      end

      it "creates dirty methods for the name" do
        expect(person).to respond_to(:aliased_changed?)
      end

      it "creates dirty methods for the alias" do
        expect(person).to respond_to(:alias_changed?)
      end

      context "when changing the name" do

        before do
          person.aliased = true
        end

        it "sets name_changed?" do
          expect(person.aliased_changed?).to be true
        end

        it "sets alias_changed?" do
          expect(person.alias_changed?).to be true
        end
      end

      context "when changing the alias" do

        before do
          person.alias = true
        end

        it "sets name_changed?" do
          expect(person.aliased_changed?).to be true
        end

        it "sets alias_changed?" do
          expect(person.alias_changed?).to be true
        end
      end

      context "when defining a criteria" do

        let(:criteria) do
          Person.where(alias: "true")
        end

        it "properly serializes the aliased field" do
          expect(criteria.selector).to eq({ "aliased" => true })
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
          User.field :custom, option: true, overwrite: true
          expect(User.fields["custom"].options[:option]).to be_truthy
        end
      end

      context "when option is nil" do

        it "calls the handler" do
          expect(handler).to receive(:call)
          User.field :custom, option: nil, overwrite: true
        end
      end

      context "when option is not provided" do

        it "does not call the handler" do
          expect(handler).to receive(:call).never
          User.field :custom, overwrite: true
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
        expect(shape.fields.keys).to include("x")
      end

      it "does not return subclass fields" do
        expect(shape.fields.keys).to_not include("radius")
      end

      it 'includes _type field' do
        expect(shape.fields.keys).to include("_type")
      end
    end

    context "on subclasses" do

      let(:circle) do
        Circle.new
      end

      it "includes the first parent field" do
        expect(circle.fields.keys).to include("x")
      end

      it "includes the second parent field" do
        expect(circle.fields.keys).to include("y")
      end

      it "includes the child fields" do
        expect(circle.fields.keys).to include("radius")
      end

      it 'includes _type field' do
        expect(circle.fields.keys).to include("_type")
      end
    end

    context "on new subclasses" do
      it "all subclasses get the discriminator key" do
        class DiscriminatorParent
          include Mongoid::Document
        end

        class DiscriminatorChild1 < DiscriminatorParent
        end

        class DiscriminatorChild2 < DiscriminatorParent
        end

        expect(DiscriminatorParent.fields.keys).to include("_type")
        expect(DiscriminatorChild1.fields.keys).to include("_type")
        expect(DiscriminatorChild2.fields.keys).to include("_type")
      end
    end
  end

  describe ".replace_field" do

    let!(:original) do
      Person.field(:id_test, type: BSON::ObjectId, label: "id")
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
      expect(new_field.type).to eq(String)
    end

    it "keeps the options from the old field" do
      expect(new_field.options[:label]).to eq("id")
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
        expect(fields.keys).to include("user_id")
      end
    end

    context "when the class is a subclass" do

      let(:fields) do
        SubBasic.fields
      end

      it "resets the fields" do
        expect(fields.keys).to include("user_id")
      end
    end
  end

  context "when a setter accesses a field with a default" do

    let(:person) do
      Person.new(set_on_map_with_default: "testing")
    end

    it "sets the default value pre process" do
      expect(person.map_with_default).to eq({ "key" => "testing" })
    end
  end

  context "when a field is defined as a big decimal" do

    context 'when Mongoid.map_big_decimal_to_decimal128 is false' do
      config_override :map_big_decimal_to_decimal128, false

      let(:band) do
        Band.new(name: "Tool")
      end

      let(:decimal) do
        BigDecimal("1000000.00")
      end

      context "when setting to a big decimal" do

        before do
          band.sales = decimal
        end

        it "properly persists as a string" do
          expect(band.attributes["sales"]).to eq(decimal.to_s)
        end

        it "returns the proper big decimal" do
          expect(band.sales).to eq(decimal)
        end
      end

      context "when setting to a string" do

        before do
          band.sales = decimal.to_s
        end

        it "properly persists as a string" do
          expect(band.attributes["sales"]).to eq(decimal.to_s)
        end

        it "returns the proper big decimal" do
          expect(band.sales).to eq(decimal)
        end
      end

      context "when setting to an integer" do

        before do
          band.sales = decimal.to_i
        end

        it "properly persists as a string" do
          expect(band.attributes["sales"]).to eq("1000000")
        end

        it "returns the proper big decimal" do
          expect(band.sales).to eq(decimal)
        end
      end

      context "when setting to a float" do

        before do
          band.sales = decimal.to_f
        end

        it "properly persists as a string" do
          expect(band.attributes["sales"]).to eq(decimal.to_s)
        end

        it "returns the proper big decimal" do
          expect(band.sales).to eq(decimal)
        end
      end
    end

    context 'when Mongoid.map_big_decimal_to_decimal128 is true' do
      config_override :map_big_decimal_to_decimal128, true

      let(:band) do
        Band.new(name: "Tool")
      end

      let(:decimal) do
        BigDecimal("1000000.00")
      end

      context "when setting to a big decimal" do

        before do
          band.sales = decimal
        end

        it "properly persists as a BSON::Decimal128" do
          expect(band.attributes["sales"]).to eq(BSON::Decimal128.new(decimal))
        end

        it "returns the proper big decimal" do
          expect(band.sales).to eq(decimal)
        end
      end

      context "when setting to a string" do

        before do
          band.sales = decimal.to_s
        end

        it "persists as a BSON::Decimal128" do
          expect(band.attributes["sales"]).to eq(BSON::Decimal128.new(decimal.to_s))
        end

        it "returns the proper big decimal" do
          expect(band.sales).to eq(decimal)
        end
      end

      context "when setting to an integer" do

        before do
          band.sales = decimal.to_i
        end

        it "persists as a BSON::Decimal128" do
          expect(band.attributes["sales"]).to eq(BSON::Decimal128.new(decimal.to_i.to_s))
        end

        it "returns the proper big decimal" do
          expect(band.sales).to eq(decimal)
        end
      end

      context "when setting to a float" do

        before do
          band.sales = decimal.to_f
        end

        it "properly persists as a BSON::Decimal128" do
          expect(band.attributes["sales"]).to eq(BSON::Decimal128.new(decimal.to_f.to_s))
        end

        it "returns the proper big decimal" do
          expect(band.sales).to eq(decimal)
        end
      end
    end
  end

  context "when the field is a hash of arrays" do

    let(:person) do
      Person.create!
    end

    let(:map) do
      {
        "stack1" => [ 1, 2, 3, 4 ],
        "stack2" => [ 1, 2, 3, 4 ],
        "stack3" => [ 1, 2, 3, 4 ]
      }
    end

    before do
      person.map = map
      person.map["stack1"].reverse!
      person.save!
    end

    it "properly updates the hash" do
      expect(person.map).to eq(
        {
          "stack1" => [ 4, 3, 2, 1 ],
          "stack2" => [ 1, 2, 3, 4 ],
          "stack3" => [ 1, 2, 3, 4 ]
        }
      )
    end

    it "persists the changes" do
      expect(person.reload.map).to eq(
        {
          "stack1" => [ 4, 3, 2, 1 ],
          "stack2" => [ 1, 2, 3, 4 ],
          "stack3" => [ 1, 2, 3, 4 ]
        }
      )
    end
  end

  context "when overriding a parent class field" do

    context "when the field has a default value" do

      let!(:canvas) do
        Canvas.new
      end

      let!(:test) do
        Canvas::Test.new
      end

      it "does not override the parent" do
        expect(canvas.foo).to eq("original")
      end

      it "overrides the default" do
        expect(test.foo).to eq("overridden")
      end
    end
  end

  context "when a localized field is a boolean" do

    context "when the default is true" do

      let(:definition) do
        Definition.new
      end

      it "returns the proper predicate result" do
        expect(definition).to be_active
      end
    end
  end

  describe '_type field' do
    context 'on parent class' do
      let(:shape) { Shape.new }

      it 'is correctly set' do
        shape.attributes['_type'].should == 'Shape'
      end
    end

    context 'on child class' do
      let(:circle) { Circle.new }

      it 'is correctly set' do
        circle.attributes['_type'].should == 'Circle'
      end
    end
  end

  describe '.database_field_name' do

    shared_examples_for 'database_field_name' do
      subject { Person.database_field_name(key) }

      context 'non-aliased field name' do
        let(:key) { 't' }
        it { is_expected.to eq 't' }
      end

      context 'aliased field name' do
        let(:key) { 'test' }
        it { is_expected.to eq 't' }
      end

      context 'non-aliased embeds one relation' do
        let(:key) { 'pass' }
        it { is_expected.to eq 'pass' }
      end

      context 'aliased embeds one relation' do
        let(:key) { 'passport' }
        it { is_expected.to eq 'pass' }
      end

      context 'non-aliased embeds many relation' do
        let(:key) { 'mobile_phones' }
        it { is_expected.to eq 'mobile_phones' }
      end

      context 'aliased embeds many relation' do
        let(:key) { 'phones' }
        it { is_expected.to eq 'mobile_phones' }
      end

      context 'non-aliased embeds one field' do
        let(:key) { 'pass.exp' }
        it { is_expected.to eq 'pass.exp' }
      end

      context 'aliased embeds one field' do
        let(:key) { 'passport.expiration_date' }
        it { is_expected.to eq 'pass.exp' }
      end

      context 'non-aliased embeds many field' do
        let(:key) { 'mobile_phones.landline' }
        it { is_expected.to eq 'mobile_phones.landline' }
      end

      context 'aliased embeds many field' do
        let(:key) { 'phones.extension' }
        it { is_expected.to eq 'mobile_phones.ext' }
      end

      context 'aliased multi-level embedded document' do
        let(:key) { 'phones.extension' }
        it { is_expected.to eq 'mobile_phones.ext' }
      end

      context 'non-aliased multi-level embedded document' do
        let(:key) { 'phones.extension' }
        it { is_expected.to eq 'mobile_phones.ext' }
      end

      context 'aliased multi-level embedded document field' do
        let(:key) { 'mobile_phones.country_code.code' }
        it { is_expected.to eq 'mobile_phones.country_code.code' }
      end

      context 'non-aliased multi-level embedded document field' do
        let(:key) { 'phones.country_code.iso_alpha2_code' }
        it { is_expected.to eq 'mobile_phones.country_code.iso' }
      end

      context 'when field is unknown' do
        let(:key) { 'shenanigans' }
        it { is_expected.to eq 'shenanigans' }
      end

      context 'when embedded field is unknown' do
        let(:key) { 'phones.bamboozle' }
        it { is_expected.to eq 'mobile_phones.bamboozle' }
      end

      context 'when multi-level embedded field is unknown' do
        let(:key) { 'phones.bamboozle.brouhaha' }
        it { is_expected.to eq 'mobile_phones.bamboozle.brouhaha' }
      end
    end

    shared_examples_for 'pre-fix database_field_name' do
      subject { Person.database_field_name(key) }

      context 'non-aliased field name' do
        let(:key) { 't' }
        it { is_expected.to eq 't' }
      end

      context 'aliased field name' do
        let(:key) { 'test' }
        it { is_expected.to eq 't' }
      end

      context 'non-aliased embeds one relation' do
        let(:key) { 'pass' }
        it { is_expected.to eq 'pass' }
      end

      context 'aliased embeds one relation' do
        let(:key) { 'passport' }
        it { is_expected.to eq 'pass' }
      end

      context 'non-aliased embeds many relation' do
        let(:key) { 'mobile_phones' }
        it { is_expected.to eq 'mobile_phones' }
      end

      context 'aliased embeds many relation' do
        let(:key) { 'phones' }
        it { is_expected.to eq 'mobile_phones' }
      end

      context 'non-aliased embeds one field' do
        let(:key) { 'pass.exp' }
        it { is_expected.to eq 'pass.exp' }
      end

      context 'aliased embeds one field' do
        let(:key) { 'passport.expiration_date' }
        it { is_expected.to eq 'passport.expiration_date' }
      end

      context 'non-aliased embeds many field' do
        let(:key) { 'mobile_phones.landline' }
        it { is_expected.to eq 'mobile_phones.landline' }
      end

      context 'aliased embeds many field' do
        let(:key) { 'phones.extension' }
        it { is_expected.to eq 'phones.extension' }
      end

      context 'aliased multi-level embedded document' do
        let(:key) { 'phones.extension' }
        it { is_expected.to eq 'phones.extension' }
      end

      context 'non-aliased multi-level embedded document' do
        let(:key) { 'phones.extension' }
        it { is_expected.to eq 'phones.extension' }
      end

      context 'aliased multi-level embedded document field' do
        let(:key) { 'mobile_phones.country_code.code' }
        it { is_expected.to eq 'mobile_phones.country_code.code' }
      end

      context 'non-aliased multi-level embedded document field' do
        let(:key) { 'phones.country_code.iso_alpha2_code' }
        it { is_expected.to eq 'phones.country_code.iso_alpha2_code' }
      end

      context 'when field is unknown' do
        let(:key) { 'shenanigans' }
        it { is_expected.to eq 'shenanigans' }
      end

      context 'when embedded field is unknown' do
        let(:key) { 'phones.bamboozle' }
        it { is_expected.to eq 'phones.bamboozle' }
      end

      context 'when multi-level embedded field is unknown' do
        let(:key) { 'phones.bamboozle.brouhaha' }
        it { is_expected.to eq 'phones.bamboozle.brouhaha' }
      end
    end

    context "when the broken_alias_handling is not set" do
      config_override :broken_alias_handling, false

      context 'given nil' do
        subject { Person.database_field_name(nil) }
        it { is_expected.to eq nil }
      end

      context 'given an empty String' do
        subject { Person.database_field_name('') }
        it { is_expected.to eq nil }
      end

      context 'given a String' do
        subject { Person.database_field_name(key.to_s) }
        it_behaves_like 'database_field_name'
      end

      context 'given a Symbol' do
        subject { Person.database_field_name(key.to_sym) }
        it_behaves_like 'database_field_name'
      end
    end

    context "when the broken_alias_handling is set" do
      config_override :broken_alias_handling, true

      context 'given nil' do
        subject { Person.database_field_name(nil) }
        it { is_expected.to eq nil }
      end

      context 'given an empty String' do
        subject { Person.database_field_name('') }
        it { is_expected.to eq "" }
      end

      context 'given a String' do
        subject { Person.database_field_name(key.to_s) }
        it_behaves_like 'pre-fix database_field_name'
      end

      context 'given a Symbol' do
        subject { Person.database_field_name(key.to_sym) }
        it_behaves_like 'pre-fix database_field_name'
      end
    end

    context 'when getting the database field name of a belongs_to associations' do
      # These tests only apply when the flag is not set
      config_override :broken_alias_handling, false

      context "when the broken_alias_handling is not set" do
        context "when the association is the last item" do
          let(:name) do
            Game.database_field_name("person")
          end

          it "gets the alias" do
            expect(name).to eq("person_id")
          end
        end

        context "when the association is not the last item" do
          let(:name) do
            Game.database_field_name("person.name")
          end

          it "gets the alias" do
            expect(name).to eq("person.name")
          end
        end
      end
    end
  end

  describe "#get_field" do

    let(:klass) { Person }
    let(:field) { klass.cleanse_localized_field_names(field_name) }

    context "when cleansing a field" do
      let(:field_name) { "employer_id" }
      it "returns the correct field name" do
        expect(field).to eq(field_name)
      end
    end

    context "when cleansing a localized field" do
      let(:field_name) { "desc" }
      it "returns the correct field name" do
        expect(field).to eq(field_name)
      end
    end

    context "when cleansing a translation field" do
      let(:field_name) { "desc_translations" }
      it "returns the correct field name" do
        expect(field).to eq("desc")
      end
    end

    context "when cleansing an existing translation field" do
      let(:field_name) { "localized_translations" }
      it "returns the correct field name" do
        expect(field).to eq(field_name)
      end
    end

    context "when cleansing an existing translation field with a _translations" do
      let(:field_name) { "localized_translations_translations" }
      it "returns the correct field name" do
        expect(field).to eq("localized_translations")
      end
    end

    context "when cleansing dotted translation field" do
      config_override :broken_alias_handling, false
      let(:field_name) { "passport.name_translations.asd" }
      it "returns the correct field name" do
        expect(field).to eq("pass.name.asd")
      end
    end

    context "when cleansing dotted translation field as a symbol" do
      config_override :broken_alias_handling, false
      let(:field_name) { "passport.name_translations.asd".to_sym }
      it "returns the correct field name" do
        expect(field).to eq("pass.name.asd")
      end
    end

    context "when cleansing dotted existing translation field" do
      config_override :broken_alias_handling, false
      let(:field_name) { "passport.localized_translations.asd" }
      it "returns the correct field name" do
        expect(field).to eq("pass.localized_translations.asd")
      end
    end

    context "when cleansing aliased dotted translation field" do
      let(:field_name) { "pass.name_translations.asd" }
      it "returns the correct field name" do
        expect(field).to eq("pass.name.asd")
      end
    end
  end

  describe "localize: :present" do

    let(:product) do
      Product.new
    end

    context "when assigning a non blank value" do

      before do
        product.title = "hello"
      end

      it "assigns the value" do
        expect(product.title).to eq("hello")
      end

      it "populates the translations hash" do
        expect(product.title_translations).to eq({ "en" => "hello" })
      end
    end

    context "when assigning an empty string" do
      with_default_i18n_configs

      before do
        I18n.locale = :en
        product.title = "hello"
        I18n.locale = :de
        product.title = "hello there!"
        product.title = ""
      end

      it "assigns the value" do
        expect(product.title).to eq(nil)
      end

      it "populates the translations hash" do
        expect(product.title_translations).to eq({ "en" => "hello" })
      end
    end

    context "when assigning nil" do
      with_default_i18n_configs

      before do
        I18n.locale = :en
        product.title = "hello"
        I18n.locale = :de
        product.title = "hello there!"
        product.title = nil
      end

      it "assigns the value" do
        expect(product.title).to eq(nil)
      end

      it "populates the translations hash" do
        expect(product.title_translations).to eq({ "en" => "hello" })
      end
    end

    context "when assigning an empty array" do
      with_default_i18n_configs

      before do
        I18n.locale = :en
        product.title = "hello"
        I18n.locale = :de
        product.title = "hello there!"
        product.title = []
      end

      it "assigns the value" do
        expect(product.title).to eq(nil)
      end

      it "populates the translations hash" do
        expect(product.title_translations).to eq({ "en" => "hello" })
      end
    end

    context "when assigning an empty string first" do
      with_default_i18n_configs

      before do
        product.title = ""
      end

      it "assigns the value" do
        expect(product.title).to eq(nil)
      end

      it "populates the translations hash" do
        expect(product.title_translations).to eq({})
      end
    end

    context "when assigning an empty string with only one translation" do
      with_default_i18n_configs

      before do
        product.title = "Hello"
        product.title = ""
        product.save!
      end

      let(:from_db) { Product.first }

      it "assigns the value" do
        expect(product.title).to eq(nil)
      end

      it "populates the translations hash" do
        expect(product.title_translations).to eq({})
      end

      it "round trips an empty hash" do
        expect(from_db.title_translations).to eq({})
      end
    end
  end
end
