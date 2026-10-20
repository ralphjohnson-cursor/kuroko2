require 'rails_helper'

describe Kuroko2::JobInstance do
  let(:log) { Kuroko2::Log.take }

  describe '#logs' do
    let(:definition) { create(:job_definition) }
    let(:instance) { create(:job_instance, job_definition: definition) }

    it do
      instance.logs.info('log info')
      expect(log.level).to eq 'INFO'
    end
  end

  describe '#initialize' do
    let(:definition) { create(:job_definition) }
    let(:instance) { definition.job_instances.create! }

    it do
      expect(instance.tokens.count).to eq 1
      expect(instance.reload.tokens.count).to eq 1
      expect(instance.tokens.first.script).to eq instance.job_definition.script
    end

    context 'Overwrite script on creating' do
      let(:script) { 'env: ALTERNATIVE=1' }
      let(:instance) { definition.job_instances.create!(script: script) }

      it 'Inject alternative script to the instance' do
        expect(instance.tokens.count).to eq 1
        expect(instance.tokens.first.script).to eq script
      end
    end
  end

  describe '#cancel' do
    let(:definition) { create(:job_definition) }
    let(:instance) { definition.job_instances.create! }

    subject! { instance.cancel(by: 'test') }

    it do
      expect(instance).to be_canceled_at
      expect(instance.tokens.size).to eq 0
      expect(instance.executions.size).to eq 0
    end
  end

  describe '#generate_token' do
    before do
      ActionMailer::Base.deliveries.clear
      create(:job_instance, job_definition: definition)
    end
    subject! { definition.job_instances.create }

    context 'notify_cancellation is false' do
      let(:definition) { create(:job_definition, notify_cancellation: false, prevent_multi: true) }

      it { expect(ActionMailer::Base.deliveries).to be_empty }
    end

    context 'notify_cancellation is false' do
      let(:definition) { create(:job_definition, notify_cancellation: true, prevent_multi: true) }

      it { expect(ActionMailer::Base.deliveries).not_to be_empty }
    end
  end

  describe '#status' do
    let(:instance) do
      create(
        :job_instance,
        finished_at:    finished_at,
        error_at:       error_at,
        canceled_at:    canceled_at,
        job_definition: definition,
      )
    end
    let(:finished_at) { nil }
    let(:error_at)    { nil }
    let(:canceled_at) { nil }
    let(:definition) { create(:job_definition) }

    context 'with finished_at present' do
      let(:finished_at) { Time.current }

      it 'returns "success"' do
        expect(instance.status).to eq('success')
      end
    end

    context 'with canceled_at present' do
      let(:canceled_at) { Time.current }

      it 'returns "canceled"' do
        expect(instance.status).to eq('canceled')
      end
    end

    context 'with error_at present' do
      let(:error_at) { Time.current }

      it 'returns "error"' do
        expect(instance.status).to eq('error')
      end
    end

    context 'when no timestamp is set' do
      it 'returns "working"' do
        expect(instance.status).to eq('working')
      end
    end
  end

  describe '#working? and #error?' do
    let(:definition) { create(:job_definition) }
    let(:instance) { create(:job_instance, job_definition: definition, error_at: Time.current) }

    it 'treats an unfinished instance with error_at as an error' do
      expect(instance).to be_working
      expect(instance.error?).to eq(true)
    end

    it 'stops being an error after the instance finishes or is canceled' do
      instance.update!(finished_at: Time.current)
      expect(instance).not_to be_working
      expect(instance.error?).to eq(false)

      instance.update!(finished_at: nil, canceled_at: Time.current)
      expect(instance).not_to be_working
      expect(instance.error?).to eq(false)
    end
  end

  describe '#cancelable?' do
    let(:definition) { create(:job_definition) }
    let(:instance) { create(:job_instance, job_definition: definition) }

    it 'follows the first token' do
      instance.tokens.first.update!(status: Kuroko2::Token::FAILURE)
      expect(instance.cancelable?).to eq(true)

      instance.tokens.first.update!(status: Kuroko2::Token::WORKING)
      expect(instance.cancelable?).to eq(false)
    end

    it 'is nil when the instance has no token' do
      instance.tokens.destroy_all

      expect(instance.cancelable?).to be_nil
    end
  end

  describe '#execution_minutes' do
    let(:definition) { create(:job_definition) }
    let(:instance) { create(:job_instance, job_definition: definition) }
    let(:created) { Time.zone.parse('2026-01-01 00:00:00') }

    it 'prefers error_at, then canceled_at, then finished_at' do
      instance.update_columns(
        created_at: created,
        error_at: created + 10.minutes,
        canceled_at: created + 20.minutes,
        finished_at: created + 50.minutes,
      )
      expect(instance.execution_minutes).to eq(10.0)

      instance.update_columns(error_at: nil)
      expect(instance.execution_minutes).to eq(20.0)

      instance.update_columns(canceled_at: nil)
      expect(instance.execution_minutes).to eq(50.0)
    end

    it 'uses the current time while the instance is still running' do
      instance.update_columns(created_at: created, error_at: nil, canceled_at: nil, finished_at: nil)

      Timecop.freeze(created + 90.minutes + 30.seconds) do
        expect(instance.execution_minutes).to eq(90.5)
      end
    end
  end

  describe '#log_memory_consumption' do
    let(:definition) { create(:job_definition) }
    let(:instance) { create(:job_instance, job_definition: definition) }

    it 'keeps the larger consumption value' do
      instance.log_memory_consumption(5)
      instance.log_memory_consumption(3)

      expect(instance.memory_consumption_log.value).to eq(5)

      instance.log_memory_consumption(8)
      expect(instance.memory_consumption_log.reload.value).to eq(8)
    end
  end
end
