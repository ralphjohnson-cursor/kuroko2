require 'rails_helper'

describe Kuroko2::Worker do
  describe '.on' do
    let!(:local) { create(:worker, hostname: 'app-1', worker_id: 1) }
    let!(:remote) { create(:worker, hostname: 'app-2', worker_id: 1) }

    it 'returns workers on the given hostname' do
      expect(described_class.on('app-1')).to contain_exactly(local)
      expect(described_class.on('app-1')).not_to include(remote)
    end
  end

  describe '.ordered' do
    it 'orders by hostname and then worker id' do
      second = create(:worker, hostname: 'b', worker_id: 1)
      third = create(:worker, hostname: 'b', worker_id: 2)
      first = create(:worker, hostname: 'a', worker_id: 9)

      expect(described_class.ordered).to eq [first, second, third]
    end
  end

  describe '.executing' do
    let(:token) { create(:token) }
    let(:execution) { create(:execution, token: token) }
    let!(:worker) { create(:worker, execution: execution) }

    it 'returns the worker assigned to the execution' do
      expect(described_class.executing(execution.id)).to eq worker
    end

    it 'returns nil when no worker is assigned' do
      expect(described_class.executing(-1)).to be_nil
    end
  end
end
