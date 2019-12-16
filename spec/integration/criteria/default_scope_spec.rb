require 'spec_helper'

describe 'Criteria and default scope' do

  context 'order in query' do
    let(:query) do
      Acolyte.order(status: :desc)
    end

    let(:sort_options) do
      query.options[:sort]
    end

    it 'is added after order of default scope' do
      sort_options.should == {'status' => -1, 'name' => 1}

      # Keys in Ruby are ordered
      sort_options.keys.should == %w(name status)
    end
  end
end
