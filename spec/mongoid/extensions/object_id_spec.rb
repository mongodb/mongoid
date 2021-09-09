# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Extensions::ObjectId do

  let(:object_id) do
    BSON::ObjectId.new
  end

  let(:composite_key) do
    "21-jump-street"
  end

  describe "#__evolve_object_id__" do

    it "returns self" do
      expect(object_id.__evolve_object_id__).to eq(object_id)
    end

    it "returns the same instance" do
      expect(object_id.__evolve_object_id__).to equal(object_id)
    end
  end

  describe ".evolve" do

    context "when the class is using object ids" do

      context "when provided a single object id" do

        let(:evolved) do
          BSON::ObjectId.evolve(object_id)
        end

        it "returns the object id" do
          expect(evolved).to eq(object_id)
        end
      end

      context "when provided an array of object ids" do

        let(:other_id) do
          BSON::ObjectId.new
        end

        let(:evolved) do
          BSON::ObjectId.evolve([ object_id, other_id ])
        end

        it "returns the array of object ids" do
          expect(evolved).to eq([ object_id, other_id ])
        end
      end

      context "when provided a single string" do

        context "when the string is a valid object id" do

          let(:evolved) do
            BSON::ObjectId.evolve(object_id.to_s)
          end

          it "evolves to an object id" do
            expect(evolved).to eq(object_id)
          end
        end

        context "when the string is not a valid object id" do

          it "returns the key" do
            expect(BSON::ObjectId.evolve(composite_key)).to eq(
              composite_key
            )
          end
        end

        context "when the string is empty" do

          let(:evolved) do
            BSON::ObjectId.evolve("")
          end

          it "evolves to an empty string" do
            expect(evolved).to be_empty
          end
        end
      end

      context "when provided an array" do

        context "when array key of nils" do

          let(:evolved) do
            BSON::ObjectId.evolve([ nil, nil ])
          end

          it "returns the array with nils" do
            expect(evolved).to eq([ nil, nil ])
          end
        end

        context "when the array key is empty strings" do

          let(:evolved) do
            BSON::ObjectId.evolve([ "", "" ])
          end

          it "returns the array with empty strings" do
            expect(evolved).to eq([ "", "" ])
          end
        end

        context "when the array key is full of strings" do

          context "when the strings are valid object ids" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:evolved) do
              BSON::ObjectId.evolve([ object_id.to_s, other_id.to_s ])
            end

            it "evolves to an array of object ids" do
              expect(evolved).to eq([ object_id, other_id ])
            end
          end

          context "when the strings are not valid object ids" do

            let(:other_key) do
              "hawaii-five-o"
            end

            let(:evolved) do
              BSON::ObjectId.evolve([ composite_key, other_key ])
            end

            it "returns the key" do
              expect(BSON::ObjectId.evolve(composite_key)).to eq(
                composite_key
              )
            end
          end
        end
      end

      context "when provided a hash" do

        context "when the hash key is _id" do

          context "when the value is an object id" do

            let(:hash) do
              { _id: object_id }
            end

            let(:evolved) do
              BSON::ObjectId.evolve(hash)
            end

            it "returns the hash" do
              expect(evolved).to eq(hash)
            end
          end

          context "when the value is an array of object ids" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:hash) do
              { _id: [ object_id, other_id ] }
            end

            let(:evolved) do
              BSON::ObjectId.evolve(hash)
            end

            it "returns the hash" do
              expect(evolved).to eq(hash)
            end
          end

          context "when the value is a string" do

            let(:hash) do
              { _id: object_id.to_s }
            end

            let(:evolved) do
              BSON::ObjectId.evolve(hash)
            end

            it "returns the hash with evolved value" do
              expect(evolved).to eq({ _id: object_id })
            end
          end

          context "when the value is an array of strings" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:hash) do
              { _id: [ object_id.to_s, other_id.to_s ] }
            end

            let(:evolved) do
              BSON::ObjectId.evolve(hash)
            end

            it "returns the hash with evolved values" do
              expect(evolved).to eq({ _id: [ object_id, other_id ] })
            end
          end
        end

        context "when the hash key is id" do

          context "when the value is an object id" do

            let(:hash) do
              { id: object_id }
            end

            let(:evolved) do
              BSON::ObjectId.evolve(hash)
            end

            it "returns the hash" do
              expect(evolved).to eq(hash)
            end
          end

          context "when the value is an array of object ids" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:hash) do
              { id: [ object_id, other_id ] }
            end

            let(:evolved) do
              BSON::ObjectId.evolve(hash)
            end

            it "returns the hash" do
              expect(evolved).to eq(hash)
            end
          end

          context "when the value is a string" do

            let(:hash) do
              { id: object_id.to_s }
            end

            let(:evolved) do
              BSON::ObjectId.evolve(hash)
            end

            it "returns the hash with evolved value" do
              expect(evolved).to eq({ id: object_id })
            end
          end

          context "when the value is an array of strings" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:hash) do
              { id: [ object_id.to_s, other_id.to_s ] }
            end

            let(:evolved) do
              BSON::ObjectId.evolve(hash)
            end

            it "returns the hash with evolved values" do
              expect(evolved).to eq({ id: [ object_id, other_id ] })
            end
          end
        end

        context "when the hash key is not an id" do

          context "when the value is a string" do

            let(:hash) do
              { key: composite_key }
            end

            let(:evolved) do
              BSON::ObjectId.evolve(hash)
            end

            it "returns the hash" do
              expect(evolved).to eq(hash)
            end
          end

          context "when the value is an array of strings" do

            let(:hash) do
              { key: [ composite_key ] }
            end

            let(:evolved) do
              BSON::ObjectId.evolve(hash)
            end

            it "returns the hash" do
              expect(evolved).to eq(hash)
            end
          end
        end
      end
    end
  end

  describe ".mongoize" do

    context "when the class is using object ids" do

      context "when provided a single object id" do

        let(:mongoized) do
          BSON::ObjectId.mongoize(object_id)
        end

        it "returns the object id" do
          expect(mongoized).to eq(object_id)
        end
      end

      context "when provided an array of object ids" do

        let(:other_id) do
          BSON::ObjectId.new
        end

        let(:mongoized) do
          BSON::ObjectId.mongoize([ object_id, other_id ])
        end

        it "returns the array of object ids" do
          expect(mongoized).to eq([ object_id, other_id ])
        end
      end

      context "when provided a single string" do

        context "when the string is a valid object id" do

          let(:mongoized) do
            BSON::ObjectId.mongoize(object_id.to_s)
          end

          it "mongoizes to an object id" do
            expect(mongoized).to eq(object_id)
          end
        end

        context "when the string is not a valid object id" do

          it "returns the key" do
            expect(BSON::ObjectId.mongoize(composite_key)).to eq(
              composite_key
            )
          end
        end

        context "when the string is empty" do

          let(:mongoized) do
            BSON::ObjectId.mongoize("")
          end

          it "mongoizes to nil" do
            expect(mongoized).to be_nil
          end
        end
      end

      context "when provided an array" do

        context "when array key of nils" do

          let(:mongoized) do
            BSON::ObjectId.mongoize([ nil, nil ])
          end

          it "returns an empty array" do
            expect(mongoized).to be_empty
          end
        end

        context "when the array key is empty strings" do

          let(:mongoized) do
            BSON::ObjectId.mongoize([ "", "" ])
          end

          it "returns an empty array" do
            expect(mongoized).to be_empty
          end
        end

        context "when the array key is full of strings" do

          context "when the strings are valid object ids" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize([ object_id.to_s, other_id.to_s ])
            end

            it "mongoizes to an array of object ids" do
              expect(mongoized).to eq([ object_id, other_id ])
            end
          end

          context "when the strings are not valid object ids" do

            let(:other_key) do
              "hawaii-five-o"
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize([ composite_key, other_key ])
            end

            it "returns the key" do
              expect(BSON::ObjectId.mongoize(composite_key)).to eq(
                composite_key
              )
            end
          end
        end
      end

      context "when provided a hash" do

        context "when the hash key is _id" do

          context "when the value is an object id" do

            let(:hash) do
              { _id: object_id }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash" do
              expect(mongoized).to eq(hash)
            end
          end

          context "when the value is an array of object ids" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:hash) do
              { _id: [ object_id, other_id ] }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash" do
              expect(mongoized).to eq(hash)
            end
          end

          context "when the value is a string" do

            let(:hash) do
              { _id: object_id.to_s }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash with mongoized value" do
              expect(mongoized).to eq({ _id: object_id })
            end
          end

          context "when the value is an array of strings" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:hash) do
              { _id: [ object_id.to_s, other_id.to_s ] }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash with mongoized values" do
              expect(mongoized).to eq({ _id: [ object_id, other_id ] })
            end
          end
        end

        context "when the hash key is id" do

          context "when the value is an object id" do

            let(:hash) do
              { id: object_id }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash" do
              expect(mongoized).to eq(hash)
            end
          end

          context "when the value is an array of object ids" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:hash) do
              { id: [ object_id, other_id ] }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash" do
              expect(mongoized).to eq(hash)
            end
          end

          context "when the value is a string" do

            let(:hash) do
              { id: object_id.to_s }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash with mongoized value" do
              expect(mongoized).to eq({ id: object_id })
            end
          end

          context "when the value is an array of strings" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:hash) do
              { id: [ object_id.to_s, other_id.to_s ] }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash with mongoized values" do
              expect(mongoized).to eq({ id: [ object_id, other_id ] })
            end
          end
        end

        context "when the hash key is not an id" do

          context "when the value is a string" do

            let(:hash) do
              { key: composite_key }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash" do
              expect(mongoized).to eq(hash)
            end
          end

          context "when the value is an array of strings" do

            let(:hash) do
              { key: [ composite_key ] }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash" do
              expect(mongoized).to eq(hash)
            end
          end
        end
      end
    end
  end

  describe ".mongoize" do

    context "when the class is using object ids" do

      context "when provided a single object id" do

        let(:mongoized) do
          BSON::ObjectId.mongoize(object_id)
        end

        it "returns the object id" do
          expect(mongoized).to eq(object_id)
        end
      end

      context "when provided an array of object ids" do

        let(:other_id) do
          BSON::ObjectId.new
        end

        let(:mongoized) do
          BSON::ObjectId.mongoize([ object_id, other_id ])
        end

        it "returns the array of object ids" do
          expect(mongoized).to eq([ object_id, other_id ])
        end
      end

      context "when provided a single string" do

        context "when the string is a valid object id" do

          let(:mongoized) do
            BSON::ObjectId.mongoize(object_id.to_s)
          end

          it "mongoizes to an object id" do
            expect(mongoized).to eq(object_id)
          end
        end

        context "when the string is not a valid object id" do

          it "returns the key" do
            expect(BSON::ObjectId.mongoize(composite_key)).to eq(
              composite_key
            )
          end
        end

        context "when the string is empty" do

          let(:mongoized) do
            BSON::ObjectId.mongoize("")
          end

          it "mongoizes to nil" do
            expect(mongoized).to be_nil
          end
        end
      end

      context "when provided an array" do

        context "when array key of nils" do

          let(:mongoized) do
            BSON::ObjectId.mongoize([ nil, nil ])
          end

          it "returns an empty array" do
            expect(mongoized).to be_empty
          end
        end

        context "when the array key is empty strings" do

          let(:mongoized) do
            BSON::ObjectId.mongoize([ "", "" ])
          end

          it "returns an empty array" do
            expect(mongoized).to be_empty
          end
        end

        context "when the array key is full of strings" do

          context "when the strings are valid object ids" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize([ object_id.to_s, other_id.to_s ])
            end

            it "mongoizes to an array of object ids" do
              expect(mongoized).to eq([ object_id, other_id ])
            end
          end

          context "when the strings are not valid object ids" do

            let(:other_key) do
              "hawaii-five-o"
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize([ composite_key, other_key ])
            end

            it "returns the key" do
              expect(BSON::ObjectId.mongoize(composite_key)).to eq(
                composite_key
              )
            end
          end
        end
      end

      context "when provided a hash" do

        context "when the hash key is _id" do

          context "when the value is an object id" do

            let(:hash) do
              { _id: object_id }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash" do
              expect(mongoized).to eq(hash)
            end
          end

          context "when the value is an array of object ids" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:hash) do
              { _id: [ object_id, other_id ] }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash" do
              expect(mongoized).to eq(hash)
            end
          end

          context "when the value is a string" do

            let(:hash) do
              { _id: object_id.to_s }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash with mongoized value" do
              expect(mongoized).to eq({ _id: object_id })
            end
          end

          context "when the value is an array of strings" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:hash) do
              { _id: [ object_id.to_s, other_id.to_s ] }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash with mongoized values" do
              expect(mongoized).to eq({ _id: [ object_id, other_id ] })
            end
          end
        end

        context "when the hash key is id" do

          context "when the value is an object id" do

            let(:hash) do
              { id: object_id }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash" do
              expect(mongoized).to eq(hash)
            end
          end

          context "when the value is an array of object ids" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:hash) do
              { id: [ object_id, other_id ] }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash" do
              expect(mongoized).to eq(hash)
            end
          end

          context "when the value is a string" do

            let(:hash) do
              { id: object_id.to_s }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash with mongoized value" do
              expect(mongoized).to eq({ id: object_id })
            end
          end

          context "when the value is an array of strings" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:hash) do
              { id: [ object_id.to_s, other_id.to_s ] }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash with mongoized values" do
              expect(mongoized).to eq({ id: [ object_id, other_id ] })
            end
          end
        end

        context "when the hash key is not an id" do

          context "when the value is a string" do

            let(:hash) do
              { key: composite_key }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash" do
              expect(mongoized).to eq(hash)
            end
          end

          context "when the value is an array of strings" do

            let(:hash) do
              { key: [ composite_key ] }
            end

            let(:mongoized) do
              BSON::ObjectId.mongoize(hash)
            end

            it "returns the hash" do
              expect(mongoized).to eq(hash)
            end
          end
        end
      end
    end
  end

  describe "#__mongoize_object_id__" do

    it "returns self" do
      expect(object_id.__mongoize_object_id__).to eq(object_id)
    end

    it "returns the same instance" do
      expect(object_id.__mongoize_object_id__).to equal(object_id)
    end
  end
end
