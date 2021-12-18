# frozen_string_literal: true

# require "spec_helper"
#
# describe Mongoid::Relations::Proxy do
#
#   describe '#with' do
#
#     let(:circus) do
#       Circus.new
#     end
#
#     let(:animal) do
#       Animal.new
#     end
#
#     before do
#       circus.animals << animal
#       circus.save!
#     end
#
#     it 'uses the new persistence options' do
#       expect {
#         animal.with(write: { w: 100 }) do |an|
#           an.update_attribute(:name, 'kangaroo')
#         end
#       }.to raise_exception(Mongo::Error::OperationFailure)
#     end
#   end
#
#   describe "#find" do
#     let(:person) do
#       Person.create!
#     end
#
#     let(:messages) do
#       person.messages
#     end
#
#     let(:msg1) do
#       messages.create!(body: 'msg1')
#     end
#
#     it "returns nil with no arguments" do
#       expect(messages.find).to be_nil
#       expect(messages.send(:find)).to be_nil
#       expect(messages.__send__(:find)).to be_nil
#       expect(messages.public_send(:find)).to be_nil
#     end
#
#     it "returns the object corresponding to the id" do
#       expect(messages.find(msg1.id)).to eq(msg1)
#       expect(messages.send(:find, msg1.id)).to eq(msg1)
#       expect(messages.__send__(:find, msg1.id)).to eq(msg1)
#       expect(messages.public_send(:find, msg1.id)).to eq(msg1)
#     end
#   end
#
#   describe "#extend" do
#
#     before(:all) do
#       Person.reset_callbacks(:validate)
#       module Testable
#       end
#     end
#
#     after(:all) do
#       Object.send(:remove_const, :Testable)
#     end
#
#     let(:person) do
#       Person.create!
#     end
#
#     let(:name) do
#       person.build_name
#     end
#
#     before do
#       name.namable.extend(Testable)
#     end
#
#     it "extends the proxied object" do
#       expect(person).to be_a(Testable)
#     end
#
#     context "when extending from the relation definition" do
#
#       let!(:address) do
#         person.addresses.create!(street: "hobrecht")
#       end
#
#       let(:found) do
#         person.addresses.find_by_street("hobrecht")
#       end
#
#       it "extends the proxy" do
#         expect(found).to eq(address)
#       end
#     end
#   end
#
#   describe "equality" do
#     let(:messages) do
#       Person.create!.messages
#     end
#
#     it "is #equal? to itself" do
#       expect(messages.equal?(messages)).to eq(true)
#     end
#
#     it "is == to itself" do
#       expect(messages == messages).to eq(true)
#     end
#
#     it "is not #equal? to its target" do
#       expect(messages.equal?(messages.target)).to eq(false)
#       expect(messages.target.equal?(messages)).to eq(false)
#     end
#
#     it "is == to its target" do
#       expect(messages == messages.target).to eq(true)
#       expect(messages.target == messages).to eq(true)
#     end
#   end
# end
