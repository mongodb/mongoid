require "spec_helper"

# describe Mongoid::Fields::Internal::ForeignKeys::Object do

  # describe "#foreign_key?" do

    # let(:field) do
      # described_class.instantiate(
        # :vals,
        # metadata: Person.relations["posts"],
        # type: Object,
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
          # type: Object,
          # default: nil,
          # identity: true,
          # metadata: metadata
        # )
      # end

      # context "when using object ids" do

        # let(:object_id) do
          # Moped::BSON::ObjectId.new
        # end

        # it "performs conversion on the ids if strings" do
          # field.serialize(object_id.to_s).should eq(object_id)
        # end
      # end

      # context "when not using object ids" do

        # context "when using strings" do

          # context "when provided a string" do

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
              # field.serialize(object_id.to_s).should eq(object_id.to_s)
            # end
          # end

          # context "when provided a hash" do

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

            # let(:criterion) do
              # { "$in" => [ object_id.to_s ] }
            # end

            # it "does not convert" do
              # field.serialize(criterion).should eq(
                # criterion
              # )
            # end
          # end
        # end

        # context "when using integers" do

          # context "when provided a string" do

            # before do
              # Person.field(:_id, type: Integer)
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
              # field.serialize("1").should eq(1)
            # end
          # end

          # context "when provided a hash with a string value" do

            # before do
              # Person.field(:_id, type: Integer)
            # end

            # after do
              # Person.field(
                # :_id,
                # type: Moped::BSON::ObjectId,
                # pre_processed: true,
                # default: ->{ Moped::BSON::ObjectId.new }
              # )
            # end

            # let(:criterion) do
              # { "$eq" => "1" }
            # end

            # it "does not convert" do
              # field.serialize(criterion).should eq(
                # { "$eq" => 1 }
              # )
            # end
          # end

          # context "when provided a hash with an array of string values" do

            # before do
              # Person.field(:_id, type: Integer)
            # end

            # after do
              # Person.field(
                # :_id,
                # type: Moped::BSON::ObjectId,
                # pre_processed: true,
                # default: ->{ Moped::BSON::ObjectId.new }
              # )
            # end

            # let(:criterion) do
              # { "$in" => [ "1" ] }
            # end

            # it "does not convert" do
              # field.serialize(criterion).should eq(
                # { "$in" => [ 1 ] }
              # )
            # end
          # end
        # end
      # end
    # end
  # end
# end
