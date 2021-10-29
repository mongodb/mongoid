# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Referenced::HasAndBelongsToMany::Buildable do

  let(:base) do
    double
  end

  let(:options) do
    { }
  end

  describe "#build" do

    let(:documents) do
      association.build(base, object)
    end

    let(:association) do
      Mongoid::Association::Referenced::HasAndBelongsToMany.new(Person, :preferences, options)
    end

    context "when provided ids" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:object) do
        [ object_id ]
      end

      let(:criteria) do
        Preference.all_of("_id" => { "$in" => object })
      end

      it "returns the criteria" do
        expect(documents).to eq(criteria)
      end
    end

    context "when order specified" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:options) do
        {
          order: :rating.desc
        }
      end

      let(:object) do
        [ object_id ]
      end

      let(:criteria) do
        Preference.all_of("_id" => { "$in" => object }).order_by(options[:order])
      end

      it "returns the criteria" do
        expect(documents).to eq(criteria)
      end
    end

    context "when scope is specified" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:options) do
        {
          scope: -> { where(rating: 3) }
        }
      end

      let(:object) do
        [ object_id ]
      end

      let(:criteria) do
        Preference.all_of("_id" => { "$in" => object }).where(rating: 3)
      end

      it "returns the criteria" do
        expect(documents).to eq(criteria)
      end
    end

    context "when provided a object" do

      context "when the object is not nil" do

        let(:object) do
          [ Post.new ]
        end

        it "returns the objects" do
          expect(documents).to eq(object)
        end
      end

      context "when the object is nil" do

        let(:object) do
          nil
        end

        let(:criteria) do
          Preference.all_of("_id" => { "$in" => [] })
        end

        it "a criteria object" do
          expect(documents).to eq(criteria)
        end
      end
    end

    context "when no documents found in the database" do

      context "when the ids are empty" do

        it "returns an empty array" do
          expect(Person.new.preferences).to be_empty
        end
      end

      context "when the ids are incorrect" do

        let(:person) do
          Person.create!
        end

        before do
          person.preference_ids = [ BSON::ObjectId.new ]
        end

        it "returns an empty array" do
          expect(person.preferences).to be_empty
        end
      end
    end
  end
end
