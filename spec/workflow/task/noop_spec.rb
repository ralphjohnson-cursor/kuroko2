require 'rails_helper'

module Kuroko2::Workflow::Task
  describe Noop do
    describe '#execute' do
      let(:token) { build(:token) }
      let(:node) { Kuroko2::Workflow::Node.new(:noop) }

      it 'logs and continues to the next node' do
        expect(Kuroko2.logger).to receive(:info).with("(token #{token.uuid}) NOOP")

        expect(Noop.new(node, token).execute).to eq :next
      end
    end
  end
end
