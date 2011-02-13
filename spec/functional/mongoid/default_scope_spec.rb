require 'spec_helper'

describe Mongoid::DefaultScope do

  before do
    [ Person, Tree ].each(&:delete_all)
  end

  context "when providing a default scope on root documents" do

    let!(:fir) do
      Tree.create(:name => "Fir",   :evergreen => true )
    end

    let!(:pine) do
      Tree.create(:name => "Pine",  :evergreen => true )
    end

    let!(:birch) do
      Tree.create(:name => "Birch", :evergreen => false)
    end

    it "returns them in the correct order" do
      Tree.all.entries.should == [ birch, fir, pine ]
    end

    it "respects other scopes" do
      Tree.verdant.entries.should == [ fir, pine ]
    end
  end

  context "when providing a default scope on an embedded document" do

    let!(:person) do
      Person.create(:ssn => "111-11-1111")
    end

    let!(:tron) do
      person.videos.create(:title => "Tron")
    end

    let!(:bladerunner) do
      person.videos.create(:title => "Bladerunner")
    end

    it "respects the default scope" do
      person.reload.videos.all.should == [ bladerunner, tron ]
    end
  end
end
