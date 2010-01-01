require "spec_helper"

describe Mongoid::Extensions::Hash::Assimilation do

  describe "#assimilate" do

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

  end

end
