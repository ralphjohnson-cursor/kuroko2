require 'rails_helper'

describe Kuroko2::Execution do

  describe '#completed?' do
    let(:token) { create(:token) }

    it 'is true only after the execution has both started and finished' do
      running = create(:execution, token: token, started_at: Time.current, finished_at: nil)
      done = create(:execution, token: create(:token), started_at: Time.current, finished_at: Time.current)
      queued = create(:execution, token: create(:token), started_at: nil, finished_at: nil)

      expect(done).to be_completed
      expect(running).not_to be_completed
      expect(queued).not_to be_completed
    end
  end

  describe '#success?' do
    let(:token) { create(:token) }

    it 'is true only when the exit status is zero' do
      expect(create(:execution, token: token, exit_status: 0)).to be_success
      expect(create(:execution, token: create(:token), exit_status: 1)).not_to be_success
      expect(create(:execution, token: create(:token), exit_status: nil)).not_to be_success
    end
  end

  describe '#finish' do
    let(:token) { create(:token) }
    let(:execution) { create(:execution, token: token, output: nil, exit_status: nil, finished_at: nil) }

    it 'stores the output, exit status, and finished time' do
      finished_at = Time.zone.parse('2020-01-02 03:04:05')

      Timecop.freeze(finished_at) do
        execution.finish(output: 'done', exit_status: 0)
      end

      execution.reload
      expect(execution.output).to eq 'done'
      expect(execution.exit_status).to eq 0
      expect(execution.finished_at).to eq finished_at
    end
  end

  describe '#finish_by_signal' do
    let(:token) { create(:token) }
    let(:execution) { create(:execution, token: token, output: nil, term_signal: nil, finished_at: nil) }

    it 'stores the output, terminating signal, and finished time' do
      finished_at = Time.zone.parse('2020-01-02 03:04:05')

      Timecop.freeze(finished_at) do
        execution.finish_by_signal(output: 'killed', term_signal: 15)
      end

      execution.reload
      expect(execution.output).to eq 'killed'
      expect(execution.term_signal).to eq 15
      expect(execution.finished_at).to eq finished_at
    end
  end

  describe 'default values' do
    it 'assigns a uuid and an empty context before create' do
      token = create(:token)
      execution = described_class.create!(
        token: token,
        job_definition: token.job_definition,
        job_instance: token.job_instance,
        shell: 'echo hi',
        context: nil,
        uuid: nil,
      )

      expect(execution.uuid).to be_present
      expect(execution.context).to eq({})
    end
  end

  describe '.poll' do
    context 'with active execution' do
      let(:definition) { token.job_instance.job_definition }
      let(:token) { create(:token) }

      context 'default queue' do
        subject { Kuroko2::Execution.poll }
        let!(:execution) { create(:execution, job_definition: definition, token: token, started_at: nil) }

        it { is_expected.to eq execution }
      end

      context 'given queue' do
        subject { Kuroko2::Execution.poll(queue) }
        let!(:execution) { create(:execution, job_definition: definition, token: token, started_at: nil, queue: queue) }
        let(:queue) { 'QUEUE' }

        it { is_expected.to eq execution }
      end
    end
  end
end
