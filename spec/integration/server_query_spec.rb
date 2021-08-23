# frozen_string_literal: true

require 'spec_helper'

# This file serves as a record of server query behavior.

describe 'Server queries' do

  context 'scalar operator on scalar field' do
    let!(:document) do
      Survey.create!(
        questions: [Question.new(
          answers: [Answer.new(position: 3)],
        )],
      )
    end

    let(:query) do
      {'questions.answers.position' => {'$gt' => 2}}
    end

    it 'finds' do
      Survey.collection.find(query).to_a.should == [document.attributes]
    end
  end

  context 'scalar operator on array field' do
    let!(:document) do
      Bar.create!(
        questions: [
          answers: [
            position: [3],
          ],
        ],
      )
    end

    context '$eq with scalar on array field' do
      let(:query) do
        {'questions.answers.position' => {'$eq' => 3}}
      end

      it 'finds' do
        Bar.collection.find(query).to_a.should == [document.attributes.with_indifferent_access]
      end
    end

    context '$ne with scalar on array field' do
      context 'same value as array item' do
        let(:query) do
          {'questions.answers.position' => {'$ne' => 3}}
        end

        it 'matches array and does not find' do
          Bar.collection.find(query).to_a.should == []
        end
      end

      context 'different value from array items' do
        let(:query) do
          {'questions.answers.position' => {'$ne' => 2}}
        end

        it 'finds' do
          Bar.collection.find(query).to_a.should == [document.attributes.with_indifferent_access]
        end
      end
    end

    context '$gt on array field' do
      let(:query) do
        {'questions.answers.position' => {'$gt' => 2}}
      end

      it 'finds' do
        # This finds the document - https://jira.mongodb.org/browse/DOCSP-10717
        Bar.collection.find(query).to_a.should == [document.attributes.with_indifferent_access]
      end
    end

    context '$in on a double array field' do
      let!(:document) do
        Bar.create!(
          questions: [
            answers: [
              position: [[3]],
            ],
          ],
        )
      end

      let(:query) do
        {'questions.answers.position' => {'$in' => [3]}}
      end

      it 'does not find' do
        Bar.collection.find(query).to_a.should == []
      end
    end

    context '$in on an array field' do
      let!(:document) do
        Bar.create!(
          questions: [
            answers: [
              position: [3],
            ],
          ],
        )
      end

      let(:query) do
        {'questions.answers.position' => {'$in' => [3]}}
      end

      it 'finds' do
        Bar.collection.find(query).to_a.should == [document.attributes.with_indifferent_access]
      end
    end

    context '$in on a scalar field' do
      let!(:document) do
        Bar.create!(
          questions: [
            answers: [
              position: 3,
            ],
          ],
        )
      end

      let(:query) do
        {'questions.answers.position' => {'$in' => [3]}}
      end

      it 'finds' do
        Bar.collection.find(query).to_a.should == [document.attributes.with_indifferent_access]
      end
    end
  end
end
