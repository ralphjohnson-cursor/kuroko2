require 'rails_helper'

module Kuroko2::Command
  describe Executor do
    describe '.num_workers' do
      before do
        described_class.instance_variable_set(:@num_workers, nil)
      end

      after do
        described_class.instance_variable_set(:@num_workers, nil)
      end

      it 'counts the default workers plus the master and monitor' do
        expect(described_class.num_workers).to eq(
          described_class::DEFAULT_NUM_WORKERS + described_class::NUM_SYSTEM_WORKERS
        )
      end

      it 'adds the system workers to NUM_WORKERS' do
        ENV['NUM_WORKERS'] = '1'

        expect(described_class.num_workers).to eq 3
      end
    end
  end
end
