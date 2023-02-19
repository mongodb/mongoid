module Mongoid
  module ImmutableIds
    def immutable_id_examples_as(name)
      shared_examples_for name do
        shared_examples 'a persisted document' do
          it 'should ignore the change and issue a warning' do
            expect(Mongoid::Warnings).to receive(:warn_mutable_ids)
            expect { invoke_operation! }.not_to raise_error
            expect(id_is_unchanged).not_to be legacy_behavior_expects_id_to_change
          end

          context 'when immutable_ids is true' do
            before { Mongoid::Config.immutable_ids = true }
            after { Mongoid::Config.immutable_ids = false }

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

        context 'when the field is _id' do
          let(:new_id_value) { 1234 }

          context 'when the document is top-level' do    
            let(:legacy_behavior_expects_id_to_change) { false }

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
            let(:legacy_behavior_expects_id_to_change) { true }

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

              context 'updating embeds_one via parent' do
                context 'when immutable_ids is false' do
                  before { expect(Mongoid::Config.immutable_ids).to be false }

                  it 'should ignore the change' do
                    expect(Mongoid::Warnings).to receive(:warn_mutable_ids)

                    parent.pet = pet = Pet.new
                    parent.save

                    original_id = pet._id
                    new_id = BSON::ObjectId.new

                    expect { parent.update(pet: { _id: new_id }) }.not_to raise_error
                    expect(parent.reload.pet._id.to_s).to be == original_id.to_s
                  end
                end

                context 'when immutable_ids is true' do
                  before { Mongoid::Config.immutable_ids = true }
                  after { Mongoid::Config.immutable_ids = false }

                  it 'should raise an exception' do
                    parent.pet = pet = Pet.new
                    parent.save

                    original_id = pet._id
                    new_id = BSON::ObjectId.new

                    expect { parent.update(pet: { _id: new_id }) }
                      .to raise_error(Mongoid::Errors::ImmutableAttribute)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
