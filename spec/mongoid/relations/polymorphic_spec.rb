require "spec_helper"

describe Mongoid::Relations::Polymorphic do

  describe "#polymorph" do

    let(:klass) do
      Class.new.tap { |c| c.send(:include, Mongoid::Document) }
    end

    context "when the relation is polymorphic" do

      context "when the relation stores a foreign key" do

        let(:metadata) do
          Mongoid::Relations::Metadata.new(
            name: :ratable,
            polymorphic: true,
            relation: Mongoid::Relations::Referenced::In
          )
        end

        let!(:polymorphed) do
          klass.polymorph(metadata)
        end

        it "sets polymorphic to true" do
          klass.should be_polymorphic
        end

        it "adds the foreign key type field" do
          klass.fields["ratable_type"].should_not be_nil
        end

        it "adds the foreign key inverse field field" do
          klass.fields["ratable_field"].should_not be_nil
        end

        it "returns self" do
          polymorphed.should eq(klass)
        end
      end

      context "when the relation does not store a foreign key" do

        let(:metadata) do
          Mongoid::Relations::Metadata.new(
            name: :ratings,
            as: :ratable,
            relation: Mongoid::Relations::Referenced::Many
          )
        end

        before do
          klass.polymorph(metadata)
        end

        it "sets polymorphic to true" do
          klass.should be_polymorphic
        end

        it "does not add the foreign key type field" do
          klass.fields["ratable_type"].should be_nil
        end

        it "does not add the foreign key inverse field field" do
          klass.fields["ratable_field"].should be_nil
        end
      end
    end

    context "when the relation is not polymorphic" do

      let(:metadata) do
        Mongoid::Relations::Metadata.new(
          name: :ratings,
          relation: Mongoid::Relations::Referenced::Many
        )
      end

      before do
        klass.polymorph(metadata)
      end

      it "sets polymorphic to false" do
        klass.should_not be_polymorphic
      end

      it "does not add the foreign key type field" do
        klass.fields["ratable_type"].should be_nil
      end

      it "does not add the foreign key inverse field field" do
        klass.fields["ratable_field"].should be_nil
      end
    end
  end

  describe ".polymorphic?" do

    context "when the document is in a polymorphic relation" do

      it "returns true" do
        Movie.should be_polymorphic
      end
    end

    context "when the document is not in a polymorphic relation" do

      it "returns false" do
        Survey.should_not be_polymorphic
      end
    end
  end

  describe "#polymorphic?" do

    context "when the document is in a polymorphic relation" do

      it "returns true" do
        Movie.new.should be_polymorphic
      end
    end

    context "when the document is not in a polymorphic relation" do

      it "returns false" do
        Survey.new.should_not be_polymorphic
      end
    end
  end
end
