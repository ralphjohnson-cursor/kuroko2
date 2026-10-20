require 'rails_helper'

describe Kuroko2::JobDefinition do
  let!(:definition) { create(:job_definition_with_instances) }

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

  describe 'tags' do
    it 'assigns unique tags from comma-separated text' do
      definition.text_tags = ' alpha , beta、alpha '
      definition.save!

      expect(definition.reload.text_tags).to eq('alpha,beta')
      expect(definition.tags.map(&:name)).to eq(%w[alpha beta])
    end

    it 'reuses an existing tag with the same name' do
      tag = Kuroko2::Tag.create!(name: 'shared')

      definition.text_tags = 'shared'
      definition.save!

      expect(definition.tags).to eq([tag])
      expect(Kuroko2::Tag.where(name: 'shared').count).to eq(1)
    end
  end

  describe '.tagged_by' do
    let!(:both) do
      create(:job_definition).tap do |record|
        record.update!(text_tags: 'red,blue')
      end
    end
    let!(:red_only) do
      create(:job_definition).tap do |record|
        record.update!(text_tags: 'red')
      end
    end

    it 'returns definitions that have every requested tag' do
      expect(described_class.tagged_by(%w[red blue])).to contain_exactly(both)
      expect(described_class.tagged_by(%w[red])).to contain_exactly(both, red_only)
    end
  end

  describe '.search_by' do
    let!(:named) { create(:job_definition, name: 'UniqueZebraJob') }
    let!(:scripted) { create(:job_definition, script: "echo: UniqueZebraScript\n") }
    let!(:tagged) do
      create(:job_definition).tap do |record|
        record.update!(text_tags: 'UniqueZebraTag')
      end
    end

    it 'matches name, script, and tag name' do
      expect(described_class.search_by('UniqueZebra')).to contain_exactly(named, scripted, tagged)
    end
  end

  describe '#create_instance' do
    let(:definition) { create(:job_definition, hipchat_notify_finished: false) }
    let(:token) { create(:token, job_definition: definition, uuid: 'token-uuid') }

    it 'launches an instance and records who launched it' do
      instance = definition.create_instance(script: "echo: hi\n", launched_by: 'scheduler', token: token)

      expect(instance.script).to eq("echo: hi\n")
      expect(instance.logs.map(&:message)).to include('(token token-uuid) Launched by scheduler')
    end
  end

  describe '#save_and_record_revision' do
    let(:user) { create(:user) }

    it 'persists the definition and stores the first script revision' do
      definition = build(:job_definition, admins: [user], script: "noop:\n")

      expect(definition.save_and_record_revision(edited_user: user)).to eq(true)
      expect(definition.revisions.map(&:script)).to eq(["noop:\n"])
      expect(definition.revisions.first.user).to eq(user)
      expect(definition.memory_expectancy).to be_present
    end

    it 'returns false and skips the revision when validation fails' do
      definition = described_class.new(name: '', description: 'desc', script: "noop:\n")

      expect(definition.save_and_record_revision(edited_user: user)).to eq(false)
      expect(definition.revisions).to be_empty
    end
  end

  describe '#update_and_record_revision' do
    let(:user) { create(:user) }
    let(:definition) { create(:job_definition, script: "noop:\n") }

    it 'records a revision only when the script changes' do
      expect(
        definition.update_and_record_revision({ script: "echo: hi\n" }, edited_user: user)
      ).to eq(true)
      expect(definition.revisions.first.script).to eq("echo: hi\n")

      expect {
        definition.update_and_record_revision({ description: 'Updated description' }, edited_user: user)
      }.not_to change { definition.revisions.count }
    end

    it 'returns false when the new attributes are invalid' do
      expect(definition.update_and_record_revision({ name: '' }, edited_user: user)).to eq(false)
      expect(definition.errors[:name]).to be_present
    end
  end

  describe 'validations' do
    subject(:definition) { build(:job_definition) }

    it 'rejects a script with a syntax error' do
      definition.script = '???'

      expect(definition).not_to be_valid
      expect(definition.errors[:base].join).to include('syntax errors')
    end

    it 'rejects an unregistered task' do
      definition.script = "not_a_task:\n"

      expect(definition).not_to be_valid
      expect(definition.errors[:base].join).to include('validation errors')
    end

    it 'requires at least one admin' do
      definition.admins = []

      expect(definition).not_to be_valid
      expect(definition.errors[:admins].join).to include('at least one person')
    end

    it 'checks the slack channel format' do
      definition.slack_channel = 'general'
      expect(definition).not_to be_valid

      definition.slack_channel = '#a.b'
      expect(definition).not_to be_valid

      definition.slack_channel = '#alerts'
      expect(definition).to be_valid
    end

    it 'checks the webhook url scheme' do
      definition.webhook_url = 'ftp://example.com/hook'
      expect(definition).not_to be_valid

      definition.webhook_url = 'https://example.com/hook'
      expect(definition).to be_valid
    end
  end
end
