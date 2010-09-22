require "spec_helper"

describe Mongoid::Identity do

  describe ".create" do

    let(:name) { Name.new }

    context "when class is inherited" do

      let(:canvas) { Canvas.new }

      it "sets the document _type to the class name" do
        Mongoid::Identity.new(canvas).create
        canvas._type.should == "Canvas"
      end

    end

    context "when class is a subclass" do

      let(:browser) { Browser.new }

      it "sets the document _type to the class name" do
        Mongoid::Identity.new(browser).create
        browser._type.should == "Browser"
      end

    end

    context "when not using inheritance" do

      it "does not set the type" do
        name._type.should be_nil
      end

    end

    context "when the document has a primary key" do

      before do
        @address = Address.allocate
        @address.instance_variable_set(:@attributes, { "street" => "Market St"})
      end

      it "sets the id to the composite key" do
        Mongoid::Identity.new(@address).create
        @address.id.should == "market-st"
      end

    end

    context "when the document has no primary key" do

      context "when the document has no id" do

        before do
          @person = Person.allocate
          @person.instance_variable_set(:@attributes, {})
          @object_id = stub(:to_s => "1")
          BSON::ObjectId.expects(:new).returns(@object_id)
        end

        context "when using object ids" do

          before do
            Person.identity :type => BSON::ObjectId
          end

          after do
            Person.identity :type => String
          end

          it "sets the id to a mongo object id" do
            Mongoid::Identity.new(@person).create
            @person.id.should == @object_id
          end
        end

        context "when not using object ids" do

          it "sets the id to a mongo object id string" do
            Mongoid::Identity.new(@person).create
            @person.id.should == "1"
          end

        end

      end

      context "when the document has an id" do

        before do
          @person = Person.allocate
          @person.instance_variable_set(:@attributes, { "_id" => "5" })
        end

        it "returns the existing id" do
          Mongoid::Identity.new(@person)
          @person.id.should == "5"
        end

      end

    end

  end

end
