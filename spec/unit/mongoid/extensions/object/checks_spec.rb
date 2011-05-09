require "spec_helper"

describe Mongoid::Extensions::Object::Checks do

  describe "#_vacant?" do

    context "when the object is an array" do

      context "when the object is empty" do

        let(:object) do
          []
        end

        it "returns true" do
          object.should be__vacant
        end
      end

      context "when the object is not empty" do

        let(:object) do
          [ :testing ]
        end

        it "returns false" do
          object.should_not be__vacant
        end
      end
    end

    context "when the object is a hash" do

      context "when the object is empty" do

        let(:object) do
          {}
        end

        it "returns true" do
          object.should be__vacant
        end
      end

      context "when the object is not empty" do

        let(:object) do
          { :testing => "first" }
        end

        it "returns false" do
          object.should_not be__vacant
        end
      end
    end

    context "when the object is nil" do

      it "returns true" do
        nil.should be__vacant
      end
    end

    context "when the object is an empty string" do

      it "returns true" do
        "".should be__vacant
      end
    end

    context "when the object is not nil" do

      it "returns false" do
        "testing".should_not be__vacant
      end
    end
  end
end
