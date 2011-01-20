require 'spec_helper'

describe Mongoid::DefaultScope do

  let(:obj1) { DefaultScopeTestModel.create(:name => "C", :green => true) }
  let(:obj2) { DefaultScopeTestModel.create(:name => "B", :green => true) }
  let(:obj3) { DefaultScopeTestModel.create(:name => "A", :green => false) }

  before(:all) do
    class DefaultScopeTestModel
      include Mongoid::Document

      field :name
      field :green, :type => Boolean

      scope :verdant, where(:green => true)
      default_scope asc(:name)
    end

    obj1; obj2; obj3
  end

  it "returns them in the correct order" do
    DefaultScopeTestModel.all.entries.should == [ obj3, obj2, obj1 ]
  end

  it "respects other scopes" do
    DefaultScopeTestModel.verdant.entries.should == [ obj2, obj1 ]
  end
end
