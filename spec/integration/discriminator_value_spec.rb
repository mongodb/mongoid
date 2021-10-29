# frozen_string_literal: true

require 'spec_helper'

describe "#discriminator_key" do 

  context "when the discriminator value is not set on a class" do
    let(:piano) do 
      Piano.new
    end

    let(:guitar) do 
      Guitar.new
    end  
    
    it "sets the child discriminator key to _type: Piano" do
      expect(piano._type).to eq("Piano")
    end

    it "sets the child discriminator key to _type: Guitar" do
      expect(guitar._type).to eq("Guitar")
    end
  end

  context "when the discriminator_value is set on a child" do
    before do 
      Piano.discriminator_value = "keys"
    end

    after do 
      Piano.discriminator_value = nil
    end

    let(:piano) do 
      Piano.new
    end

    it "has the correct discriminator value on the instance" do 
      expect(piano._type).to eq("keys")
    end
  end

  context "when the discriminator key and value are set on a child" do
    before do 
      Piano.discriminator_value = "keys"
      Instrument.discriminator_key = "dkey"
    end

    after do 
      Piano.discriminator_value = nil
      Instrument.discriminator_key = nil
    end


    let(:piano) do 
      Piano.new
    end

    it "has the correct discriminator value on the instance" do 
      expect(piano.dkey).to eq("keys")
    end
  end

  context "when adding to the db" do
    context "when not changing the discriminator value" do 
      before do 
        Piano.create!
      end

      it "has the correct count" do 
        expect(Piano.count).to eq(1)
      end

      it "has the correct count in the parent" do 
        expect(Instrument.count).to eq(1)
      end

      it "has zero count in the sibling" do 
        expect(Guitar.count).to eq(0)
      end
    end

    context "when changing the discriminator value" do 
      before do 
        Piano.discriminator_value = "keys"
        Piano.create!
      end

      after do 
        Piano.discriminator_value = nil
      end

      it "has the correct count" do 
        expect(Piano.count).to eq(1)
      end

      it "has the correct count in the parent" do 
        expect(Instrument.count).to eq(1)
      end

      it "has zero count in the sibling" do 
        expect(Guitar.count).to eq(0)
      end
    end

    context "when changing the discriminator key/value" do 
      before do 
        Instrument.discriminator_key = "dkey"
        Piano.discriminator_value = "keys"
        Piano.create!
      end

      after do 
        Instrument.discriminator_key = nil
        Piano.discriminator_value = nil
      end

      it "has the correct count" do 
        expect(Piano.count).to eq(1)
      end

      it "has the correct count in the parent" do 
        expect(Instrument.count).to eq(1)
      end

      it "has zero count in the sibling" do 
        expect(Guitar.count).to eq(0)
      end
    end

    context "when calling count before changing the discriminator key/value" do 
      before do 
        Instrument.count
        Instrument.discriminator_key = "dkey"
        Piano.discriminator_value = "keys"
        Piano.create!
      end

      after do 
        Instrument.discriminator_key = nil
        Piano.discriminator_value = nil
      end

      it "has the correct count" do 
        expect(Piano.count).to eq(1)
      end

      it "has the correct count in the parent" do 
        expect(Instrument.count).to eq(1)
      end

      it "has zero count in the sibling" do 
        expect(Guitar.count).to eq(0)
      end
    end

    context "when calling create before changing the discriminator key/value" do 
      before do 
        Piano.create!
        Instrument.discriminator_key = "dkey"
        Piano.discriminator_value = "keys"
        Piano.create!
      end

      after do 
        Instrument.discriminator_key = nil
        Piano.discriminator_value = nil
      end

      it "has the correct count" do 
        expect(Piano.count).to eq(1)
      end

      it "has the correct count in the parent" do 
        expect(Instrument.count).to eq(2)
      end

      it "has zero count in the sibling" do 
        expect(Guitar.count).to eq(0)
      end
    end

    context "when there exists an unrecognizable discriminator value in the database" do 
      before do 
        Piano.discriminator_value = "keys"
        Piano.create!(_type: "dvalue")
      end

      after do 
        Piano.discriminator_value = nil
      end

      it "is not considered a piano" do 
        expect(Piano.count).to eq(0)
      end

      it "is considered an Instrument, the parent" do 
        expect(Instrument.count).to eq(1)
      end

      it "has zero count in the sibling" do 
        expect(Guitar.count).to eq(0)
      end
    end
  end
end
