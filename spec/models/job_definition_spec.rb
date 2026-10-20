require 'rails_helper'

describe Kuroko2::JobDefinition do
  let!(:definition) { create(:job_definition_with_instances) }

  describe 'validations' do
    subject(:definition) { build(:job_definition) }

    it 'accepts a slack channel and an https webhook' do
      definition.slack_channel = '#ops'
      definition.webhook_url = 'https://example.com/hook'

      expect(definition).to be_valid
    end

    it 'rejects a slack channel that does not start with #' do
      definition.slack_channel = 'ops'

      expect(definition).not_to be_valid
      expect(definition.errors[:slack_channel]).to be_present
    end

    it 'rejects a webhook that is not an http url' do
      definition.webhook_url = 'not a url'

      expect(definition).not_to be_valid
      expect(definition.errors[:webhook_url]).to be_present
    end

    it 'rejects a script with invalid syntax' do
      definition.script = ':'

      expect(definition).not_to be_valid
    end
  end

  describe '#text_tags=' do
    let(:definition) { create(:job_definition) }

    it 'splits on commas, drops blanks, and keeps unique names' do
      definition.text_tags = 'alpha, beta、 alpha'
      definition.save!

      expect(definition.reload.text_tags).to eq 'alpha,beta'
    end
  end

  describe '.tagged_by' do
    let!(:both) { create(:job_definition).tap { |definition| definition.update!(text_tags: 'red,blue') } }
    let!(:red_only) { create(:job_definition).tap { |definition| definition.update!(text_tags: 'red') } }

    it 'returns definitions that have every requested tag' do
      expect(described_class.tagged_by(%w(red blue))).to contain_exactly(both)
      expect(described_class.tagged_by(%w(red))).to contain_exactly(both, red_only)
    end
  end

  describe '.search_by' do
    let!(:named) { create(:job_definition, name: 'UniqueBillingJob') }
    let!(:scripted) { create(:job_definition, script: "noop:\n# UniqueBillingScript\n") }
    let!(:tagged) { create(:job_definition).tap { |definition| definition.update!(text_tags: 'UniqueBillingTag') } }
    let!(:other) { create(:job_definition, name: 'Other', script: "noop:\n") }

    it 'matches the name, script, or tag' do
      expect(described_class.search_by('UniqueBilling')).to contain_exactly(named, scripted, tagged)
      expect(described_class.search_by('UniqueBilling')).not_to include(other)
    end
  end

  describe '#save_and_record_revision' do
    let(:user) { create(:user) }
    let(:definition) { create(:job_definition, script: "noop:\n") }

    it 'records a revision when the script changes' do
      expect(definition.save_and_record_revision(edited_user: user)).to eq true
      expect(definition.revisions.count).to eq 1
      expect(definition.revisions.first.user).to eq user
      expect(definition.revisions.first.script).to eq "noop:\n"

      expect { definition.save_and_record_revision(edited_user: user) }.not_to change { definition.revisions.count }

      definition.script = "echo: hi\n"
      expect(definition.save_and_record_revision(edited_user: user)).to eq true
      expect(definition.revisions.first.script).to eq "echo: hi\n"
    end

    it 'returns false and skips the revision when the definition is invalid' do
      definition.name = ''

      expect(definition.save_and_record_revision(edited_user: user)).to eq false
      expect(definition.revisions).to be_empty
    end
  end

  describe '#create_instance' do
    let(:definition) { create(:job_definition, prevent_multi: Kuroko2::JobDefinition::PreventMultiStatus::NONE) }

    it 'launches an instance and records who launched it' do
      instance = definition.create_instance(launched_by: 'scheduler')

      expect(instance.logs.pluck(:message)).to include('Launched by scheduler')
    end

    it 'prefixes the token uuid and keeps an ad hoc script' do
      token = create(:token, job_definition: definition)
      instance = definition.create_instance(launched_by: 'api', token: token, script: "echo: 1\n")

      expect(instance.script).to eq "echo: 1\n"
      expect(instance.logs.pluck(:message)).to include("(token #{token.uuid}) Launched by api")
    end
  end

  describe '#destroy' do
    subject { definition.destroy }

    context 'token dependency' do
      context 'without token' do
        before { Kuroko2::Token.destroy_all }

        it { is_expected.to be_truthy }
      end

      context 'with token' do
        it { is_expected.to be_falsey }
      end
    end

    context 'schedules dependency' do
      before do
        Kuroko2::Token.destroy_all
        definition.job_schedules.create(cron: '0 * * * *')
      end

      it do
        is_expected.to be_truthy
        expect(Kuroko2::JobSchedule.all.size).to be_zero
      end
    end
  end

  describe "#proceed_multi_instance?" do
    let(:prevent_multi) { 1 }
    let!(:definition) do
      create(
        :job_definition_with_instances,
        prevent_multi: prevent_multi,
      )
    end

    subject { definition.proceed_multi_instance? }

    context 'prevent_multi is default (working, failure)' do
      context "the token's status is working" do
        it { is_expected.to be_falsey }
      end

      context "the token's status is failure" do
        before do
          Kuroko2::Token.where(job_definition_id: definition.id).
            update_all(status: Kuroko2::Token::FAILURE)
        end
        it { is_expected.to be_falsey }
      end

      context "the token's status is finished" do
        before do
          Kuroko2::Token.where(job_definition_id: definition.id).
            update_all(status: Kuroko2::Token::FINISHED)
        end
        it { is_expected.to be_truthy }
      end
    end

    context 'prevent_multi is only working' do
      let(:prevent_multi) { 2 }

      context "the token's status is working" do
        it { is_expected.to be_falsey }
      end

      context "the token's status is failure" do
        before do
          Kuroko2::Token.where(job_definition_id: definition.id).
            update_all(status: Kuroko2::Token::FAILURE)
        end
        it { is_expected.to be_truthy }
      end

      context "the token's status is finished" do
        before do
          Kuroko2::Token.where(job_definition_id: definition.id).
            update_all(status: Kuroko2::Token::FINISHED)
        end
        it { is_expected.to be_truthy }
      end
    end

    context 'prevent_multi is only failure' do
      let(:prevent_multi) { 3 }

      context "the token's status is working" do
        it { is_expected.to be_truthy }
      end

      context "the token's status is failure" do
        before do
          Kuroko2::Token.where(job_definition_id: definition.id).
            update_all(status: Kuroko2::Token::FAILURE)
        end
        it { is_expected.to be_falsey }
      end

      context "the token's status is finished" do
        before do
          Kuroko2::Token.where(job_definition_id: definition.id).
            update_all(status: Kuroko2::Token::FINISHED)
        end
        it { is_expected.to be_truthy }
      end
    end

    context 'prevent_multi is only failure' do
      let(:prevent_multi) { 3 }

      context "the token's status is working" do
        it { is_expected.to be_truthy }
      end

      context "the token's status is failure" do
        before do
          Kuroko2::Token.where(job_definition_id: definition.id).
            update_all(status: Kuroko2::Token::FAILURE)
        end
        it { is_expected.to be_falsey }
      end

      context "the token's status is finished" do
        before do
          Kuroko2::Token.where(job_definition_id: definition.id).
            update_all(status: Kuroko2::Token::FINISHED)
        end
        it { is_expected.to be_truthy }
      end
    end

    context 'prevent_multi disabled' do
      let(:prevent_multi) { 0 }

      context "the token's status is working" do
        it { is_expected.to be_truthy }
      end

      context "the token's status is failure" do
        before do
          Kuroko2::Token.where(job_definition_id: definition.id).
            update_all(status: Kuroko2::Token::FAILURE)
        end
        it { is_expected.to be_truthy }
      end

      context "the token's status is finished" do
        before do
          Kuroko2::Token.where(job_definition_id: definition.id).
            update_all(status: Kuroko2::Token::FINISHED)
        end
        it { is_expected.to be_truthy }
      end
    end
  end
end
