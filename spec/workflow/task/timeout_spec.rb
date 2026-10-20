require 'rails_helper'

module Kuroko2::Workflow::Task
  describe Timeout do
    describe '#execute' do
      let(:token) { build(:token, context: {}) }
      subject { Timeout.new(node, token).execute }

      context 'with a number of hours' do
        let(:node) { Kuroko2::Workflow::Node.new(:timeout, '2h') }

        it 'stores the timeout in minutes' do
          expect(subject).to eq :next
          expect(token.context['TIMEOUT']).to eq 120
        end
      end

      context 'with a number of minutes' do
        let(:node) { Kuroko2::Workflow::Node.new(:timeout, '15m') }

        it 'stores the timeout as minutes' do
          subject
          expect(token.context['TIMEOUT']).to eq 15
        end
      end

      context 'without an option' do
        let(:node) { Kuroko2::Workflow::Node.new(:timeout) }

        it 'leaves the context unchanged' do
          expect(subject).to eq :next
          expect(token.context).to eq({})
        end
      end

      context 'with a non numeric option' do
        let(:node) { Kuroko2::Workflow::Node.new(:timeout, 'soon') }

        it 'raises an assertion error' do
          expect { subject }.to raise_error(Kuroko2::Workflow::AssertionError, /TIMEOUT/)
        end
      end
    end
  end
end
