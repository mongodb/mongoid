require 'spec_helper'

describe 'Criteria logical operations' do
  let!(:ap) { Band.create!(name: 'Astral Projection', origin: 'SFX', genres: ['Goa', 'Psy']) }
  let!(:im) { Band.create!(name: 'Infected Mushroom', origin: 'Computers', genres: ['Psy']) }
  let!(:sp) { Band.create!(name: 'Sun Project', genres: ['Goa']) }

  describe 'and' do
    it 'combines conditions on different fields given as hashes' do
      bands = Band.where(name: /Proj/).and(genres: 'Psy')
      expect(bands.to_a).to eq([ap])
    end

    it 'combines conditions on different fields given as scopes' do
      bands = Band.where(name: /Proj/).and(Band.where(genres: 'Psy'))
      expect(bands.to_a).to eq([ap])
    end

    it 'combines conditions on same field given as hashes' do
      bands = Band.where(name: /Proj/).and(name: /u/)
      expect(bands.to_a).to eq([sp])
    end

    it 'combines conditions on same field given as scopes' do
      bands = Band.where(name: /Proj/).and(Band.where(name: /u/))
      expect(bands.to_a).to eq([sp])
    end
  end

  describe 'or' do
    it 'combines conditions on different fields given as hashes' do
      bands = Band.where(name: /Sun/).or(origin: 'SFX')
      expect(bands.order_by(name: 1).to_a).to eq([ap, sp])
    end

    it 'combines conditions on different fields given as scopes' do
      bands = Band.where(name: /Sun/).or(Band.where(origin: 'SFX'))
      expect(bands.order_by(name: 1).to_a).to eq([ap, sp])
    end

    it 'combines conditions on same field given as hashes' do
      bands = Band.where(name: /jecti/).or(name: /ush/)
      expect(bands.order_by(name: 1).to_a).to eq([ap, im])
    end

    it 'combines conditions on same field given as scopes' do
      bands = Band.where(name: /jecti/).or(Band.where(name: /ush/))
      expect(bands.order_by(name: 1).to_a).to eq([ap, im])
    end

    context 'when using a symbol operator' do
      context 'when field has a serializer' do
        let!(:doc) { Dokument.create! }

        it 'works' do
          scope = Dokument.or(:created_at.lte => DateTime.now).sort(id: 1)
          # input was converted from DateTime to Time
          scope.criteria.selector['$or'].first['created_at']['$lte'].should be_a(Time)
          scope.to_a.should == [doc]
        end
      end
    end
  end

  describe 'not' do
    context 'hash argument with string value' do
      let(:actual) do
        Band.not(name: 'test').selector
      end

      let(:expected) do
        {'name' => {'$ne' => 'test'}}
      end

      it 'expands to use $ne' do
        expect(actual).to eq(expected)
      end
    end

    context 'hash argument with regexp value' do
      let(:actual) do
        Band.not(name: /test/).selector
      end

      let(:expected) do
        {'name' => {'$not' => /test/}}
      end

      it 'expands to use $not' do
        expect(actual).to eq(expected)
      end
    end
  end
end
