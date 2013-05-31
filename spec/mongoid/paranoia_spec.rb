require "spec_helper"

describe Mongoid::Paranoia do

  describe ".scoped" do

    it "returns a scoped criteria" do
      ParanoidPost.scoped.selector.should eq({ "deleted_at" => nil })
    end
  end

  describe ".deleted" do

    context "when called on a root document" do

      let(:post) do
        ParanoidPost.create(title: "testing")
      end

      before do
        post.destroy
      end

      let(:deleted) do
        ParanoidPost.deleted
      end

      it "returns the deleted documents" do
        deleted.should eq([ post ])
      end
    end

    context "when called on an embedded document" do

      let(:person) do
        Person.create
      end

      let(:phone) do
        person.paranoid_phones.create
      end

      before do
        phone.destroy
        person.reload
      end

      it "returns the deleted documents" do
        person.paranoid_phones.deleted.should eq([ phone ])
      end

      it "returns the correct count" do
        person.paranoid_phones.deleted.count.should eq(1)
      end
    end
  end

  describe "#destroy!" do

    context "when the document is a root" do

      let(:post) do
        ParanoidPost.create(title: "testing")
      end

      before do
        post.destroy!
      end

      let(:raw) do
        ParanoidPost.collection.find(_id: post.id).first
      end

      it "hard deletes the document" do
        raw.should be_nil
      end

      it "executes the before destroy callbacks" do
        post.before_destroy_called.should be_true
      end

      it "executes the after destroy callbacks" do
        post.after_destroy_called.should be_true
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create
      end

      let(:phone) do
        person.paranoid_phones.create(number: "911")
      end

      before do
        phone.destroy!
      end

      let(:raw) do
        Person.collection.find(_id: person.id).first
      end

      it "hard deletes the document" do
        raw["paranoid_phones"].should be_empty
      end

      it "executes the before destroy callbacks" do
        phone.before_destroy_called.should be_true
      end

      it "executes the after destroy callbacks" do
        phone.after_destroy_called.should be_true
      end
    end

    context "when the document has a dependent relation" do

      let(:post) do
        ParanoidPost.create(title: "test")
      end

      let!(:author) do
        post.authors.create(name: "poe")
      end

      before do
        post.destroy!
      end

      it "cascades the dependent option" do
        expect {
          author.reload
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end
  end

  describe "#destroy" do

    context "when the document is a root" do

      let(:post) do
        ParanoidPost.create(title: "testing")
      end

      before do
        post.destroy
      end

      let(:raw) do
        ParanoidPost.collection.find(_id: post.id).first
      end

      it "soft deletes the document" do
        raw["deleted_at"].should be_within(1).of(Time.now)
      end

      it "does not return the document in a find" do
        expect {
          ParanoidPost.find(post.id)
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end

      it "executes the before destroy callbacks" do
        post.before_destroy_called.should be_true
      end

      it "executes the after destroy callbacks" do
        post.after_destroy_called.should be_true
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create
      end

      let(:phone) do
        person.paranoid_phones.create(number: "911")
      end

      before do
        phone.destroy
      end

      let(:raw) do
        Person.collection.find(_id: person.id).first
      end

      it "soft deletes the document" do
        raw["paranoid_phones"].first["deleted_at"].should be_within(1).of(Time.now)
      end

      it "does not return the document in a find" do
        expect {
          person.paranoid_phones.find(phone.id)
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end

      it "does not include the document in the relation" do
        person.paranoid_phones.scoped.should be_empty
      end

      it "executes the before destroy callbacks" do
        phone.before_destroy_called.should be_true
      end

      it "executes the after destroy callbacks" do
        phone.after_destroy_called.should be_true
      end
    end

    context "when the document has a dependent: :delete relation" do

      let(:post) do
        ParanoidPost.create(title: "test")
      end

      let!(:author) do
        post.authors.create(name: "poe")
      end

      before do
        post.destroy
      end

      it "cascades the dependent option" do
        expect {
          author.reload
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end

    context "when the document has a dependent: :restrict relation" do

      let(:post) do
        ParanoidPost.create(title: "test")
      end

      let!(:title) do
        post.titles.create
      end

      before do
        begin
          post.destroy
        rescue Mongoid::Errors::DeleteRestriction
        end
      end

      it "does not destroy the document" do
        post.should_not be_destroyed
      end
    end
  end

  describe "#destroyed?" do

    context "when the document is a root" do

      let(:post) do
        ParanoidPost.create(title: "testing")
      end

      context "when the document is hard deleted" do

        before do
          post.destroy!
        end

        it "returns true" do
          post.should be_destroyed
        end
      end

      context "when the document is soft deleted" do

        before do
          post.destroy
        end

        it "returns true" do
          post.should be_destroyed
        end
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create
      end

      let(:phone) do
        person.paranoid_phones.create(number: "911")
      end

      context "when the document is hard deleted" do

        before do
          phone.destroy!
        end

        it "returns true" do
          phone.should be_destroyed
        end
      end

      context "when the document is soft deleted" do

        before do
          phone.destroy
        end

        it "returns true" do
          phone.should be_destroyed
        end
      end
    end
  end

  describe "#deleted?" do

    context "when the document is a root" do

      let(:post) do
        ParanoidPost.create(title: "testing")
      end

      context "when the document is hard deleted" do

        before do
          post.destroy!
        end

        it "returns true" do
          post.should be_deleted
        end
      end

      context "when the document is soft deleted" do

        before do
          post.destroy
        end

        it "returns true" do
          post.should be_deleted
        end
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create
      end

      let(:phone) do
        person.paranoid_phones.create(number: "911")
      end

      context "when the document is hard deleted" do

        before do
          phone.destroy!
        end

        it "returns true" do
          phone.should be_deleted
        end
      end

      context "when the document is soft deleted" do

        before do
          phone.destroy
        end

        it "returns true" do
          phone.should be_deleted
        end
      end
    end
  end

  describe "#destroyed?" do

    context "when the document is a root" do

      let(:post) do
        ParanoidPost.create(title: "testing")
      end

      context "when the document is hard deleted" do

        before do
          post.destroy!
        end

        it "returns false" do
          post.should_not be_persisted
        end
      end

      context "when the document is soft deleted" do

        before do
          post.destroy
        end

        it "returns false" do
          post.should_not be_persisted
        end
      end

      context "when the document is reloaded" do

        before do
          post.destroy
          post.reload
        end

        it "returns false" do
          post.should_not be_persisted
        end
      end
    end
  end

  describe "#delete!" do

    context "when the document is a root" do

      let(:post) do
        ParanoidPost.create(title: "testing")
      end

      before do
        post.delete!
      end

      let(:raw) do
        ParanoidPost.collection.find(_id: post.id).first
      end

      it "hard deletes the document" do
        raw.should be_nil
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create
      end

      let(:phone) do
        person.paranoid_phones.create(number: "911")
      end

      before do
        phone.delete!
      end

      let(:raw) do
        Person.collection.find(_id: person.id).first
      end

      it "hard deletes the document" do
        raw["paranoid_phones"].should be_empty
      end
    end

    context "when the document has a dependent relation" do

      let(:post) do
        ParanoidPost.create(title: "test")
      end

      let!(:author) do
        post.authors.create(name: "poe")
      end

      before do
        post.delete!
      end

      it "cascades the dependent option" do
        expect {
          author.reload
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end
  end

  describe "#delete" do

    context "when the document is a root" do

      let(:post) do
        ParanoidPost.create(title: "testing")
      end

      before do
        post.delete
      end

      let(:raw) do
        ParanoidPost.collection.find(_id: post.id).first
      end

      it "soft deletes the document" do
        raw["deleted_at"].should be_within(1).of(Time.now)
      end

      it "does not return the document in a find" do
        expect {
          ParanoidPost.find(post.id)
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end

      it "clears out the persistence options" do
        Mongoid::Threaded.persistence_options(ParanoidPost).should be_nil
      end

      it "clears out the identity map" do
        Mongoid::IdentityMap.should be_empty
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create
      end

      let(:phone) do
        person.paranoid_phones.create(number: "911")
      end

      before do
        phone.delete
      end

      let(:raw) do
        Person.collection.find(_id: person.id).first
      end

      it "soft deletes the document" do
        raw["paranoid_phones"].first["deleted_at"].should be_within(1).of(Time.now)
      end

      it "does not return the document in a find" do
        expect {
          person.paranoid_phones.find(phone.id)
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end

      it "does not include the document in the relation" do
        person.paranoid_phones.scoped.should be_empty
      end
    end

    context "when the document has a dependent relation" do

      let(:post) do
        ParanoidPost.create(title: "test")
      end

      let!(:author) do
        post.authors.create(name: "poe")
      end

      before do
        post.delete
      end

      it "cascades the dependent option" do
        expect {
          author.reload
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end

    context "when the document has a dependent: :restrict relation" do

      let(:post) do
        ParanoidPost.create(title: "test")
      end

      let!(:title) do
        post.titles.create
      end

      before do
        begin
          post.delete
        rescue Mongoid::Errors::DeleteRestriction
        end
      end

      it "does not destroy the document" do
        post.should_not be_destroyed
      end
    end
  end

  describe "#remove" do

    let(:post) do
      ParanoidPost.new
    end

    let!(:time) do
      Time.now
    end

    before do
      post.remove
    end

    it "sets the deleted flag" do
      post.should be_destroyed
    end
  end

  describe "#restore" do

    context "when the document is a root" do

      let(:post) do
        ParanoidPost.create(title: "testing")
      end

      before do
        post.delete
        post.restore
      end

      it "removes the deleted at time" do
        post.deleted_at.should be_nil
      end

      it "persists the change" do
        post.reload.deleted_at.should be_nil
      end

      it "marks document again as persisted" do
        post.persisted?.should be_true
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create
      end

      let(:phone) do
        person.paranoid_phones.create(number: "911")
      end

      before do
        phone.delete
        phone.restore
      end

      it "removes the deleted at time" do
        phone.deleted_at.should be_nil
      end

      it "persists the change" do
        person.reload.paranoid_phones.first.deleted_at.should be_nil
      end
    end
  end

  describe ".scoped" do

    let(:scoped) do
      ParanoidPost.scoped
    end

    it "returns a scoped criteria" do
      scoped.selector.should eq({ "deleted_at" => nil })
    end
  end

  describe "#set" do

    let!(:post) do
      ParanoidPost.create
    end

    let(:time) do
      20.days.ago
    end

    before do
      post.set(:deleted_at, time)
    end

    it "persists the change" do
      post.reload.deleted_at.should be_within(1).of(time)
    end
  end

  describe ".unscoped" do

    let(:unscoped) do
      ParanoidPost.unscoped
    end

    it "returns an unscoped criteria" do
      unscoped.selector.should eq({})
    end
  end

  describe "#to_param" do

    let(:post) do
      ParanoidPost.new(title: "testing")
    end

    context "when the document is new" do

      it "still returns nil" do
        post.to_param.should be_nil
      end
    end

    context "when the document is not deleted" do

      before do
        post.save
      end

      it "returns the id as a string" do
        post.to_param.should eq(post.id.to_s)
      end
    end

    context "when the document is deleted" do

      before do
        post.save
        post.delete
      end

      it "returns the id as a string" do
        post.to_param.should eq(post.id.to_s)
      end
    end
  end
end
