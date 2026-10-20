require 'rails_helper'

describe Kuroko2::Worker do
  describe '.on' do
    it 'filters by hostname' do
      local = create(:worker, hostname: 'app-1', worker_id: 1)
      create(:worker, hostname: 'app-2', worker_id: 1)

      expect(described_class.on('app-1')).to eq([local])
    end
  end

  describe '.ordered' do
    it 'orders by hostname and worker id' do
      second_host = create(:worker, hostname: 'b', worker_id: 1)
      first_host_second = create(:worker, hostname: 'a', worker_id: 2)
      first_host_first = create(:worker, hostname: 'a', worker_id: 1)

      expect(described_class.ordered).to eq([first_host_first, first_host_second, second_host])
    end
  end

  describe '.executing' do
    it 'finds the worker running an execution' do
      execution = create(:execution)
      worker = create(:worker, execution: execution)
      create(:worker)

      expect(described_class.executing(execution.id)).to eq(worker)
    end

    it 'returns nil when no worker is running the execution' do
      expect(described_class.executing(-1)).to be_nil
    end
  end
end
