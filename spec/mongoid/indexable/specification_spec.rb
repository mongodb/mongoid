require "spec_helper"

describe Mongoid::Indexable::Specification do

  describe "#==" do

    context "when the keys are different" do

      let(:spec_one) do
        described_class.new(Band, { name: 1 })
      end

      let(:spec_two) do
        described_class.new(Band, { title: 1 })
      end

      it "returns false" do
        expect(spec_one).to_not eq(spec_two)
      end
    end

    context "when the keys are the same" do

      let(:spec_one) do
        described_class.new(Band, { name: 1 })
      end

      let(:spec_two) do
        described_class.new(Band, { name: 1 })
      end

      it "returns true" do
        expect(spec_one).to eq(spec_two)
      end
    end

    context "when the keys are in different order" do

      let(:spec_one) do
        described_class.new(Band, { name: 1, title: -1 })
      end

      let(:spec_two) do
        described_class.new(Band, { title: -1, name: 1 })
      end

      it "returns false" do
        expect(spec_one).to_not eq(spec_two)
      end
    end

    context "when the keys are the same with different value" do

      let(:spec_one) do
        described_class.new(Band, { name: 1, title: 1 })
      end

      let(:spec_two) do
        described_class.new(Band, { name: 1, title: -1 })
      end

      it "returns false" do
        expect(spec_one).to_not eq(spec_two)
      end
    end
  end

  describe "#fields" do

    let(:spec) do
      described_class.new(Band, { name: 1, title: 1 })
    end

    it "returns the key fields in order" do
      expect(spec.fields).to eq([ :name, :title ])
    end
  end

  describe "#initialize" do

    let(:spec) do
      described_class.new(
        Band,
        { name: 1, title: 1, years: -1 },
        background: true,
        drop_dups: true
      )
    end

    it "sets the class" do
      expect(spec.klass).to eq(Band)
    end

    it "normalizes the key" do
      expect(spec.key).to eq(name: 1, title: 1, y: -1)
    end

    it "normalizes the options" do
      expect(spec.options).to eq(background: true, drop_dups: true)
    end
  end

  describe '#name' do

    context 'when there is only one field' do

      let(:spec) do
        described_class.new(Band, { name: 1 })
      end

      it 'returns the key and direction separated by an underscore' do
        expect(spec.name).to eq('name_1')
      end
    end

    context 'when there are two fields' do

      let(:spec) do
        described_class.new(Band, { name: 1, title: -1 })
      end

      it 'returns the keys and directions separated by underscores' do
        expect(spec.name).to eq('name_1_title_-1')
      end
    end
  end
end
