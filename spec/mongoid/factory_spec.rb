require "spec_helper"

describe Mongoid::Factory do

  describe ".build" do

    context "when the type attribute is present" do

      let(:attributes) do
        { "_type" => "Person", "title" => "Sir" }
      end

      context "when the type is a class" do

        let(:person) do
          described_class.build(Person, attributes)
        end

        it "instantiates based on the type" do
          person.title.should eq("Sir")
        end
      end

      context "when the type is a not a subclass" do

        let(:person) do
          described_class.build(Person, { "_type" => "Canvas" })
        end

        it "instantiates the provided class" do
          person.class.should eq(Person)
        end
      end

      context "when the type is a subclass of the provided" do

        let(:person) do
          described_class.build(Person, { "_type" => "Doctor" })
        end

        it "instantiates the subclass" do
          person.class.should eq(Doctor)
        end
      end

      context "when type is an empty string" do

        let(:attributes) do
          { "title" => "Sir", "_type" => "" }
        end

        let(:person) do
          described_class.build(Person, attributes)
        end

        it "instantiates based on the type" do
          person.title.should eq("Sir")
        end
      end

      context "when type is the lower case class name" do

        let(:attributes) do
          { "title" => "Sir", "_type" => "person" }
        end

        let(:person) do
          described_class.build(Person, attributes)
        end

        it "instantiates based on the type" do
          person.title.should eq("Sir")
        end
      end
    end

    context "when type is not preset" do

      let(:attributes) do
        { "title" => "Sir" }
      end

      let(:person) do
        described_class.build(Person, attributes)
      end

      it "instantiates based on the provided class" do
        person.title.should eq("Sir")
      end
    end
  end

  describe ".from_db" do

    context "when the attributes are nil" do

      let(:document) do
        described_class.from_db(Address, nil)
      end

      it "generates based on the provided class" do
        document.should be_a(Address)
      end

      it "sets the attributes to empty" do
        document.attributes.should be_empty
      end
    end

    context "when a type is in the attributes" do

      context "when the type is a class" do

        let(:attributes) do
          { "_type" => "Person", "title" => "Sir" }
        end

        let(:document) do
          described_class.from_db(Address, attributes)
        end

        it "generates based on the type" do
          document.should be_a(Person)
        end

        it "sets the attributes" do
          document.title.should eq("Sir")
        end
      end

      context "when the type is empty" do

        let(:attributes) do
          { "_type" => "", "title" => "Sir" }
        end

        let(:document) do
          described_class.from_db(Person, attributes)
        end

        it "generates based on the provided class" do
          document.should be_a(Person)
        end

        it "sets the attributes" do
          document.title.should eq("Sir")
        end
      end

      context "when type is the lower case class name" do

        let(:attributes) do
          { "title" => "Sir", "_type" => "person" }
        end

        let(:person) do
          described_class.from_db(Person, attributes)
        end

        it "instantiates based on the type" do
          person.title.should eq("Sir")
        end
      end
    end

    context "when a type is not in the attributes" do

      let(:attributes) do
        { "title" => "Sir" }
      end

      let(:document) do
        described_class.from_db(Person, attributes)
      end

      it "generates based on the provided class" do
        document.should be_a(Person)
      end

      it "sets the attributes" do
        document.title.should eq("Sir")
      end
    end
  end
  
  describe ".from_map_or_db" do
    before(:each) do
      Mongoid::IdentityMap.clear
    end
    
    context "when the attributes are nil" do

      let(:document) do
        described_class.from_map_or_db(Address, nil)
      end

      it "generates based on the provided class" do
        document.should be_a(Address)
      end

      it "sets the attributes to empty" do
        document.attributes.should be_empty
      end
    end
    
    context "when supplying an id" do
      let(:attributes) do
        { "title" => "Sir", "_type" => "person", "_id" => "1"}        
      end
      
      context "when the identity map is enabled" do
        around(:each) do |example|
          Mongoid.identity_map_enabled = true
          example.run
          Mongoid.identity_map_enabled = false
        end
        
        context "when a document for the id is not in the identity map" do
          let(:document) do
            described_class.from_map_or_db(Person, attributes)
          end
        
          it "sets the attributes" do
            document.title.should eq("Sir")
          end          
        end
      
        context "when the document has been previously loaded into the identity map" do
          let(:db_document) do
            described_class.from_db(Person, attributes)
          end
          
          let(:document) do
            described_class.from_map_or_db(Person, attributes)
          end
          
          before(:each) do
            Mongoid::IdentityMap.set(db_document)
          end
          
          it "returns the same instance from the identity map" do
            document.object_id.should eq(db_document.object_id)
          end
        end
      end
      
      context "when the identity map is off" do
        let(:db_document) do
          described_class.from_db(Person, attributes)
        end
          
        let(:document) do
          described_class.from_map_or_db(Person, attributes)
        end

        it "returns a different instance" do
          document.object_id.should_not eq(db_document.object_id)
        end
      end
    end
  end
end
