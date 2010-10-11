require 'spec_helper'

describe 'Given id is a legal bson string' do
  let(:id) {'123456789012345678901234'}
  
  before do
    MixedDrink.delete_all
  end
  
  describe 'when I create document with ObjectId(id) as "_id" field' do
    it 'then I should find it with id string' do
      mojito = MixedDrink.create(:id => BSON::ObjectId(id), :name => 'mojito')
      MixedDrink.find(id).should == mojito
    end
  end
  
  describe 'when I create document with id as "_id" field' do
    it 'then I should find document with id string' do
      rhum = MixedDrink.create(:id => id, :name => 'rhum')
      MixedDrink.find(id).should == rhum
    end
  end
end