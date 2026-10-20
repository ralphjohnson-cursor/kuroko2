require 'rails_helper'

module Kuroko2::Workflow
  describe Notifier do
    let(:instance) { create(:job_instance) }

    describe '.notify' do
      it 'logs a warning and continues when one notifier raises' do
        mail = instance_double(Notifier::Mail)
        allow(Notifier::Mail).to receive(:new).and_return(mail)
        allow(mail).to receive(:notify_failure).and_raise(RuntimeError, 'smtp down')
        allow(Notifier::Slack).to receive(:new).and_return(instance_double(Notifier::Slack, notify_failure: nil))
        allow(Notifier::Hipchat).to receive(:new).and_return(instance_double(Notifier::Hipchat, notify_failure: nil))
        allow(Notifier::Webhook).to receive(:new).and_return(instance_double(Notifier::Webhook, notify_failure: nil))

        expect(Kuroko2.logger).to receive(:warn).with(/Failure to notify failure.*smtp down/)

        expect { Notifier.notify(:failure, instance) }.not_to raise_error
      end
    end
  end
end
