require "spec_helper"

describe Mongoid::Persistence::Operations::Remove do

  before do
    [ Artist, Album, Person ].each(&:delete_all)
    Mongoid::IdentityMap.clear
  end

  describe "#persist" do

    context "when the remove succeeded" do

      let!(:person) do
        Person.create(:ssn => "323-21-1111")
      end

      before do
        person.delete
      end

      let(:in_map) do
        Mongoid::IdentityMap.get(Person, person.id)
      end

      it "removes the document from the identity map" do
        in_map.should be_nil
      end
    end
  end

  context "when a dependent option exists" do

    context "when accessing the parent before destroy" do

      let(:artist) do
        Artist.create(:name => "depeche mode")
      end

      let!(:album) do
        artist.albums.create
      end

      before do
        artist.destroy
      end

      it "allows the access" do
        artist.name.should eq("destroyed")
      end

      it "destroys the associated document" do
        album.should be_destroyed
      end
    end
  end
end
