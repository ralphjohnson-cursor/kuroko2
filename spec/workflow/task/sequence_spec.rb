require 'rails_helper'

module Kuroko2::Workflow::Task
  describe Sequence do
    describe '#execute' do
      let(:token) { build(:token) }
      let(:node) { Kuroko2::Workflow::Node.new(:sequence, 'daily') }

      it 'logs the option and continues to the next node' do
        expect(Kuroko2.logger).to receive(:info).with("(token #{token.uuid}) Sequence is executed with option 'daily'")

        expect(Sequence.new(node, token).execute).to eq :next
      end
    end
  end
end
