require 'spec_helper'

describe 'mschulkind' do
  it 'creates referenced with referenced' do
    odd = Odd.create(name: 'one')

    odd.evens.create(name: 'two', odds: [Odd.new(name: 'three')])

    expect(odd.evens.count).to eq(1)
    expect(odd.evens.first.odds.count).to eq(1)
    expect(Even.count).to eq(1)
    expect(Odd.count).to eq(2)
  end

end
