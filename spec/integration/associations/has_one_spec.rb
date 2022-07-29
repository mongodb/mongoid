# frozen_string_literal: true

require 'spec_helper'
require 'mongoid/association/referenced/has_one_models'

describe 'has_one associations' do
  context 'destroying parent in transaction with dependent child' do
    require_transaction_support

    let(:college) { HomCollege.create! }
    let(:address) { HomAddress.create!(college: college) }

    before do
      HomCollege.delete_all
      HomAddress.delete_all
    end

    context 'dependent: :destroy' do
      before do
        HomCollege.class_eval do
          has_one :address, class_name: 'HomAddress', dependent: :destroy
        end
      end

      it 'destroys' do
        address

        HomCollege.count.should == 1
        HomAddress.count.should == 1

        HomCollege.with_session do |session|
          session.with_transaction do
            college.destroy!
          end
        end

        HomCollege.count.should == 0
        HomAddress.count.should == 0
      end
    end

    context 'dependent: :restrict_with_error' do
      before do
        HomCollege.class_eval do
          has_one :address, class_name: 'HomAddress', dependent: :restrict_with_error
        end
      end

      it 'does not destroy' do
        address

        HomCollege.count.should == 1
        HomAddress.count.should == 1

        lambda do
          HomCollege.with_session do |session|
            session.with_transaction do
              college.destroy!
            end
          end
        end.should raise_error(Mongoid::Errors::DocumentNotDestroyed)

        HomCollege.count.should == 1
        HomAddress.count.should == 1
      end
    end
  end

  context 'when calling methods on target' do
    let(:parent) do
      HomCollege.create!.tap do |college|
        HomAccreditation.create!(college: college)
      end
    end

    shared_examples 'delegates to the field' do |reloaded: false|
      context 'non-conflicting field name' do
        it 'delegates to the field' do
          parent.accreditation.price.should == 42
        end

        context 'using send' do
          it 'delegates to the field' do
            parent.accreditation.send(:price).should == 42
          end
        end
      end

      context 'field name that conflicts with Kernel' do
        it 'delegates to the field' do
          parent.accreditation.format.should == 'fmt'
        end

        context 'using send' do
          it 'delegates to the field' do
            if reloaded
              pending 'MONGOID-5018'
            end

            parent.accreditation.send(:format).should == 'fmt'
          end
        end
      end
    end

    include_examples 'delegates to the field'

    context 'after reloading parent' do
      before do
        parent.reload
      end

      include_examples 'delegates to the field', reloaded: true
    end
  end

  context 'when child does not have parent association' do
    context 'Child.new' do
      it 'creates a child instance' do
        HomBusDriver.new.should be_a(HomBusDriver)
      end
    end

    context 'assignment to child in parent' do
      let(:parent) { HomBus.new }

      it 'raises InverseNotFound' do
        lambda do
          parent.driver = HomBusDriver.new
        end.should raise_error(Mongoid::Errors::InverseNotFound)
      end
    end
  end

  context 're-associating the same object' do
    context 'with dependent: destroy' do
      let(:person) do
        Person.create!
      end

      let!(:game) do
        Game.create!(person: person) do
          person.reload
        end
      end

      it 'does not destroy the dependent object' do
        person.game.should == game
        person.game = person.game
        person.save!
        person.reload
        person.game.should == game
      end
    end

    context 'without dependent: destroy' do
      let(:person) do
        Person.create!
      end

      let!(:account) do
        Account.create!(person: person, name: 'foo').tap do
          person.reload
        end
      end

      it 'does not destroy the dependent object' do
        person.account.should == account
        person.account = person.account
        person.save!
        person.reload
        person.account.should == account
      end
    end
  end

  context "when assigning to a has_one" do
    let(:post) { HomPost.create! }
    let(:comment1) { HomComment.create!(content: "Comment 1") }

    context "when assigning the same value" do
      let(:comment2) { HomComment.create! }

      it "persists it correctly" do
        post.comment = comment1
        post.reload
        expect(post.comment).to eq(comment1)

        post.comment = comment1
        post.reload
        expect(post.comment).to eq(comment1)
      end
    end

    context "when assigning two values with the same _id" do
      let(:comment2) { HomComment.new(id: comment1.id) }

      it "raises a duplicate key error" do
        post.comment = comment1
        expect do
          post.comment = comment2
        end.to raise_error(Mongo::Error::OperationFailure, /duplicate key/)
      end
    end

    context "when duping the object and changing attributes" do
      let(:comment2) { comment1.dup }

      before do
        comment2.content = "Comment 2"

        post.comment = comment1
        post.reload
      end

      it "updates the attributes correctly" do
        post.comment = comment2
        post.reload

        expect(post.comment).to eq(comment2)
        expect(post.comment.content).to eq(comment2.content)
      end
    end

    context "when explicitly setting the foreign key" do
      let(:comment2) { HomComment.new(post_id: post.id, content: "2") }

      it "persists the new comment" do
        post.comment = comment1
        post.reload

        post.comment = comment2
        post.reload

        expect(post.comment).to eq(comment2)
        expect(post.comment.content).to eq(comment2.content)
      end
    end

    context "when reassigning the same value" do
      let(:comment2) { HomComment.create!(content: "Comment 2") }

      it "persists it correctly" do
        post.comment = comment1
        post.reload
        expect(post.comment).to eq(comment1)

        post.comment = comment2
        post.reload
        expect(post.comment).to eq(comment2)

        post.comment = comment1
        post.reload
        expect(post.comment).to eq(nil)
      end
    end
  end

  context "when overwriting an association" do
    let(:post1) { HomPost.create!(title: "post 1") }
    let(:post2) { HomPost.create!(title: "post 2") }
    let(:comment) { HomComment.create(post: post1) }

    it "does not overwrite the original value" do
      pending "MONGOID-3999"
      p1 = comment.post
      expect(p1.title).to eq("post 1")
      comment.post = post2
      expect(p1.title).to eq("post 1")
    end
  end
end
