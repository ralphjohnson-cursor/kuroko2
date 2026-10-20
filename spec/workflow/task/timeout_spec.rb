require 'rails_helper'

module Kuroko2::Workflow::Task
  describe Timeout do
    let(:token) { build(:token, context: {}) }

    it 'stores a duration in minutes under TIMEOUT' do
      node = Kuroko2::Workflow::Node.new(:timeout, '2h')

      expect(described_class.new(node, token).execute).to eq(:next)
      expect(token.context['TIMEOUT']).to eq(120)
    end

    it 'accepts a bare number and a minute suffix' do
      node = Kuroko2::Workflow::Node.new(:timeout, '15m')
      described_class.new(node, token).execute
      expect(token.context['TIMEOUT']).to eq(15)

      plain = Kuroko2::Workflow::Node.new(:timeout, '9')
      described_class.new(plain, token).execute
      expect(token.context['TIMEOUT']).to eq(9)
    end

    it 'leaves the context unchanged when the option is blank' do
      node = Kuroko2::Workflow::Node.new(:timeout)

      expect(described_class.new(node, token).execute).to eq(:next)
      expect(token.context).to eq({})
    end

    it 'rejects a value that is not a duration' do
      node = Kuroko2::Workflow::Node.new(:timeout, 'soon')

      expect { described_class.new(node, token).execute }.to raise_error(
        Kuroko2::Workflow::AssertionError,
        'A value of TIMEOUT should be a number.',
      )
    end
  end
end
