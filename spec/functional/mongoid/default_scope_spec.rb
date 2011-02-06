require 'spec_helper'

describe Mongoid::DefaultScope do

  let!(:fir)   { Tree.create(:name => "Fir",   :evergreen => true ) }
  let!(:pine)  { Tree.create(:name => "Pine",  :evergreen => true ) }
  let!(:birch) { Tree.create(:name => "Birch", :evergreen => false) }

  after do
    Tree.delete_all
  end

  it "returns them in the correct order" do
    Tree.all.entries.should == [ birch, fir, pine ]
  end

  it "respects other scopes" do
    Tree.verdant.entries.should == [ fir, pine ]
  end
end
