# frozen_string_literal: true

require "spec_helper"

describe "Using to_key in queries" do
  config_override :expand_single_element_arrays_in_query, true

  let(:person) do
    Person.create!(title: "Sir", aliases: ["John", "Jack"])
  end

  context 'using where' do
    it "returns the document" do
      expect(Person.where(id: person.to_key).first).to eq(person)
    end
  end

  context 'using find' do
    it "returns the document" do
      expect(Person.find(person.to_key).first).to eq(person)
    end
  end

  context 'using find_by' do
    it "returns the document" do
      expect(Person.find_by(id: person.to_key)).to eq(person)
    end
  end
end
