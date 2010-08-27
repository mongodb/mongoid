require "spec_helper"

describe Mongoid::Fields do

  describe ".defaults" do

    it "returns a hash of all the default values" do
      Game.defaults.should == { "high_score" => 500, "score" => 0 }
    end

  end

  describe "#defaults" do

    context "with defaults specified as a non-primitive" do

      before do
        Person.field(:hash_testing, :type => Hash, :default => {})
        Person.field(:array_testing, :type => Array, :default => [])
        @first_person = Person.new
        @second_person = Person.new
      end

      after do
        Person.fields.delete("hash_testing")
        Person.fields.delete("array_testing")
      end

      it "should not return the same object when calling defaults with a default hash" do
        @first_person.hash_testing.object_id.should_not == @second_person.hash_testing.object_id
      end

      it "should not return the same object when calling defaults with a default array" do
        @first_person.array_testing.object_id.should_not == @second_person.array_testing.object_id
      end
    end

    context "on parent classes" do

      before do
        @shape = Shape.new
      end

      it "does not return subclass defaults" do
        @shape.defaults.should == { "x" => 0, "y" => 0 }
      end

    end

    context "on subclasses" do

      before do
        @circle = Circle.new
      end

      it "has the parent and child defaults" do
        @circle.defaults.should == { "x" => 0, "y" => 0, "radius" => 0 }
      end

    end

  end

  describe ".field" do

    context "with no options" do

      before do
        Person.field(:testing)
      end

      it "adds a reader for the fields defined" do
        @person = Person.new(:testing => "Test")
        @person.testing.should == "Test"
      end

      it "adds a writer for the fields defined" do
        @person = Person.new(:testing => "Test")
        @person.testing = "Testy"
        @person.testing.should == "Testy"
      end

      it "adds an reader method with a question mark" do
        @person = Person.new(:testing => "Test")
        @person.testing?.should be_true
        Person.new.testing?.should be_false
      end

    end

    context "when the type is an object" do

      let(:bob) { Person.new(:reading => 10.023) }

      it "returns the given value" do
        bob.reading.should == 10.023
      end

    end

    context "when type is a mongoid document" do

      before do
        @person = Person.new
        @drink = MixedDrink.new(:name => "Jack and Coke")
        @person.mixed_drink = @drink
      end

      it "allows proper access to the object" do
        @person.mixed_drink.should == @drink
        @person.attributes[:mixed_drink].except(:_id).except(:_type).should ==
          { "name" => "Jack and Coke" }
      end

      it "adds an reader method with a question mark" do
        @person.mixed_drink?.should be_true
      end

    end

    context "when type is a boolean" do

      before do
        @person = Person.new(:terms => true)
      end

      it "adds an accessor method with a question mark" do
        @person.terms?.should be_true
      end

    end

    context "when as is specified" do

      before do
        Person.field :aliased, :as => :alias, :type => Boolean
        @person = Person.new(:alias => true)
      end

      it "uses the alias to write the attribute" do
        @person.expects(:write_attribute).with("aliased", true)
        @person.alias = true
      end

      it "uses the alias to read the attribute" do
        @person.expects(:read_attribute).with("aliased")
        @person.alias
      end

      it "uses the alias for the query method" do
        @person.expects(:read_attribute).with("aliased")
        @person.alias?
      end

    end

  end

  describe "#fields" do

    context "on parent classes" do

      before do
        @shape = Shape.new
      end

      it "does not return subclass fields" do
        @shape.fields.keys.should include("x")
        @shape.fields.keys.should include("y")
        @shape.fields.keys.should_not include("radius")
      end

    end

    context "on subclasses" do

      before do
        @circle = Circle.new
      end

      it "has the parent and child fields" do
        @circle.fields.keys.should include("x")
        @circle.fields.keys.should include("y")
        @circle.fields.keys.should include("radius")
      end

    end

  end

end
