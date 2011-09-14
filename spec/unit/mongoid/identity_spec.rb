require "spec_helper"

describe Mongoid::Identity do

  describe "#create" do

    let(:name) do
      Name.new
    end

    context "when the class is polymorphic" do

      let(:movie) do
        Movie.new
      end

      before do
        Mongoid::Identity.new(movie).create
      end

      it "sets the document type to the class name" do
        movie._type.should == "Movie"
      end
    end

    context "when class is inherited" do

      let(:canvas) do
        Canvas.new
      end

      before do
        Mongoid::Identity.new(canvas).create
      end

      it "sets the document _type to the class name" do
        canvas._type.should == "Canvas"
      end
    end

    context "when class is a subclass" do
      before do
        Mongoid::Identity.new(browser).create
      end

      context "and the subclass does not have a primary key" do
        let(:browser){ Browser.new }

        it "sets the document _type to the class name" do
          browser._type.should == "Browser"
        end
      end

      context "and the subclass has a primary key defined" do
        let(:browser){ Browser.new :id => 1234 }

        it "sets the document _type to the class name" do
          browser._type.should == "Browser"
        end
      end
    end

    context "when not using inheritance" do

      it "does not set the type" do
        name._type.should be_nil
      end
    end

    context "when the document has a primary key" do

      let(:address) do
        Address.allocate
      end

      before do
        address.instance_variable_set(:@attributes, { "street" => "Market St"})
        Mongoid::Identity.new(address).create
      end

      it "sets the id to the composite key" do
        address.id.should == "market-st"
      end
    end

    context "when the document has no primary key" do

      context "when the document has no id" do

        let(:person) do
          Person.allocate
        end

        let(:object_id) do
          stub(:to_s => "1")
        end

        before do
          person.instance_variable_set(:@attributes, {})
          BSON::ObjectId.expects(:new).returns(object_id)
        end

        context "when using object ids" do

          before do
            Mongoid::Identity.new(person).create
          end

          it "sets the id to a mongo object id" do
            person.id.should == object_id
          end
        end

        context "when not using object ids" do

          before do
            Person.identity(:type => String)
            Mongoid::Identity.new(person).create
          end

          after do
            Person.identity(:type => BSON::ObjectId)
          end

          it "sets the id to a mongo object id string" do
            person.id.should == "1"
          end
        end
      end

      context "when the document has an id" do

        let(:person) do
          Person.allocate
        end

        before do
          person.instance_variable_set(:@attributes, { "_id" => "5" })
          Mongoid::Identity.new(person)
        end

        it "returns the existing id" do
          person.id.should == "5"
        end
      end
    end
  end
end
