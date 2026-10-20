require 'rails_helper'

describe Kuroko2::ExecutionLogger do
  describe '.get_logger' do
    let(:config) { Kuroko2.config }

    around do |example|
      original = config.execution_logger
      example.run
    ensure
      config.execution_logger = original
    end

    it 'returns Void for the configured Void logger' do
      expect(described_class.get_logger(stream_name: 'JOB')).to be_a(described_class::Void)
    end

    it 'returns Void when no logger type is configured' do
      config.execution_logger = nil

      expect(described_class.get_logger(stream_name: 'JOB')).to be_a(described_class::Void)
    end

    it 'merges configured options with call options' do
      probe = Class.new do
        def initialize(**kwargs)
          @kwargs = kwargs
        end
        attr_reader :kwargs
      end
      stub_const('Kuroko2::ExecutionLogger::Probe', probe)
      config.execution_logger = Hashie::Mash.new(
        type: 'Probe',
        option: { 'group_name' => 'kuroko', 'region' => 'ap-northeast-1' },
      )

      logger = described_class.get_logger(stream_name: 'JOB1', region: 'us-east-1')

      expect(logger.kwargs).to eq(
        group_name: 'kuroko',
        region: 'us-east-1',
        stream_name: 'JOB1',
      )
    end
  end

  describe Kuroko2::ExecutionLogger::Void do
    subject(:logger) { described_class.new(stream_name: 'JOB') }

    it 'drops sent logs' do
      expect(logger.send_log('hello')).to be_nil
    end

    it 'raises NotFound when logs are requested' do
      expect { logger.get_logs('token') }.to raise_error(Kuroko2::ExecutionLogger::NotFound)
    end
  end
end
