require "spec_helper"

describe Mongoid::Relations::Cascading::Delete do

  let(:person) do
    Person.create
  end

  describe "#cascade" do

    context "when cascading a has one" do

      context "when the relation exists" do

        let!(:home) do
          person.create_home
        end

        before do
          person.delete
        end

        it "deletes the relation" do
          home.should be_destroyed
        end

        it "persists the deletion" do
          expect {
            home.reload
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end

      context "when the relation does not exist" do

        before do
          person.delete
        end

        it "deletes the base document" do
          person.should be_destroyed
        end
      end
    end
  end

  context "when cascading a has many" do

    context "when the relation has documents" do

      let!(:post_one) do
        person.posts.create(title: "one")
      end

      let!(:post_two) do
        person.posts.create(title: "two")
      end

      context "when the documents are in memory" do

        before do
          post_one.should_receive(:delete).never
          post_two.should_receive(:delete).never
          person.delete
        end

        it "deletes the first document" do
          post_one.should be_destroyed
        end

        it "deletes the second document" do
          post_two.should be_destroyed
        end

        it "unbinds the first document" do
          post_one.person.should be_nil
        end

        it "unbinds the second document" do
          post_two.person.should be_nil
        end

        it "removes the documents from the relation" do
          person.posts.should be_empty
        end

        it "persists the first deletion" do
          expect {
            post_one.reload
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end

        it "persists the second deletion" do
          expect {
            post_two.reload
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end
    end
  end
end
