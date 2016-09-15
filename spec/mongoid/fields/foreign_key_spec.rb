require "spec_helper"

describe Mongoid::Fields::ForeignKey do

  describe "#add_atomic_changes" do

    let(:field) do
      described_class.new(
        :vals,
        metadata: Person.relations["preferences"],
        type: Array,
        default: [],
        identity: true
      )
    end

    let(:person) do
      Person.new
    end

    let(:preference_one) do
      Preference.new
    end

    let(:preference_two) do
      Preference.new
    end

    let(:preference_three) do
      Preference.new
    end

    let(:mods) do
      {}
    end

    before do
      person.preferences.concat([ preference_one, preference_three ])
    end

    context "when adding and removing" do

      before do
        field.add_atomic_changes(
          person,
          "preference_ids",
          "preference_ids",
          mods,
          [ preference_three.id ],
          [ preference_two.id ]
        )
      end

      it "adds the current to the modifications" do
        expect(mods["preference_ids"]).to eq(
          [ preference_one.id, preference_three.id ]
        )
      end
    end
  end

  describe "#eval_default" do

    let(:default) do
      [ BSON::ObjectId.new ]
    end

    let(:field) do
      described_class.new(
        :vals,
        metadata: Person.relations["posts"],
        type: Array,
        default: default,
        identity: true
      )
    end

    it "dups the default value" do
      expect(field.eval_default(Person.new)).to_not equal(default)
    end

    it "returns the correct value" do
      expect(field.eval_default(Person.new)).to eq(default)
    end
  end

  describe "#foreign_key?" do

    let(:field) do
      described_class.new(
        :vals,
        metadata: Person.relations["posts"],
        type: Array,
        default: [],
        identity: true
      )
    end

    it "returns true" do
      expect(field).to be_foreign_key
    end
  end

  describe "#evolve" do

    let(:metadata) do
      Person.reflect_on_association(:preferences)
    end

    context "when provided a document" do

      let(:field) do
        described_class.new(:person_id, type: Object, metadata: metadata)
      end

      let(:game) do
        Game.new
      end

      let(:evolved) do
        field.evolve(game)
      end

      it "returns the id for the document" do
        expect(evolved).to eq(game.id)
      end
    end

    context "when the type is an array" do

      let(:field) do
        described_class.new(:preference_ids, type: Array, default: [], metadata: metadata)
      end

      context "when providing a single value" do

        context "when the value is an id string" do

          let(:id) do
            BSON::ObjectId.new
          end

          let(:evolved) do
            field.evolve(id.to_s)
          end

          it "converts the value to an object id" do
            expect(evolved).to eq(id)
          end
        end

        context "when the value is a normal string" do

          let(:evolved) do
            field.evolve("testing")
          end

          it "does not convert the value" do
            expect(evolved).to eq("testing")
          end
        end

        context "when the value is an empty string" do

          let(:evolved) do
            field.evolve("")
          end

          it "does not convert the value" do
            expect(evolved).to be_empty
          end
        end
      end

      context "when providing an array" do

        context "when the values are id strings" do

          context "when the relation stores ids as object ids" do

            let(:id_one) do
              BSON::ObjectId.new
            end

            let(:id_two) do
              BSON::ObjectId.new
            end

            let(:evolved) do
              field.evolve([ id_one.to_s, id_two.to_s ])
            end

            it "converts the value to an object id" do
              expect(evolved).to eq([ id_one, id_two ])
            end
          end

          context "when the relation stores ids as strings" do

            let!(:metadata) do
              Agent.reflect_on_association(:accounts)
            end

            let!(:field) do
              described_class.new(:account_ids, type: Array, default: [], metadata: metadata)
            end

            let(:id_one) do
              BSON::ObjectId.new.to_s
            end

            let(:id_two) do
              BSON::ObjectId.new.to_s
            end

            let(:evolved) do
              field.evolve([ id_one, id_two ])
            end

            it "does not convert the values to object ids" do
              expect(evolved).to eq([ id_one, id_two ])
            end
          end
        end

        context "when the values are normal strings" do

          let(:evolved) do
            field.evolve([ "testing" ])
          end

          it "does not convert the value" do
            expect(evolved).to eq([ "testing" ])
          end
        end

        context "when the values are empty strings" do

          let(:evolved) do
            field.evolve([ "" ])
          end

          it "does not convert the value" do
            expect(evolved).to eq([ "" ])
          end
        end

        context "when the values are nils" do

          let(:evolved) do
            field.evolve([ nil ])
          end

          it "does not convert the value" do
            expect(evolved).to eq([ nil ])
          end
        end
      end
    end

    context "when the type is an object" do

      let(:metadata) do
        Game.reflect_on_association(:person)
      end

      let(:field) do
        described_class.new(:person_id, type: Object, metadata: metadata)
      end

      context "when providing a single value" do

        context "when the relation stores object ids" do

          context "when the value is an id string" do

            let(:id) do
              BSON::ObjectId.new
            end

            let(:evolved) do
              field.evolve(id.to_s)
            end

            it "converts the value to an object id" do
              expect(evolved).to eq(id)
            end
          end

          context "when the value is a normal string" do

            let(:evolved) do
              field.evolve("testing")
            end

            it "does not convert the value" do
              expect(evolved).to eq("testing")
            end
          end

          context "when the value is an empty string" do

            let(:evolved) do
              field.evolve("")
            end

            it "does not convert the value" do
              expect(evolved).to be_empty
            end
          end
        end

        context "when the relation stores string ids" do

          let(:metadata) do
            Comment.reflect_on_association(:account)
          end

          let(:field) do
            described_class.new(:person_id, type: Object, metadata: metadata)
          end

          context "when the value is an id string" do

            let(:id) do
              BSON::ObjectId.new
            end

            let(:evolved) do
              field.evolve(id.to_s)
            end

            it "does not convert the value to an object id" do
              expect(evolved).to eq(id.to_s)
            end
          end

          context "when the value is a normal string" do

            let(:evolved) do
              field.evolve("testing")
            end

            it "does not convert the value" do
              expect(evolved).to eq("testing")
            end
          end

          context "when the value is an empty string" do

            let(:evolved) do
              field.evolve("")
            end

            it "does not convert the value" do
              expect(evolved).to be_empty
            end
          end
        end
      end

      context "when providing an array" do

        context "when the values are id strings" do

          context "when the relation stores ids as object ids" do

            let(:id_one) do
              BSON::ObjectId.new
            end

            let(:id_two) do
              BSON::ObjectId.new
            end

            let(:evolved) do
              field.evolve([ id_one.to_s, id_two.to_s ])
            end

            it "converts the value to an object id" do
              expect(evolved).to eq([ id_one, id_two ])
            end
          end

          context "when the relation stores ids as strings" do

            let(:metadata) do
              Comment.reflect_on_association(:account)
            end

            let(:field) do
              described_class.new(:person_id, type: Object, metadata: metadata)
            end

            let(:id_one) do
              BSON::ObjectId.new.to_s
            end

            let(:id_two) do
              BSON::ObjectId.new.to_s
            end

            let(:evolved) do
              field.evolve([ id_one, id_two ])
            end

            it "does not convert the values to object ids" do
              expect(evolved).to eq([ id_one, id_two ])
            end
          end
        end

        context "when the values are normal strings" do

          let(:evolved) do
            field.evolve([ "testing" ])
          end

          it "does not convert the value" do
            expect(evolved).to eq([ "testing" ])
          end
        end

        context "when the values are empty strings" do

          let(:evolved) do
            field.evolve([ "" ])
          end

          it "does not convert the value" do
            expect(evolved).to eq([ "" ])
          end
        end

        context "when the values are nils" do

          let(:evolved) do
            field.evolve([ nil ])
          end

          it "does not convert the value" do
            expect(evolved).to eq([ nil ])
          end
        end
      end
    end

    context "when the metadata is polymoprhic" do

      let(:metadata) do
        Agent.reflect_on_association(:names)
      end

      let(:field) do
        described_class.new(:nameable_id, type: Object, metadata: metadata)
      end

      let(:value) do
        BSON::ObjectId.new().to_s
      end

      let(:evolved) do
        field.evolve(value)
      end

      it "does not change the foreign key" do
        expect(evolved).to be(value)
      end
    end
  end

  describe "#lazy?" do

    context "when the key is resizable" do

      let(:field) do
        described_class.new(:test, type: Array, overwrite: true)
      end

      it "returns true" do
        expect(field).to be_lazy
      end
    end

    context "when the key is not resizable" do

      let(:field) do
        described_class.new(:test, type: BSON::ObjectId, overwrite: true)
      end

      it "returns false" do
        expect(field).to_not be_lazy
      end
    end
  end

  describe "#mongoize" do

    context "when the type is array" do

      context "when the array is object ids" do

        let(:metadata) do
          Mongoid::Relations::Metadata.new(
            inverse_class_name: "Game",
            name: :person,
            relation: Mongoid::Relations::Referenced::In
          )
        end

        let(:field) do
          described_class.new(
            :vals,
            type: Array,
            default: [],
            identity: true,
            metadata: metadata,
            overwrite: true
          )
        end

        context "when provided nil" do

          it "returns an empty array" do
            expect(field.mongoize(nil)).to be_empty
          end
        end

        context "when provided an empty array" do

          let(:array) do
            []
          end

          it "returns an empty array" do
            expect(field.mongoize(array)).to eq(array)
          end

          it "returns the same instance" do
            expect(field.mongoize(array)).to equal(array)
          end
        end

        context "when using object ids" do

          let(:object_id) do
            BSON::ObjectId.new
          end

          it "performs conversion on the ids if strings" do
            expect(field.mongoize([object_id.to_s])).to eq([object_id])
          end
        end

        context "when not using object ids" do

          let(:object_id) do
            BSON::ObjectId.new
          end

          before do
            Person.field(
              :_id,
              type: String,
              pre_processed: true,
              default: ->{ BSON::ObjectId.new.to_s },
              overwrite: true
            )
          end

          after do
            Person.field(
              :_id,
              type: BSON::ObjectId,
              pre_processed: true,
              default: ->{ BSON::ObjectId.new },
              overwrite: true
            )
          end

          it "does not convert" do
            expect(field.mongoize([object_id.to_s])).to eq([object_id.to_s])
          end
        end
      end
    end

    context "when the type is object" do

      context "when the array is object ids" do

        let(:metadata) do
          Mongoid::Relations::Metadata.new(
            inverse_class_name: "Game",
            name: :person,
            relation: Mongoid::Relations::Referenced::In
          )
        end

        let(:field) do
          described_class.new(
            :vals,
            type: Object,
            default: nil,
            identity: true,
            metadata: metadata,
            overwrite: true
          )
        end

        context "when using object ids" do

          let(:object_id) do
            BSON::ObjectId.new
          end

          it "performs conversion on the ids if strings" do
            expect(field.mongoize(object_id.to_s)).to eq(object_id)
          end
        end

        context "when not using object ids" do

          context "when using strings" do

            context "when provided a string" do

              let(:object_id) do
                BSON::ObjectId.new
              end

              before do
                Person.field(
                  :_id,
                  type: String,
                  pre_processed: true,
                  default: ->{ BSON::ObjectId.new.to_s },
                  overwrite: true
                )
              end

              after do
                Person.field(
                  :_id,
                  type: BSON::ObjectId,
                  pre_processed: true,
                  default: ->{ BSON::ObjectId.new },
                  overwrite: true
                )
              end

              it "does not convert" do
                expect(field.mongoize(object_id.to_s)).to eq(object_id.to_s)
              end
            end
          end

          context "when using integers" do

            context "when provided a string" do

              before do
                Person.field(:_id, type: Integer, overwrite: true)
              end

              after do
                Person.field(
                  :_id,
                  type: BSON::ObjectId,
                  pre_processed: true,
                  default: ->{ BSON::ObjectId.new },
                  overwrite: true
                )
              end

              it "converts the string to an integer" do
                expect(field.mongoize("1")).to eq(1)
              end
            end
          end
        end
      end
    end
  end

  describe "#resizable" do

    context "when the type is an array" do

      let(:field) do
        described_class.new(:vals, type: Array, default: [])
      end

      it "returns true" do
        expect(field).to be_resizable
      end
    end

    context "when the type is an object" do

      let(:field) do
        described_class.new(:vals, type: Object, default: [])
      end

      it "returns false" do
        expect(field).to_not be_resizable
      end
    end
  end

  context "when the foreign key points is a many to many" do

    context "when the related document stores non object ids" do

      let(:agent) do
        Agent.new(account_ids: [ true, false, 1, 2 ])
      end

      it "casts the ids on the initial set" do
        expect(agent.account_ids).to eq([ "true", "false", "1", "2" ])
      end
    end
  end
end
