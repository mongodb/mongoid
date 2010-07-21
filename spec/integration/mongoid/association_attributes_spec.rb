require "spec_helper"

describe Mongoid::Associations do

  before do
    Person.collection.remove
  end

  context "embeds_one" do

    context "with attributes hash" do
      describe "creating associated document" do
        let(:person) { Person.create!( :ssn => "1234", :pet_attributes => { :name => 'odie' } ) }
        specify { person.reload.pet.name.should == 'odie' }
      end

      describe "updating associated document" do
        let(:person) { Person.create!( :ssn => "1234", :pet_attributes => { :name => 'garfield' } ) }
        before { person.update_attributes(:pet_attributes => { :name => 'odie' } ) }
        specify { person.reload.pet.name.should == 'odie' }
      end
    end

    context "with a normal hash" do
      describe "creating associated document" do
        let(:person) { Person.create!( :ssn => "1234", :pet => { :name => 'odie', :tag_list => "dog, beagle" } ) }
        specify { person.reload.pet.name.should == 'odie' }
        specify { person.reload.pet.tags.should == ["dog", "beagle"] }    
      end

      describe "updating associated document" do
        let(:person) { Person.create!( :ssn => "1234", :pet => { :name => 'garfield', :tag_list => "cat" } ) }
        before { person.update_attributes!(:pet => { :name => 'odie', :tag_list => "dog, beagle" } ) }
        specify { person.reload.pet.name.should == 'odie' }
        specify { person.reload.pet.tags.should == ["dog", "beagle"] }               
      end
    end

  end

  context "embeds_many" do

    context "with attributes hash" do
      describe "creating associated document" do
        let(:person) { Person.create!( :ssn => "1234", :favorites_attributes => { '0' => { :title => 'something' } } ) }
        specify { person.reload.favorites.first.title.should == 'something' }
      end

      describe "updating associated document" do
        let(:person) { Person.create!( :ssn => "1234", :favorites => { '0' => { :title => 'nothing' } } ) }
        before do
          person.update_attributes(:favorites_attributes => { '0' => { :title => 'something' } } )
        end
        specify { person.reload.favorites.first.title.should == 'something' }
      end
    end

    context "with a normal hash" do
      describe "creating associated document" do
        let(:person) { Person.create!( :ssn => "1234", :favorites => { '0' => { :title => 'something' } } ) }
        specify { person.reload.favorites.first.title.should == 'something' }
      end

      describe "updating associated document" do
        let(:person) { Person.create!( :ssn => "1234", :favorites => { '0' => { :title => 'nothing' } } ) }
        before { person.update_attributes(:favorites => { '0' => { :title => 'something' } } ) }
        specify { person.reload.favorites.first.title.should == 'something' }
      end
    end
  end
end
