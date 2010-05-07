require "spec_helper"

describe Mongoid::Extensions::Hash::Assimilation do

  describe "#assimilate" do

    context "when an id exists" do

      before do
        @child = { "_id" => "hank-moody", "first_name" => "Hank", "last_name" => "Moody" }
        @parent = Person.new(:title => "Mr.")
        @options = Mongoid::Associations::Options.new(:name => :name)
        @document = @child.assimilate(@parent, @options)
      end

      it "sets the id" do
        @document._id.should == "hank-moody"
      end

      it "considers the document persisted" do
        @document.new_record?.should == false
      end
    end

    context "when a type is not provided" do

      before do
        @child = { :first_name => "Hank", :last_name => "Moody" }
        @parent = Person.new(:title => "Mr.")
        @options = Mongoid::Associations::Options.new(:name => :name)
      end

      it "incorporates the hash into the object graph" do
        @child.assimilate(@parent, @options)
        @parent.name.first_name.should == "Hank"
        @parent.name.last_name.should == "Moody"
      end

    end

    context "when a type is provided" do

      before do
        @child = { :speed => 300 }
        @parent = Canvas.new(:name => "web page")
        @options = Mongoid::Associations::Options.new(:name => :writer)
      end

      it "incorporates the hash into the object graph with the supplied type" do
        @child.assimilate(@parent, @options, HtmlWriter)
        @parent.writer.should be_a_kind_of(HtmlWriter)
        @parent.writer.speed.should == 300
      end

      it "adds the _type field to the hash" do
        @child.assimilate(@parent, @options, HtmlWriter)
        @parent.writer._type.should == "HtmlWriter"
      end

    end

    context "when the child provides the type" do

      before do
        @child = { "radius" => 10, "_type" => "Circle" }
        @parent = Canvas.new()
        @options = Mongoid::Associations::Options.new(:name => :shapes, :class_name => "Shape")
      end

      it "should use the _type information from the child object" do
        @child.assimilate(@parent, @options)
        @parent.shapes.first.should be_a_kind_of(Circle)
        @parent.shapes.first.radius.should == 10
      end
    end
  end
end
