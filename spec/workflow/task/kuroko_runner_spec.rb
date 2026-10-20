require 'rails_helper'

module Kuroko2::Workflow::Task
  describe KurokoRunner do
    let(:definition) { create(:job_definition, script: "kuroko_runner: cleanup_old_instances\n") }
    let(:instance) do
      create(:job_instance, job_definition: definition).tap do |job_instance|
        job_instance.tokens.destroy_all
      end
    end
    let(:token) do
      create(:token, path: '/', script: 'kuroko_runner:', context: context, job_definition: definition, job_instance: instance)
    end
    let(:context) { {} }
    let(:node) { Kuroko2::Workflow::Node.new(:kuroko_runner, 'cleanup_old_instances') }

    it 'queues a rails runner execution in the application root' do
      expect(described_class.new(node, token).execute).to eq(:pass)

      execution = Kuroko2::Execution.take
      expect(execution.shell).to eq(
        "bundle exec #{Rails.root.join('bin/rails')} runner -e #{Rails.env} #{Kuroko2::Engine.root.join('bin/cleanup_old_instances.rb')}"
      )
      expect(execution.context['CHDIR']).to eq(Rails.root.to_s)
      expect(execution.context['ENV']).to eq('BUNDLE_GEMFILE' => Rails.root.join('Gemfile').to_s)
    end

    it 'keeps environment values already stored on the token' do
      token.context['ENV'] = { 'NAME' => 'alice' }

      described_class.new(node, token).execute

      expect(Kuroko2::Execution.take.context['ENV']).to eq(
        'NAME' => 'alice',
        'BUNDLE_GEMFILE' => Rails.root.join('Gemfile').to_s,
      )
    end
  end
end
