require "spec_helper"

describe Mongoid::Relations::Cascading::Nullify do

  let(:person) do
    Person.new
  end

  describe "#cascade" do

    context "when nullifying a references many" do

      let(:post) do
        stub
      end

      let(:metadata) do
        stub(
          :name => :posts,
          :foreign_key_setter => :person_id=,
          :macro => :references_many
        )
      end

      let(:strategy) do
        described_class.new(person, metadata)
      end

      context "when the documents exist" do

        before do
          person.expects(:posts).returns([ post ])
        end

        it "nullifies all documents in the relation" do
          post.expects(:person_id=).with(nil)
          post.expects(:save)
          strategy.cascade
        end
      end

      context "when no documents exist" do

        before do
          person.expects(:posts).returns([])
        end

        it "does not nullify anything" do
          post.expects(:person_id=).never
          strategy.cascade
        end
      end
    end

    context "when nullifying a many to many" do

      let(:preference) do
        stub(:id => BSON::ObjectId.new)
      end

      let(:metadata) do
        stub(
          :name => :preferences,
          :foreign_key => :preference_ids,
          :inverse_foreign_key => :person_ids,
          :macro => :references_and_referenced_in_many
        )
      end

      let(:strategy) do
        described_class.new(person, metadata)
      end

      context "when the documents exist" do

        before do
          person.expects(:preferences).returns([ preference ])
        end

        it "nullifies all documents in the relation" do
          preference.expects(:person_ids).returns([ person ])
          preference.expects(:save)
          strategy.cascade
        end
      end

      context "when no documents exist" do

        before do
          person.expects(:preferences).returns([])
        end

        it "does not nullify anything" do
          preference.expects(:person_ids).never
          strategy.cascade
        end
      end
    end
  end
end
