# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Atomic::Modifiers do

  let(:modifiers) do
    described_class.new
  end

  describe "#push_conflict?" do
    let(:result) { modifiers.send(:push_conflict?, field) }

    context 'for embeds many subdocument' do
      context 'when another field on subdocument is being set' do
        before do
          modifiers.set('foo.0.a' => 1)
        end

        let(:field) { 'foo' }

        it 'does not conflict' do
          pending 'https://jira.mongodb.org/browse/MONGOID-4982'

          result.should be false
        end
      end
    end
  end

  describe "#add_to_set" do

    context "when the unique adds are empty" do

      before do
        modifiers.add_to_set({})
      end

      it "does not contain any operations" do
        expect(modifiers).to eq({})
      end
    end

    context "when the adds are not empty" do

      let(:adds) do
        { "preference_ids" => [ "one", "two" ] }
      end

      context "when adding a single field" do

        before do
          modifiers.add_to_set(adds)
        end

        it "adds the add to set with each modifiers" do
          expect(modifiers).to eq({
            "$addToSet" => { "preference_ids" => { "$each" => [ "one", "two" ] }}
          })
        end
      end

      context "when adding to an existing field" do

        let(:adds_two) do
          { "preference_ids" => [ "three" ] }
        end

        before do
          modifiers.add_to_set(adds)
          modifiers.add_to_set(adds_two)
        end

        it "adds the add to set with each modifiers" do
          expect(modifiers).to eq({
            "$addToSet" =>
              { "preference_ids" =>
                { "$each" => [ "one", "two", "three" ] }
              }
          })
        end
      end
    end
  end

  describe "#pull" do

    context "when the pulls are empty" do

      before do
        modifiers.pull({})
      end

      it "does not contain any pull operations" do
        expect(modifiers).to eq({})
      end
    end

    context "when no conflicting modifications are present" do

      context "when adding a single pull" do

        let(:pulls) do
          { "addresses" => { "_id" => { "$in" => [ "one" ]}} }
        end

        before do
          modifiers.pull(pulls)
        end

        it "adds the push all modifiers" do
          expect(modifiers).to eq(
            { "$pull" => { "addresses" => { "_id" => { "$in" => [ "one" ]}}}}
          )
        end
      end

      context "when adding to an existing pull" do

        let(:pull_one) do
          { "addresses" => { "_id" => { "$in" => [ "one" ]}} }
        end

        let(:pull_two) do
          { "addresses" => { "_id" => { "$in" => [ "two" ]}} }
        end

        before do
          modifiers.pull(pull_one)
          modifiers.pull(pull_two)
        end

        it "overwrites the previous pulls" do
          expect(modifiers).to eq(
            { "$pull" => { "addresses" => { "_id" => { "$in" => [ "two" ]}}}}
          )
        end
      end
    end
  end

  describe "#pull_all" do

    context "when the pulls are empty" do

      before do
        modifiers.pull_all({})
      end

      it "does not contain any pull operations" do
        expect(modifiers).to eq({})
      end
    end

    context "when no conflicting modifications are present" do

      context "when adding a single pull" do

        let(:pulls) do
          { "addresses" => [{ "_id" => "one" }] }
        end

        before do
          modifiers.pull_all(pulls)
        end

        it "adds the push all modifiers" do
          expect(modifiers).to eq(
            { "$pullAll" =>
              { "addresses" => [
                  { "_id" => "one" }
                ]
              }
            }
          )
        end
      end

      context "when adding to an existing pull" do

        let(:pull_one) do
          { "addresses" => [{ "street" => "Hobrechtstr." }] }
        end

        let(:pull_two) do
          { "addresses" => [{ "street" => "Pflugerstr." }] }
        end

        before do
          modifiers.pull_all(pull_one)
          modifiers.pull_all(pull_two)
        end

        it "adds the pull all modifiers" do
          expect(modifiers).to eq(
            { "$pullAll" =>
              { "addresses" => [
                  { "street" => "Hobrechtstr." },
                  { "street" => "Pflugerstr." }
                ]
              }
            }
          )
        end
      end
    end
  end

  describe "#push" do

    context "when the pushes are empty" do

      before do
        modifiers.push({})
      end

      it "does not contain any push operations" do
        expect(modifiers).to eq({})
      end
    end

    context "when no conflicting modification is present" do

      context "when adding a single push" do

        let(:pushes) do
          { "addresses" => { "street" => "Oxford St" } }
        end

        before do
          modifiers.push(pushes)
        end

        it "adds the push all modifiers" do
          expect(modifiers).to eq(
            { "$push" =>
              { "addresses" => { '$each' => [
                  { "street" => "Oxford St" }
                ] }
              }
            }
          )
        end
      end

      context "when adding to an existing push" do

        let(:push_one) do
          { "addresses" => { "street" => "Hobrechtstr." } }
        end

        let(:push_two) do
          { "addresses" => { "street" => "Pflugerstr." } }
        end

        before do
          modifiers.push(push_one)
          modifiers.push(push_two)
        end

        it "adds the push all modifiers" do
          expect(modifiers).to eq(
            { "$push" =>
              { "addresses" => { '$each' => [
                  { "street" => "Hobrechtstr." },
                  { "street" => "Pflugerstr." }
                ] }
              }
            }
          )
        end
      end
    end

    context "when a conflicting modification exists" do

      context "when the conflicting modification is a set" do

        let(:sets) do
          { "addresses.0.street" => "Bond" }
        end

        let(:pushes) do
          { "addresses" => { "street" => "Oxford St" } }
        end

        before do
          modifiers.set(sets)
          modifiers.push(pushes)
        end

        it "adds the push all modifiers to the conflicts hash" do
          expect(modifiers).to eq(
            { "$set" => { "addresses.0.street" => "Bond" },
              conflicts: { "$push" =>
                { "addresses" => { '$each' => [
                    { "street" => "Oxford St" }
                  ] }
                }
              }
            }
          )
        end
      end

      context "when the conflicting modification is a pull" do

        let(:pulls) do
          { "addresses" => { "street" => "Bond St" } }
        end

        let(:pushes) do
          { "addresses" => { "street" => "Oxford St" } }
        end

        before do
          modifiers.pull_all(pulls)
          modifiers.push(pushes)
        end

        it "adds the push all modifiers to the conflicts hash" do
          expect(modifiers).to eq(
            { "$pullAll" => {
              "addresses" => { "street" => "Bond St" }},
              conflicts: { "$push" =>
                { "addresses" => { '$each' => [
                    { "street" => "Oxford St" }
                  ]}
                }
              }
            }
          )
        end
      end

      context "when the conflicting modification is a push" do

        let(:nested) do
          { "addresses.0.locations" => { "street" => "Bond St" } }
        end

        let(:pushes) do
          { "addresses" => { "street" => "Oxford St" } }
        end

        before do
          modifiers.push(nested)
          modifiers.push(pushes)
        end

        it "adds the push all modifiers to the conflicts hash" do
          expect(modifiers).to eq(
            { "$push" => {
              "addresses.0.locations" => { '$each' => [{ "street" => "Bond St" }] } },
              conflicts: { "$push" =>
                { "addresses" => { '$each' => [
                    { "street" => "Oxford St" }
                  ] }
                }
              }
            }
          )
        end
      end
    end

    context 'when there is another operation on a sibling of a key which is nested' do

      let(:first_op) do
        { "addresses.0.name" => 'test' }
      end

      let(:push_op) do
        { "addresses.0.locations" => { "street" => "Oxford St" } }
      end

      before do
        modifiers.set(first_op)
        modifiers.push(push_op)
      end

      it "does not conflict and adds push to top level" do
        pending 'https://jira.mongodb.org/browse/MONGOID-4982'

        modifiers.should == {
          '$set' => { "addresses.0.name" => 'test' },
          '$push' => {"addresses.0.locations" => {'$each' => [
            { "street" => "Oxford St" },
          ]}},
        }
      end
    end
  end

  describe "#set" do

    describe "when adding to the root level" do

      context "when no conflicting mods exist" do

        context "when the sets have values" do

          let(:sets) do
            { "title" => "Sir" }
          end

          before do
            modifiers.set(sets)
          end

          it "adds the sets to the modifiers" do
            expect(modifiers).to eq({ "$set" => { "title" => "Sir" } })
          end
        end

        context "when the sets contain an id" do

          let(:sets) do
            { "_id" => BSON::ObjectId.new }
          end

          before do
            modifiers.set(sets)
          end

          it "does not include the id sets" do
            expect(modifiers).to eq({})
          end
        end

        context "when the sets are empty" do

          before do
            modifiers.set({})
          end

          it "does not contain set operations" do
            expect(modifiers).to eq({})
          end
        end
      end

      context "when a conflicting modification exists" do

        let(:pulls) do
          { "addresses" => [{ "_id" => "one" }] }
        end

        let(:sets) do
          { "addresses.0.title" => "Sir" }
        end

        before do
          modifiers.pull_all(pulls)
          modifiers.set(sets)
        end

        it "adds the set modifiers to the conflicts hash" do
          expect(modifiers).to eq(
            { "$pullAll" =>
              { "addresses" => [
                  { "_id" => "one" }
                ]
              },
              conflicts:
                { "$set" => { "addresses.0.title" => "Sir" }}
            }
          )
        end
      end
    end
  end

  describe "#unset" do

    describe "when adding to the root level" do

      context "when the unsets have values" do

        let(:unsets) do
          [ "addresses" ]
        end

        before do
          modifiers.unset(unsets)
        end

        it "adds the unsets to the modifiers" do
          expect(modifiers).to eq({ "$unset" => { "addresses" => true } })
        end
      end

      context "when the unsets are empty" do

        before do
          modifiers.unset([])
        end

        it "does not contain unset operations" do
          expect(modifiers).to eq({})
        end
      end
    end
  end
end
