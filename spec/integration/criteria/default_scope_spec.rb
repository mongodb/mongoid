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
      sort_options.should eq({ 'status' => -1, 'name' => 1 })

      # Keys in Ruby are ordered
      sort_options.keys.should eq %w[name status]
    end
  end

  context 'default scope + logical operator' do
    context 'logical operator applied to a criteria' do
      let(:base) { Appointment.where }

      it 'has default scope' do
        base.selector.should eq({ 'active' => true })
      end

      describe '.or' do
        let(:criteria) do
          base.or(timed: true)
        end

        it 'adds new condition in parallel to default scope conditions' do
          criteria.selector.should eq(
            {
              '$or' => [
                { 'active' => true },
                { 'timed' => true }
              ]
            }
          )
        end
      end

      describe '.any_of' do
        let(:criteria) do
          base.any_of(timed: true)
        end

        it 'maintains default scope conditions' do
          criteria.selector.should eq({ 'active' => true, 'timed' => true })
        end
      end
    end

    context 'logical operator called on the class' do
      let(:base) { Appointment }

      describe '.or' do
        let(:criteria) do
          base.or(timed: true)
        end

        it 'adds new condition in parallel to default scope conditions' do
          criteria.selector.should eq(
            {
              '$or' => [
                { 'active' => true },
                { 'timed' => true }
              ]
            }
          )
        end
      end
    end
  end
end
