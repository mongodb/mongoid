require 'spec_helper'

describe 'id is a legal bson string' do
  let(:id) {'123456789012345678901234'}
  
  before do
    MixedDrink.delete_all
  end
  
  describe '#create with a ObjectId(id), then find with same id' do
    it 'should create out of legal string' do
      mojito = MixedDrink.create(:id => BSON::ObjectId(id), :name => 'mojito')
      MixedDrink.find(id).should == mojito
    end
  end
  
  describe '#create with a stringed object id (size=24), then find with same id' do
    it 'should create out of legal string' do
      rhum = MixedDrink.create(:id => id, :name => 'rhum')
      MixedDrink.find(id).should == rhum
    end
  end
end