# frozen_string_literal: true

shared_context 'using AS time zone' do
  before do
    Mongoid.use_activesupport_time_zone = true
    Time.zone = "Tokyo"
  end

  after do
    Time.zone = nil
  end
end

shared_context 'not using AS time zone' do
  before do
    Mongoid.use_activesupport_time_zone = false
    Time.zone = 'Tokyo'
  end

  after do
    Mongoid.use_activesupport_time_zone = true
    Time.zone = nil
  end
end

shared_examples_for 'mongoizes to AS::TimeWithZone' do
  it 'is an AS::TimeWithZone' do
    expect(mongoized.class).to eq(ActiveSupport::TimeWithZone)
  end

  it 'is equal to expected time' do
    expect(expected_time).to be_a(ActiveSupport::TimeWithZone)
    expect(mongoized).to eq(expected_time)
  end
end

shared_examples_for 'mongoizes to Time' do
  it 'is a Time' do
    expect(mongoized.class).to eq(Time)
  end

  it 'is equal to expected time' do
    expect(expected_time).to be_a(Time)
    expect(mongoized).to eq(expected_time)
  end
end

shared_examples_for 'maintains precision when mongoized' do
  it 'maintains precision' do
    # 123457 happens to be consistently obtained by various tests
    expect(mongoized.to_f.to_s).to match(/\.123457/)
  end
end
