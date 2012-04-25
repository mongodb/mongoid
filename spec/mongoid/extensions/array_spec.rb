require "spec_helper"

describe Mongoid::Extensions::Array do

  describe ".__mongoize_fk__" do

    context "when the related model uses object ids" do

      let(:metadata) do
        Person.relations["preferences"]
      end

      let(:constraint) do
        metadata.constraint
      end

      context "when provided an object id" do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:fk) do
          Array.__mongoize_fk__(constraint, object_id)
        end

        it "returns the object id as an array" do
          fk.should eq([ object_id ])
        end
      end

      context "when provided a object ids" do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:fk) do
          Array.__mongoize_fk__(constraint, [ object_id ])
        end

        it "returns the object ids" do
          fk.should eq([ object_id ])
        end
      end

      context "when provided a string" do

        context "when the string is a legal object id" do

          let(:object_id) do
            BSON::ObjectId.new
          end

          let(:fk) do
            Array.__mongoize_fk__(constraint, object_id.to_s)
          end

          it "returns the object id in an array" do
            fk.should eq([ object_id ])
          end
        end

        context "when the string is not a legal object id" do

          let(:string) do
            "blah"
          end

          let(:fk) do
            Array.__mongoize_fk__(constraint, string)
          end

          it "returns the string in an array" do
            fk.should eq([ string ])
          end
        end

        context "when the string is blank" do

          let(:fk) do
            Array.__mongoize_fk__(constraint, "")
          end

          it "returns an empty array" do
            fk.should be_empty
          end
        end
      end

      context "when provided nil" do

        let(:fk) do
          Array.__mongoize_fk__(constraint, nil)
        end

        it "returns an empty array" do
          fk.should be_empty
        end
      end

      context "when provided an array of strings" do

        context "when the strings are legal object ids" do

          let(:object_id) do
            BSON::ObjectId.new
          end

          let(:fk) do
            Array.__mongoize_fk__(constraint, [ object_id.to_s ])
          end

          it "returns the object id in an array" do
            fk.should eq([ object_id ])
          end
        end

        context "when the strings are not legal object ids" do

          let(:string) do
            "blah"
          end

          let(:fk) do
            Array.__mongoize_fk__(constraint, [ string ])
          end

          it "returns the string in an array" do
            fk.should eq([ string ])
          end
        end

        context "when the strings are blank" do

          let(:fk) do
            Array.__mongoize_fk__(constraint, [ "", "" ])
          end

          it "returns an empty array" do
            fk.should be_empty
          end
        end
      end

      context "when provided nils" do

        let(:fk) do
          Array.__mongoize_fk__(constraint, [ nil, nil, nil ])
        end

        it "returns an empty array" do
          fk.should be_empty
        end
      end
    end
  end

  describe "#delete_one" do

    context "when the object doesn't exist" do

      let(:array) do
        []
      end

      let!(:deleted) do
        array.delete_one("1")
      end

      it "returns nil" do
        deleted.should be_nil
      end
    end

    context "when the object exists once" do

      let(:array) do
        [ "1", "2" ]
      end

      let!(:deleted) do
        array.delete_one("1")
      end

      it "deletes the object" do
        array.should eq([ "2" ])
      end

      it "returns the object" do
        deleted.should eq("1")
      end
    end

    context "when the object exists more than once" do

      let(:array) do
        [ "1", "2", "1" ]
      end

      let!(:deleted) do
        array.delete_one("1")
      end

      it "deletes the first object" do
        array.should eq([ "2", "1" ])
      end

      it "returns the object" do
        deleted.should eq("1")
      end
    end
  end

  describe ".demongoize" do

    let(:array) do
      [ 1, 2, 3 ]
    end

    it "returns the array" do
      Array.demongoize(array).should eq(array)
    end
  end

  describe ".mongoize" do

    let(:date) do
      Date.new(2012, 1, 1)
    end

    let(:array) do
      [ date ]
    end

    let(:mongoized) do
      Array.mongoize(array)
    end

    it "mongoizes each element in the array" do
      mongoized.first.should be_a(Time)
    end

    it "converts the elements properly" do
      mongoized.first.should eq(date)
    end
  end

  describe "#mongoize" do

    let(:date) do
      Date.new(2012, 1, 1)
    end

    let(:array) do
      [ date ]
    end

    let(:mongoized) do
      array.mongoize
    end

    it "mongoizes each element in the array" do
      mongoized.first.should be_a(Time)
    end

    it "converts the elements properly" do
      mongoized.first.should eq(date)
    end
  end

  describe ".resizable?" do

    it "returns true" do
      Array.should be_resizable
    end
  end

  describe "#resiable?" do

    it "returns true" do
      [].should be_resizable
    end
  end
end
