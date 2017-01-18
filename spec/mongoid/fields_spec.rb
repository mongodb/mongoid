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
          I18n.enforce_available_locales = false
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
            product.save
          end

          it "persists the changes" do
            expect(product.reload.description_translations).to eq(translations)
          end

          context "when updating the translations" do

            before do
              product.description_translations = { "en" => "overwritten" }
              product.save
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
            dictionary.save
          end

          it "persists the changes" do
            expect(dictionary.reload.description_translations).to eq(
              { "en" => "1", "de" => "2" }
            )
          end

          context "when updating the translations" do

            before do
              dictionary.description_translations = { "en" => "overwritten" }
              dictionary.save
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
        expect(klass.field(:test, type: Boolean).type).to be(Mongoid::Boolean)
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
          expect(Band.fields["acceptable"]).to_not be_nil
        end
      end

      context "when a custom option is provided" do

        before do
          Band.field :acceptable, type: Boolean, custom: true
        end

        it "adds the field to the model" do
          expect(Band.fields["acceptable"]).to_not be_nil
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
          expect(description).to eq("The best")
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
        person.age = "old"
        expect(person.age_before_type_cast).to eq("old")
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
        product.save
      end

      context "when setting the value to nil" do

        before do
          product.stores = nil
          product.save
        end

        it "allows the set" do
          expect(product.stores).to be_nil
        end
      end

      context "when setting any of the values to nil" do

        before do
          product.stores = [ "kadewe", nil ]
          product.save
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
          product.save
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
          expect(description).to eq({ "de" => "Cheaper drinks" })
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
          expect(description).to eq(
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
        expect(shape.pre_processed_defaults).to eq([ "_id", "x", "y", "_type" ])
      end
    end

    context "on subclasses" do

      let(:circle) do
        Circle.new
      end

      it "has the parent and child defaults" do
        expect(circle.pre_processed_defaults).to eq([ "_id", "x", "y", "_type", "radius" ])
      end
    end
  end

  describe ".field" do

    it "returns the generated field" do
      expect(Person.field(:testing)).to eq(Person.fields["testing"])
    end

    context "when the field name conflicts with mongoid's internals" do

      [:__metadata, :invalid].each do |meth|
        context "when the field is named #{meth}" do

          it "raises an error" do
            expect {
              Person.field(meth)
            }.to raise_error(Mongoid::Errors::InvalidField)
          end
        end
      end
    end

    context "when field already exist and validate_duplicate is enable" do

      before do
        Mongoid.duplicate_fields_exception = true
      end

      after do
        Mongoid.duplicate_fields_exception = false
      end

      it "raises an error" do
        expect {
          Person.field(:title)
        }.to raise_error(Mongoid::Errors::InvalidField)
      end

      it "doesn't raise an error" do
        expect {
          Class.new(Person)
        }.to_not raise_error
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
        Person.field :aliased, as: :alias, type: Boolean, overwrite: true
      end

      it "uses the alias to write the attribute" do
        (person.alias = expect(true)).to be true
      end

      it "uses the alias to read the attribute" do
        expect(person.alias).to be true
      end

      it "uses the alias for the query method" do
        expect(person).to be_alias
      end

      it "uses the name to write the attribute" do
        (person.aliased = expect(true)).to be true
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

  context "when the field is a hash of arrays" do

    let(:person) do
      Person.create
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
      person.save
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
end
