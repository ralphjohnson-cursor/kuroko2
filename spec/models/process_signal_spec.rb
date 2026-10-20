require 'rails_helper'

describe Kuroko2::ProcessSignal do
  let(:hostname) { 'worker-a' }
  let(:token) { create(:token) }
  let(:execution) { create(:execution, token: token, pid: 4242) }
  let!(:worker) { create(:worker, hostname: hostname, execution: execution) }

  def create_signal(attrs = {})
    create(:process_signal, { pid: 4242, execution: execution }.merge(attrs))
  end

  describe '.poll' do
    it 'claims one unstarted signal for the worker hostname and stamps started_at' do
      signal = create_signal

      claimed = described_class.poll(hostname)

      expect(claimed).to eq(signal)
      expect(claimed.reload.started_at).to be_present
      expect(described_class.poll(hostname)).to be_nil
    end

    it 'ignores signals whose worker is on another host' do
      create_signal

      expect(described_class.poll('other-host')).to be_nil
      expect(described_class.poll(hostname).started_at).to be_present
    end

    it 'ignores signals that have already started' do
      create_signal(started_at: Time.current)

      expect(described_class.poll(hostname)).to be_nil
    end

    it 'ignores a signal whose execution has no worker' do
      orphan = create(:execution, token: create(:token), pid: 9)
      create(:process_signal, pid: 9, execution: orphan)

      expect(described_class.poll(hostname)).to be_nil
    end

    it 'claims only one signal when several are waiting' do
      first = create_signal(pid: 1)
      second = create_signal(pid: 2)

      claimed = [described_class.poll(hostname), described_class.poll(hostname)]

      expect(claimed).to contain_exactly(first, second)
      expect(claimed.map { |signal| signal.reload.started_at }).to all(be_present)
      expect(described_class.poll(hostname)).to be_nil
    end
  end
end
