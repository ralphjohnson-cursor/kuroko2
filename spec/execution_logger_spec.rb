require 'rails_helper'

describe Kuroko2::ExecutionLogger do
  describe '.get_logger' do
    it 'builds the configured logger and forwards call options' do
      logger = described_class.get_logger(stream_name: 'JOB0000000001/2')

      expect(logger).to be_a(Kuroko2::ExecutionLogger::Void)
    end

    it 'merges configured options with call options' do
      config = Hashie::Mash.new(
        type: 'CloudWatchLogs',
        option: { group_name: 'kuroko', region: 'us-east-1' },
      )
      allow(Kuroko2.config).to receive(:execution_logger).and_return(config)
      allow(Aws::CloudWatchLogs::Client).to receive(:new).and_return(double('CloudWatchLogsClient'))

      logger = described_class.get_logger(stream_name: 'stream')

      expect(logger).to be_a(Kuroko2::ExecutionLogger::CloudWatchLogs)
      expect(Aws::CloudWatchLogs::Client).to have_received(:new).with(region: 'us-east-1')
    end

    it 'builds the configured logger when no extra options are configured' do
      allow(Kuroko2.config).to receive(:execution_logger).and_return(Hashie::Mash.new(type: 'Void'))

      logger = described_class.get_logger(stream_name: 'stream')

      expect(logger).to be_a(Kuroko2::ExecutionLogger::Void)
    end

    it 'falls back to the void logger when execution logging is unconfigured' do
      allow(Kuroko2.config).to receive(:execution_logger).and_return(nil)

      expect(described_class.get_logger).to be_a(Kuroko2::ExecutionLogger::Void)
    end
  end
end

describe Kuroko2::ExecutionLogger::Void do
  subject(:logger) { described_class.new(stream_name: 'unused') }

  describe '#send_log' do
    it 'discards the message' do
      expect(logger.send_log('hello')).to be_nil
    end
  end

  describe '#get_logs' do
    it 'raises when logs are requested' do
      expect { logger.get_logs('token') }.to raise_error(Kuroko2::ExecutionLogger::NotFound)
    end
  end
end
