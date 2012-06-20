require "spec_helper"

# describe Mongoid::Fields::Internal::ForeignKeys::Array do

  # describe "#add_atomic_changes" do

    # let(:field) do
      # described_class.instantiate(
        # :vals,
        # metadata: Person.relations["preferences"],
        # type: Array,
        # default: [],
        # identity: true
      # )
    # end

    # let(:person) do
      # Person.new
    # end

    # let(:preference_one) do
      # Preference.new
    # end

    # let(:preference_two) do
      # Preference.new
    # end

    # let(:preference_three) do
      # Preference.new
    # end

    # let(:mods) do
      # {}
    # end

    # before do
      # person.preferences.concat(preference_one, preference_three)
    # end

    # context "when adding and removing" do

      # before do
        # field.add_atomic_changes(
          # person, "preference_ids", "preference_ids", mods, [ preference_three.id ], [ preference_two.id ]
        # )
      # end

      # it "adds the current to the modifications" do
        # mods["preference_ids"].should eq(
          # [ preference_one.id, preference_three.id ]
        # )
      # end
    # end
  # end

  # describe "#eval_default" do

    # let(:default) do
      # [ Moped::BSON::ObjectId.new ]
    # end

    # let(:field) do
      # described_class.instantiate(
        # :vals,
        # metadata: Person.relations["posts"],
        # type: Array,
        # default: default,
        # identity: true
      # )
    # end

    # it "dups the default value" do
      # field.eval_default(nil).should_not equal(default)
    # end

    # it "returns the correct value" do
      # field.eval_default(nil).should eq(default)
    # end
  # end

  # describe "#foreign_key?" do

    # let(:field) do
      # described_class.instantiate(
        # :vals,
        # metadata: Person.relations["posts"],
        # type: Array,
        # default: [],
        # identity: true
      # )
    # end

    # it "returns true" do
      # field.should be_foreign_key
    # end
  # end

  # describe "#serialize" do

    # context "when the array is object ids" do

      # let(:metadata) do
        # Mongoid::Relations::Metadata.new(
          # inverse_class_name: "Game",
          # name: :person,
          # relation: Mongoid::Relations::Referenced::In
        # )
      # end

      # let(:field) do
        # described_class.instantiate(
          # :vals,
          # type: Array,
          # default: [],
          # identity: true,
          # metadata: metadata
        # )
      # end

      # context "when provided nil" do

        # it "returns an empty array" do
          # field.serialize(nil).should be_empty
        # end
      # end

      # context "when provided an empty array" do

        # let(:array) do
          # []
        # end

        # it "returns an empty array" do
          # field.serialize(array).should eq(array)
        # end

        # it "returns the same instance" do
          # field.serialize(array).should equal(array)
        # end
      # end

      # context "when using object ids" do

        # let(:object_id) do
          # Moped::BSON::ObjectId.new
        # end

        # it "performs conversion on the ids if strings" do
          # field.serialize([object_id.to_s]).should eq([object_id])
        # end
      # end

      # context "when not using object ids" do

        # let(:object_id) do
          # Moped::BSON::ObjectId.new
        # end

        # before do
          # Person.field(
            # :_id,
            # type: String,
            # pre_processed: true,
            # default: ->{ Moped::BSON::ObjectId.new.to_s }
          # )
        # end

        # after do
          # Person.field(
            # :_id,
            # type: Moped::BSON::ObjectId,
            # pre_processed: true,
            # default: ->{ Moped::BSON::ObjectId.new }
          # )
        # end

        # it "does not convert" do
          # field.serialize([object_id.to_s]).should eq([object_id.to_s])
        # end
      # end
    # end
  # end
# end
