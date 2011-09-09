require "spec_helper"

describe Mongoid::Relations::Bindings::Referenced::ManyToMany do

  describe "#bind" do

    let(:person) do
      Person.new
    end

    context "when the child is frozen" do

      let(:preference) do
        Preference.new.freeze
      end

      before do
        person.preferences << preference
      end

      it "does not set the foreign key" do
        preference.person_ids.should be_empty
      end
    end
  end

  describe "#unbind" do

    let(:person) do
      Person.new
    end

    context "when the child is frozen" do

      let(:preference) do
        Preference.new
      end

      before do
        person.preferences << preference
        preference.freeze
        person.preferences.delete(preference)
      end

      it "does not unset the foreign key" do
        preference.person_ids.should eq([ person.id ])
      end
    end
  end
end
