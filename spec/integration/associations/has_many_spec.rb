# frozen_string_literal: true
# rubocop:todo all

require 'spec_helper'
require 'mongoid/association/referenced/has_many_models'

describe 'has_many associations' do
  context 'destroying parent in transaction with dependent child' do
    require_transaction_support

    let(:company) { HmmCompany.create! }
    let(:address) { HmmAddress.create!(company: company) }

    before do
      Company.delete_all
      Address.delete_all
    end

    context 'dependent: :destroy' do
      before do
        HmmCompany.class_eval do
          has_one :address, class_name: 'HmmAddress', dependent: :destroy
        end
      end

      it 'destroys' do
        address

        HmmCompany.count.should == 1
        HmmAddress.count.should == 1

        company.with_session do |session|
          session.with_transaction do
            company.destroy!
          end
        end

        HmmCompany.count.should == 0
        HmmAddress.count.should == 0
      end
    end

    context 'dependent: :restrict_with_error' do
      before do
        HmmCompany.class_eval do
          has_one :address, class_name: 'HmmAddress', dependent: :restrict_with_error
        end
      end

      it 'destroys' do
        address

        HmmCompany.count.should == 1
        HmmAddress.count.should == 1

        lambda do
          company.with_session do |session|
            session.with_transaction do
              company.destroy!
            end
          end
        end.should raise_error(Mongoid::Errors::DocumentNotDestroyed)

        HmmCompany.count.should == 1
        HmmAddress.count.should == 1
      end
    end
  end

  context 'when child does not have parent association' do
    context 'Child.new' do
      it 'creates a child instance' do
        HmmBusSeat.new.should be_a(HmmBusSeat)
      end
    end

    context 'assignment to child in parent' do
      let(:parent) { HmmBus.new }

      it 'raises InverseNotFound' do
        lambda do
          parent.seats << HmmBusSeat.new
        end.should raise_error(Mongoid::Errors::InverseNotFound)
      end
    end
  end

  context 're-associating the same object' do
    context 'with dependent: destroy' do
      let(:wiki_page) do
        WikiPage.create!
      end

      let!(:comment) do
        Comment.create!(wiki_page: wiki_page, title: 'hi') do
          wiki_page.reload
        end
      end

      it 'does not destroy the dependent object' do
        wiki_page.comments.should == [comment]
        wiki_page.comments = [comment]
        wiki_page.save!
        wiki_page.reload
        wiki_page.comments.should == [comment]
      end
    end

    context 'without dependent: destroy' do
      let(:series) do
        Series.create!
      end

      let!(:book) do
        Book.create!(series: series).tap do
          series.reload
        end
      end

      it 'does not destroy the dependent object' do
        series.books.should == [book]
        series.books = [book]
        series.save!
        series.reload
        series.books.should == [book]
      end
    end
  end

  context 'with deeply nested trees' do
    let(:post) { HmmPost.create!(title: 'Post') }
    let(:child) { post.comments.create!(title: 'Child') }

    # creating grandchild will cascade to create the other documents
    let!(:grandchild) { child.comments.create!(title: 'Grandchild') }

    let(:updated_parent_title) { 'Post Updated' }
    let(:updated_grandchild_title) { 'Grandchild Updated' }

    context 'with nested attributes' do
      let(:attributes) do
        {
          title: updated_parent_title,
          comments_attributes: [
            {
              # no change for comment1
              _id: child.id,
              comments_attributes: [
                {
                  _id: grandchild.id,
                  title: updated_grandchild_title,
                  num: updated_grandchild_num,
                }
              ]
            }
          ]
        }
      end

      context 'when the grandchild is invalid' do
        let(:updated_grandchild_num) { -1 } # invalid value

        it 'will not save the parent' do
          expect(post.update(attributes)).to be_falsey
          expect(post.errors).not_to be_empty
          expect(post.reload.title).not_to eq(updated_parent_title)
          expect(grandchild.reload.title).not_to eq(updated_grandchild_title)
          expect(grandchild.num).not_to eq(updated_grandchild_num)
        end
      end

      context 'when the grandchild is valid' do
        let(:updated_grandchild_num) { 1 }

        it 'will save the parent' do
          expect(post.update(attributes)).to be_truthy
          expect(post.errors).to be_empty
          expect(post.reload.title).to eq(updated_parent_title)
          expect(grandchild.reload.title).to eq(updated_grandchild_title)
          expect(grandchild.num).to eq(updated_grandchild_num)
        end
      end
    end
  end
end
