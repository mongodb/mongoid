# frozen_string_literal: true

shared_examples_for "returns a cloned query" do

  it "returns a cloned query" do
    expect(selection).to_not equal(query)
  end
end

shared_examples_for 'requires an argument' do
  context "when provided no argument" do

    let(:selection) do
      query.send(query_method)
    end

    it "raises ArgumentError" do
      expect do
        selection.selector
      end.to raise_error(ArgumentError)
    end
  end
end

shared_examples_for 'requires a non-nil argument' do
  context "when provided nil" do

    let(:selection) do
      query.send(query_method, nil)
    end

    it "raises CriteriaArgumentRequired" do
      expect do
        selection.selector
      end.to raise_error(Mongoid::Errors::CriteriaArgumentRequired, /#{query_method}/)
    end
  end
end
