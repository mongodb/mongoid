module Mongoid
  module ImmutableIds
    def immutable_id_examples_as(name)
      shared_examples_for name do
        shared_examples 'a persisted document' do
          it 'should disallow _id to be updated' do
            expect { invoke_operation! }
              .to raise_error(Mongoid::Errors::ImmutableAttribute)
          end
    
          context 'when ignore_changes_to_immutable_attributes is true' do
            before { Mongoid::Config.ignore_changes_to_immutable_attributes = true }
            after { Mongoid::Config.ignore_changes_to_immutable_attributes = false }

            it 'should ignore the change and issue a warning' do
              expect(Mongoid::Warnings).to receive(:warn_ignore_immutable_deprecated)
              expect { invoke_operation! }.not_to raise_error
p object
p original_id
p parent.favorites.where(_id: original_id).to_a
p parent.favorites.where(_id: new_id_value).to_a
p id_is_unchanged
              expect(id_is_unchanged).to be true
            end
          end

          context 'when id is set to the existing value' do
            let(:new_id_value) { object._id }

            it 'should allow the update to proceed' do
              expect { invoke_operation! }
                .not_to raise_error
            end
          end
        end

        context 'when the field is _id' do
          let(:new_id_value) { 1234 }

          context 'when the document is top-level' do    
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
              let!(:original_id) { object._id }
              let(:id_is_unchanged) { Person.exists?(original_id) }
    
              it_behaves_like 'a persisted document'
            end
          end
    
          context 'when the document is embedded' do
            let(:parent) { Person.create }
  
            context 'when the document is new' do
              let(:object) { parent.favorites.new }
    
              it 'should allow _id to be updated' do
                invoke_operation!
                expect(object.new_record?).to be false
                expect(parent.reload.favorites.first._id).to be == new_id_value
              end
            end
    
            context 'when the document has been persisted' do
              let(:object) { parent.favorites.create }
              let!(:original_id) { object._id }
              let(:id_is_unchanged) { parent.favorites.where(_id: original_id).exists? }
      
              it_behaves_like 'a persisted document'
            end
          end
        end
      end
    end
  end
end
