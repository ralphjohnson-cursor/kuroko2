require 'rails_helper'

describe Kuroko2::Token do
  describe '#cancelable?' do
    context 'without children' do
      context 'working' do
        subject! { create(:token, status: Kuroko2::Token::WORKING) }

        it { is_expected.not_to be_cancelable }
      end
      context 'finished' do
        subject! { create(:token, status: Kuroko2::Token::FINISHED) }

        it { is_expected.not_to be_cancelable }
      end
      context 'failure' do
        subject! { create(:token, status: Kuroko2::Token::FAILURE) }

        it { is_expected.to be_cancelable }
      end
      context 'critical' do
        subject! { create(:token, status: Kuroko2::Token::CRITICAL) }

        it { is_expected.not_to be_cancelable }
      end
    end

    context 'with children' do
      subject!(:parent) { create(:token, status: Kuroko2::Token::WORKING) }

      context 'all children are working' do
        before { create(:token, parent_id: parent.id, status: Kuroko2::Token::WORKING) }
        before { create(:token, parent_id: parent.id, status: Kuroko2::Token::WORKING) }

        it { is_expected.not_to be_cancelable }
      end

      context 'working and failrue' do
        before { create(:token, parent_id: parent.id, status: Kuroko2::Token::WORKING) }
        before { create(:token, parent_id: parent.id, status: Kuroko2::Token::FAILURE) }

        it { is_expected.not_to be_cancelable }
      end

      context 'finished and failure' do
        before { create(:token, parent_id: parent.id, status: Kuroko2::Token::FINISHED) }
        before { create(:token, parent_id: parent.id, status: Kuroko2::Token::FAILURE) }

        it { is_expected.to be_cancelable }
      end

    end
  end

  describe "#skippable?" do
    subject! { create(:token, status: status) }

    context 'When token is failure status' do
      let(:status) { Kuroko2::Token::FAILURE }
      it { is_expected.to be_skippable }
    end

    context 'When token is waiting status' do
      let(:status) { Kuroko2::Token::WAITING }
      it { is_expected.to be_skippable }
    end

    context 'When token is working status' do
      let(:status) { Kuroko2::Token::WORKING }
      it { is_expected.not_to be_skippable }
    end
  end

  describe 'status predicates' do
    {
      Kuroko2::Token::WORKING => :working?,
      Kuroko2::Token::FAILURE => :failure?,
      Kuroko2::Token::FINISHED => :finished?,
      Kuroko2::Token::CRITICAL => :critical?,
      Kuroko2::Token::WAITING => :waiting?,
    }.each do |status, predicate|
      it "is #{predicate} when the status is #{status}" do
        token = create(:token, status: status)

        expect(token.public_send(predicate)).to eq true
        described_class::STATUSES.keys.reject { |other| other == status }.each do |other|
          expect(create(:token, status: other).public_send(predicate)).to eq false
        end
      end
    end
  end

  describe 'status transitions' do
    let(:token) { create(:token, status: Kuroko2::Token::WORKING, message: '') }

    it 'marks failure, critical, finished, working, and waiting' do
      token.mark_as_failure
      expect(token).to be_failure

      error = StandardError.new('disk full')
      token.mark_as_critical(error)
      expect(token).to be_critical
      expect(token.message).to eq 'disk full'
      expect(token.status_name).to eq 'critical'

      token.mark_as_finished
      expect(token).to be_finished
      expect(token.status_name).to eq 'finished'

      token.mark_as_working
      expect(token).to be_working

      token.mark_as_waiting
      expect(token).to be_waiting
      expect(token.status_name).to eq 'waiting'
    end
  end

  describe 'scopes' do
    def isolated_token(status)
      token = create(:token, status: status)
      described_class.where(job_instance_id: token.job_instance_id).where.not(id: token.id).delete_all
      token
    end

    it 'filters processable, working, finished, and waiting tokens' do
      working = isolated_token(Kuroko2::Token::WORKING)
      waiting = isolated_token(Kuroko2::Token::WAITING)
      finished = isolated_token(Kuroko2::Token::FINISHED)

      expect(described_class.processable).to contain_exactly(working, waiting)
      expect(described_class.working).to contain_exactly(working)
      expect(described_class.finished).to contain_exactly(finished)
      expect(described_class.waiting).to contain_exactly(waiting)
    end
  end

  describe "#retryable?" do
    subject! { create(:token, status: status) }

    context 'When token is failure status' do
      let(:status) { Kuroko2::Token::FAILURE }
      it { is_expected.to be_retryable }
    end

    context 'When token is waiting status' do
      let(:status) { Kuroko2::Token::WAITING }
      it { is_expected.not_to be_retryable }
    end

    context 'When token is working status' do
      let(:status) { Kuroko2::Token::WORKING }
      it { is_expected.not_to be_retryable }
    end
  end
end
