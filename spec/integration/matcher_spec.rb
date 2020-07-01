# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'

describe 'Matcher operators' do
  let(:result) do
    document._matches?(query)
  end

  shared_examples 'is true' do
    it 'is true' do
      result.should be true
    end
  end

  shared_examples 'is false' do
    it 'is false 'do
      result.should be false
    end
  end

  context 'when querying nested document' do
    context 'embeds_one' do
      let(:document) do
        Canvas.new(
          writer: Writer.new(speed: 3),
        )
      end

      context 'implicit $eq' do
        context 'matches' do
          let(:query) do
            {'writer.speed' => 3}
          end

          it_behaves_like 'is true'
        end

        context 'does not match' do
          let(:query) do
            {'speed' => 3}
          end

          it_behaves_like 'is false'
        end
      end

      context 'field operator' do
        # Test string and symbol operators
        ['$gt', :$gt].each do |op|
          context op.inspect do
            context 'matches' do
              let(:query) do
                {'writer.speed' => {op => 2}}
              end

              it_behaves_like 'is true'
            end

            context 'does not match' do
              let(:query) do
                {'writer.speed' => {op => 3}}
              end

              it_behaves_like 'is false'
            end
          end
        end
      end

      context 'hash query' do
        context 'scalar field in embedded document' do
          context 'matches' do
            let(:query) do
              {writer: {speed: 3}}
            end

            it_behaves_like 'is true'
          end

          context 'does not match' do
            let(:query) do
              {writer: {slow: 3}}
            end

            it_behaves_like 'is false'
          end
        end

        context 'hash field' do
          let(:document) do
            Bar.new(
              writer: {speed: 3},
            )
          end

          context 'matches' do
            let(:query) do
              {writer: {speed: 3}}
            end

            it_behaves_like 'is true'
          end

          context 'does not match' do
            let(:query) do
              {writer: {slow: 3}}
            end

            it_behaves_like 'is false'
          end
        end
      end
    end

    context 'embeds_many' do
      let(:document) do
        Survey.new(
          questions: [Question.new(
            answers: [
              Answer.new(position: 3),
              Answer.new(position: 4),
            ],
          )],
        )
      end

      context 'implicit $eq' do
        context 'matches' do
          let(:query) do
            {'questions.answers.position' => 3}
          end

          it_behaves_like 'is true'
        end

        context 'does not match' do
          let(:query) do
            {'questions.answers.position' => 2}
          end

          it_behaves_like 'is false'
        end
      end

      context 'field operator' do
        # Test string and symbol operators
        ['$gt', :$gt].each do |op|
          context op.inspect do
            context 'matches' do
              let(:query) do
                {'questions.answers.position' => {op => 2}}
              end

              it_behaves_like 'is true'
            end

            context 'does not match' do
              let(:query) do
                {'questions.answers.position' => {op => 4}}
              end

              it_behaves_like 'is false'
            end
          end
        end
      end

      context 'array index' do
        context 'matches' do
          let(:query) do
            {'questions.answers.1' => {position: 4}}
          end

          it_behaves_like 'is true'
        end

        context 'does not match' do
          let(:query) do
            {'questions.answers.0' => {position: 4}}
          end

          it_behaves_like 'is false'
        end
      end
    end
  end
end
