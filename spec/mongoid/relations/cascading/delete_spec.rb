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
          expect(home).to be_destroyed
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
          expect(person).to be_destroyed
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
          expect(post_one).to receive(:delete).never
          expect(post_two).to receive(:delete).never
          person.delete
        end

        it "deletes the first document" do
          expect(post_one).to be_destroyed
        end

        it "deletes the second document" do
          expect(post_two).to be_destroyed
        end

        it "unbinds the first document" do
          expect(post_one.person).to be_nil
        end

        it "unbinds the second document" do
          expect(post_two.person).to be_nil
        end

        it "removes the documents from the relation" do
          expect(person.posts).to be_empty
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
