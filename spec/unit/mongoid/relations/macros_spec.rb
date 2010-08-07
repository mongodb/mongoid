require "spec_helper"

describe Mongoid::Relations::Macros do

  let(:klass) do
    Class.new do
      include Mongoid::Relations::Macros
      def self.name
        "TestClass"
      end
    end
  end

  context ".embedded_in" do

    it "defines the macro" do
      klass.should respond_to(:embedded_in)
    end

    context "when defining the relation" do

      before do
        klass.embedded_in(:person)
      end

      it "adds the metadata to the klass" do
        klass.relations["person"].should_not be_nil
      end

      context "metadata properties" do

        let(:metadata) do
          klass.relations["person"]
        end

        it "automatically adds the name" do
          metadata.name.should == :person
        end

        it "automatically adds the inverse class name" do
          metadata.inverse_class_name.should == "TestClass"
        end
      end
    end
  end

  context ".embeds_many" do

    it "defines the macro" do
      klass.should respond_to(:embeds_many)
    end

    context "when defining the relation" do

      before do
        klass.embeds_many(:addresses)
      end

      it "adds the metadata to the klass" do
        klass.relations["addresses"].should_not be_nil
      end

      context "metadata properties" do

        let(:metadata) do
          klass.relations["addresses"]
        end

        it "automatically adds the name" do
          metadata.name.should == :addresses
        end

        it "automatically adds the inverse class name" do
          metadata.inverse_class_name.should == "TestClass"
        end
      end
    end
  end

  context ".embeds_one" do

    it "defines the macro" do
      klass.should respond_to(:embeds_one)
    end

    context "when defining the relation" do

      before do
        klass.embeds_one(:name)
      end

      it "adds the metadata to the klass" do
        klass.relations["name"].should_not be_nil
      end

      context "metadata properties" do

        let(:metadata) do
          klass.relations["name"]
        end

        it "automatically adds the name" do
          metadata.name.should == :name
        end

        it "automatically adds the inverse class name" do
          metadata.inverse_class_name.should == "TestClass"
        end
      end
    end
  end

  context ".referenced_in" do

    it "defines the macro" do
      klass.should respond_to(:referenced_in)
    end
  end

  context ".references_many" do

    it "defines the macro" do
      klass.should respond_to(:references_many)
    end
  end

  context ".references_one" do

    it "defines the macro" do
      klass.should respond_to(:references_one)
    end
  end
end
