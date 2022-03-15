# frozen_string_literal: true

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

  context 'when comparing Time objects' do
    let(:time) {Time.utc(2021, 10, 25, 10, 30, 30, 581345)}
    let(:document) do
      ConsumptionPeriod.new(:started_at => time)
    end

    context 'comparing millisecond precision' do
      let(:time_millis) {Time.utc(2021, 10, 25, 10, 30, 30, 581774)}

      context "when compare_time_by_ms feature flag is set" do
        config_override :compare_time_by_ms, true

        context 'with exact match' do
          let(:query) do
            {'started_at' => time_millis}
          end

          it_behaves_like 'is true'

          context 'and query has different timezone' do
            let(:time_millis) do
              Time.utc(2021, 10, 25, 10, 30, 30, 581345).in_time_zone("Stockholm")
            end

            it_behaves_like 'is true'
          end
        end

        context 'with $in' do
          let(:query) do
            {'started_at' => {:$in => [time_millis]}}
          end

          it_behaves_like 'is true'
        end

        context 'when matching an element in an array' do
          let(:document) do
            Mop.new(:array_field => [time])
          end

          context 'with equals match' do
            let(:query) do
              {'array_field' => time_millis}
            end

            it_behaves_like 'is true'
          end
        end
      end

      context "when compare_time_by_ms feature flag is not set" do
        config_override :compare_time_by_ms, false

        context 'with exact match' do
          let(:query) do
            {'started_at' => time_millis}
          end

          it_behaves_like 'is false'

          context 'and query has different timezone' do
            let(:time_millis) do
              Time.utc(2021, 10, 25, 10, 30, 30, 581345).in_time_zone("Stockholm")
            end

            it_behaves_like 'is true'
          end
        end

        context 'with $in' do
          let(:query) do
            {'started_at' => {:$in => [time_millis]}}
          end

          it_behaves_like 'is false'
        end

        context 'when matching an element in an array' do
          let(:document) do
            Mop.new(:array_field => [time])
          end

          context 'with equals match' do
            let(:query) do
              {'array_field' => time_millis}
            end

            it_behaves_like 'is false'
          end
        end
      end
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
