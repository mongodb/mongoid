require 'spec_helper'

describe "embeds many with a nil element" do
  let (:home_phone) do
    Phone.new :number => "555-555-5555"
  end

  let (:office_phone) do
    Phone.new :number => "666-666-6666"
  end

  describe "replacing the entire embedded list" do

    context "when an embeds many relationship contains a nil as the first item" do
      let (:person) do
        Person.create!
      end

      let (:phone_list) do
        [nil, home_phone, office_phone]
      end

      before do
        person.phone_numbers = phone_list
        person.save!
      end

      it "should ignore the nil and persist the remaining items" do
        reloaded = Person.find(person.id)
        reloaded.phone_numbers.should == phone_list
      end
    end

    context "when an embeds many relationship contains a nil in the middle of the list" do
      let (:person) do
        Person.create!
      end

      let (:phone_list) do
        [home_phone, nil, office_phone]
      end

      before do
        person.phone_numbers = phone_list
        person.save!
      end

      it "should ignore the nil and persist the remaining items" do
        reloaded = Person.find(person.id)
        reloaded.phone_numbers.should == phone_list
      end
    end

    context "when an embeds many relationship contains a nil at the end of the list" do
      let (:person) do
        Person.create!
      end

      let (:phone_list) do
        [home_phone, office_phone, nil]
      end

      before do
        person.phone_numbers = phone_list
        person.save!
      end

      it "should ignore the nil and persist the remaining items" do
        reloaded = Person.find(person.id)
        reloaded.phone_numbers.should == phone_list
      end
    end

  end

  describe "appending to the embedded list" do

    context "when appending a nil to the first position in an embedded list" do
      let (:person) do
        Person.create! :phone_numbers => []
      end

      before do
        person.phone_numbers << nil 
        person.phone_numbers << home_phone
        person.phone_numbers << office_phone 
        person.save!
      end

      it "should ignore the nil and persist the remaining items" do
        reloaded = Person.find(person.id)
        reloaded.phone_numbers.should == person.phone_numbers
      end
    end

    context "when appending a nil into the middle of an embedded list" do
      let (:person) do
        Person.create! :phone_numbers => []
      end

      before do
        person.phone_numbers << home_phone
        person.phone_numbers << nil 
        person.phone_numbers << office_phone 
        person.save!
      end

      it "should ignore the nil and persist the remaining items" do
        reloaded = Person.find(person.id)
        reloaded.phone_numbers.should == person.phone_numbers
      end
    end

    context "when appending a nil to the end of an embedded list" do
      let (:person) do
        Person.create! :phone_numbers => []
      end

      before do
        person.phone_numbers << home_phone
        person.phone_numbers << office_phone 
        person.phone_numbers << nil 
        person.save!
      end

      it "should ignore the nil and persist the remaining items" do
        reloaded = Person.find(person.id)
        reloaded.phone_numbers.should == person.phone_numbers
      end
    end
  
  end
end
