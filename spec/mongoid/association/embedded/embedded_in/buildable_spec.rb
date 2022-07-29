# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Embedded::EmbeddedIn::Buildable do

  describe "#build" do

    let(:base) do
      double
    end

    let(:options) do
      { }
    end

    let(:association) do
      Mongoid::Association::Embedded::EmbeddedIn.new(Person, :addresses, options)
    end

    context "when a document is provided" do

      let(:object) do
        double
      end

      let(:document) do
        association.build(base, object)
      end

      it "returns the document" do
        expect(document).to eq(object)
      end
    end
  end

  context 'when the object is already associated with another object' do

    context "when inverse is embeds_many" do

      let(:appointment1) do
        Appointment.new
      end

      let(:appointment2) do
        Appointment.new
      end

      let(:person) do
        Person.create!
      end

      before do
        appointment1.person = person
        appointment2.person = person
      end

      it 'does not clear the object of its previous association' do
        expect(appointment1.person).to eq(person)
        expect(appointment2.person).to eq(person)
        expect(person.appointments).to eq([appointment1, appointment2])
      end
    end

    context "when inverse is embeds_one" do

      let(:scribe1) do
        Scribe.new
      end

      let(:scribe2) do
        Scribe.new
      end

      let(:owner) do
        Owner.create!
      end

      before do
        scribe1.owner = owner
        scribe2.owner = owner
      end

      it 'clears the object of its previous association' do
        expect(scribe1.owner).to be_nil
        expect(scribe2.owner).to eq(owner)
      end
    end
  end
end
