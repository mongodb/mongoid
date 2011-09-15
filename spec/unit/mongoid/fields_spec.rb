require "spec_helper"

describe Mongoid::Fields do

  describe ".defaults" do

    it "returns a hash of all the default values" do
      Game.defaults.should eq([ "high_score", "score" ])
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
          Person.field(:array_testing, :type => Array, :default => [])
        end

        after do
          Person.fields.delete("array_testing")
          Person.defaults.delete_one("array_testing")
        end

        it "returns an equal object of a different instance" do
          person_one.array_testing.object_id.should_not ==
            person_two.array_testing.object_id
        end
      end

      context "when provided a default hash" do

        before do
          Person.field(:hash_testing, :type => Hash, :default => {})
        end

        after do
          Person.fields.delete("hash_testing")
        end

        it "returns an equal object of a different instance" do
          person_one.hash_testing.object_id.should_not ==
            person_two.hash_testing.object_id
        end
      end

      context "when provided a default proc" do

        context "when the proc has no argument" do

          before do
            Person.field(
              :generated_testing,
              :type => Float,
              :default => lambda { Time.now.to_f }
            )
          end

          after do
            Person.fields.delete("generated_testing")
            Person.defaults.delete_one("generated_testing")
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
              :type => Integer,
              :default => lambda { title? ? 1 : 2 }
            )
          end

          after do
            Person.fields.delete("rank")
            Person.defaults.delete_one("rank")
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
        shape.defaults.should eq([ "x", "y" ])
      end
    end

    context "on subclasses" do

      let(:circle) do
        Circle.new
      end

      it "has the parent and child defaults" do
        circle.defaults.should eq([ "x", "y", "radius" ])
      end
    end
  end

  describe ".field" do

    it "returns the generated field" do
      Person.field(:testing).should equal Person.fields["testing"]
    end

    context "when the field name conflicts with mongoid's internals" do

      it "raises an error" do
        expect {
          Person.field(:identifier)
        }.to raise_error(Mongoid::Errors::InvalidField)
      end
    end

    context "when the field is a time" do

      let!(:time) do
        Time.now
      end

      let!(:person) do
        Person.new(:lunch_time => time.utc)
      end

      context "when reading the field" do

        before do
          Time.zone = "Berlin"
        end

        after do
          Time.zone = nil
        end

        it "performs the necessary time conversions" do
          person.lunch_time.to_s.should == time.getlocal.to_s
        end
      end
    end

    context "with no options" do

      before do
        Person.field(:testing)
      end

      let(:person) do
        Person.new(:testing => "Test")
      end

      it "adds a reader for the fields defined" do
        person.testing.should == "Test"
      end

      it "adds a writer for the fields defined" do
        person.testing = "Testy"
        person.testing.should == "Testy"
      end

      it "adds an existance method" do
        person.testing?.should be_true
        Person.new.testing?.should be_false
      end

      it "adds field methods in a module to allow overriding and preserve inheritance" do
        Person.class_eval do
          attr_reader :testing_override_called
          def testing=(value)
            @testing_override_called = true
            super
          end
        end
        person.testing = 'Test'
        person.testing_override_called.should be_true
      end
    end

    context "when the type is an object" do

      let(:bob) do
        Person.new(:reading => 10.023)
      end

      it "returns the given value" do
        bob.reading.should == 10.023
      end
    end

    context "when type is a boolean" do

      let(:person) do
        Person.new(:terms => true)
      end

      it "adds an accessor method with a question mark" do
        person.terms?.should be_true
      end
    end

    context "when as is specified" do

      let(:person) do
        Person.new(:alias => true)
      end

      before do
        Person.field :aliased, :as => :alias, :type => Boolean
      end

      it "uses the alias to write the attribute" do
        person.expects(:write_attribute).with("aliased", true)
        person.alias = true
      end

      it "uses the alias to read the attribute" do
        person.expects(:read_attribute).with("aliased")
        person.alias
      end

      it "uses the alias for the query method" do
        person.expects(:read_attribute).with("aliased")
        person.alias?
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
          handler.expects(:call).with do |model,_,_|
            model.should eql Person
          end

          Person.field :custom, :option => true
        end

        it "calls the handler with the field" do
          handler.expects(:call).with do |_,field,_|
            field.should eql Person.fields["custom"]
          end

          Person.field :custom, :option => true
        end

        it "calls the handler with the option value" do
          handler.expects(:call).with do |_,_,value|
            value.should eql true
          end

          Person.field :custom, :option => true
        end
      end

      context "when option is nil" do

        it "calls the handler" do
          handler.expects(:call)
          Person.field :custom, :option => nil
        end
      end

      context "when option is not provided" do

        it "does not call the handler" do
          handler.expects(:call).never

          Person.field :custom
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

      it "includes the parent fields" do
        circle.fields.keys.should include("x")
        circle.fields.keys.should include("y")
      end

      it "includes the child fields" do
        circle.fields.keys.should include("radius")
      end
    end
  end

  describe ".object_id_field?" do

    context "when the field exists" do

      context "when the field is of type BSON::ObjectId" do

        context "when the field is the _id" do

          it "returns true" do
            Person.object_id_field?(:_id).should be_true
          end
        end

        context "when the field is a single foreign key" do

          context "when the relation is not polymorphic" do

            it "returns true" do
              Post.object_id_field?(:person_id).should be_true
            end
          end

          context "when the relation is polymorphic" do

            it "returns true" do
              Rating.object_id_field?(:ratable_id).should be_true
            end
          end
        end

        context "when the field is a multi foreign key" do

          it "returns true" do
            Person.object_id_field?(:preference_ids).should be_true
          end
        end

        context "when the field is not a foreign key" do

          it "returns true" do
            Person.object_id_field?(:bson_id).should be_true
          end
        end
      end

      context "when the field is not an object id" do

        context "when the field is an id" do

          it "returns false" do
            Address.object_id_field?(:_id).should be_false
          end
        end

        context "when the field is a normal field" do

          it "returns false" do
            Person.object_id_field?(:title).should be_false
          end
        end

        context "when the field is a single foreign key" do

          it "returns true" do
            Alert.object_id_field?(:account_id).should be_false
          end
        end

        context "when the field is a multi foreign key" do

          it "returns false" do
            Agent.object_id_field?(:account_ids).should be_false
          end
        end
      end
    end

    context "when the field does not exist" do

      it "returns false" do
        Person.object_id_field?(:some_random_name).should be_false
      end
    end
  end

  describe ".replace_field" do

    let!(:original) do
      Person.field(:id_test, :type => BSON::ObjectId, :label => "id")
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
      new_field.type.should == String
    end

    it "keeps the options from the old field" do
      new_field.options[:label].should == "id"
    end
  end
end
