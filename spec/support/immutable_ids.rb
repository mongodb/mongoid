module Mongoid
  module ImmutableIds
    def immutable_id_examples_as(name)
      shared_examples_for name do
        context 'when the field is _id' do
          context 'when the document is top-level' do
            let(:new_id_value) { 1234 }
    
            context 'when the document is new' do
              let(:object) { Person.new }
    
              it 'should allow _id to be updated' do
                invoke_operation!
                expect(object.new_record?).to be false
                expect(object.reload._id).to be == new_id_value
              end
            end
    
            context 'when the document has been persisted' do
              let(:object) { Person.create }
    
              it 'should disallow _id to be updated' do
                expect { invoke_operation! }
                  .to raise_error(Mongoid::Errors::ImmutableAttribute)
              end

              context 'when id is set to the existing value' do
                let(:new_id_value) { object._id }

                it 'should allow the update to proceed' do
                  expect { invoke_operation! }
                    .not_to raise_error
                end
              end
            end
          end
    
          context 'when the document is embedded' do
            let(:new_id_value) { "1234" }
            let(:parent) { Person.create }
    
            context 'when the document is new' do
              let(:object) { parent.addresses.new }
    
              it 'should allow _id to be updated' do
                invoke_operation!
                expect(object.new_record?).to be false
                expect(parent.reload.addresses.first._id).to be == new_id_value
              end
            end
    
            context 'when the document has been persisted' do
              let(:object) { parent.addresses.create }
    
              it 'should disallow _id to be updated' do
                expect { invoke_operation! }
                  .to raise_error(Mongoid::Errors::ImmutableAttribute)
              end

              context 'when id is set to the existing value' do
                let(:new_id_value) { object._id }

                it 'should allow the update to proceed' do
                  expect { invoke_operation! }
                    .not_to raise_error
                end
              end
            end
          end
        end
      end
    end
  end
end
