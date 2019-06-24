# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Association::Referenced::HasMany::Buildable do

  let(:base) do
    double
  end

  describe "#build" do

    let(:documents) do
      association.build(base, object)
    end

    let(:options) do
      {}
    end

    let(:association) do
      Mongoid::Association::Referenced::HasMany.new(Person, :posts, options)
    end

    context "when provided an id" do

      let(:object) do
        BSON::ObjectId.new
      end

      let(:criteria) do
        Post.where(association.foreign_key => object)
      end

      it "returns the criteria" do
        expect(documents).to eq(criteria)
      end
    end

    context "when order is specified" do

      let(:options) do
        {
          order: :rating.asc,
        }
      end

      let(:object) do
        BSON::ObjectId.new
      end

      let(:criteria) do
        Post.where(association.foreign_key => object).order_by(options[:order])
      end

      it "adds the ordering to the criteria" do
        expect(documents).to eq(criteria)
      end
    end

    context "when the relation is polymorphic" do

      let(:options) do
        {
          as: :ratable
        }
      end

      let(:object) do
        BSON::ObjectId.new
      end

      let(:base) do
        Rating.new
      end

      let(:criteria) do
        Post.where(association.foreign_key => object, 'ratable_type' => 'Rating')
      end

      it "adds the type to the criteria" do
        expect(documents).to eq(criteria)
      end
    end

    context "when provided a object" do

      let(:object) do
        [ Person.new ]
      end

      it "returns the object" do
        expect(documents).to eq(object)
      end
    end

    context "when no documents found in the database" do

      context "when the ids are empty" do

        let(:object) do
          [ nil ]
        end

        it "returns an empty array" do
          expect(documents).to be_empty
        end

        context "during initialization" do

          it "returns an empty array" do
            Person.new do |p|
              expect(p.posts).to be_empty
              expect(p.posts._association).to_not be_nil
            end
          end
        end
      end
    end
  end
end
