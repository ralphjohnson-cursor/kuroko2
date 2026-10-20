require 'rails_helper'

describe Kuroko2::ProcessSignal do
  describe '.poll' do
    let(:token) { create(:token) }
    let(:execution) { create(:execution, token: token) }
    let!(:worker) { create(:worker, hostname: 'worker-a', execution: execution) }
    let!(:signal) do
      described_class.create!(execution: execution, pid: 4242, hostname: 'ignored')
    end

    it 'returns the unstarted signal for the worker hostname and marks it started' do
      polled = described_class.poll('worker-a')

      expect(polled).to eq signal
      expect(polled.started_at).to be_present
      expect(signal.reload.started_at).to be_present
    end

    it 'does not return a signal that has already started' do
      signal.update!(started_at: Time.current)

      expect(described_class.poll('worker-a')).to be_nil
    end

    it 'does not return a signal running on another host' do
      expect(described_class.poll('worker-b')).to be_nil
      expect(signal.reload.started_at).to be_nil
    end
  end
end
