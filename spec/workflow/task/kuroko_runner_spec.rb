require 'rails_helper'

module Kuroko2::Workflow::Task
  describe KurokoRunner do
    let(:node) { Kuroko2::Workflow::Node.new(:kuroko_runner, 'daily') }

    describe '#before_execute' do
      it 'adds BUNDLE_GEMFILE to an existing environment' do
        token = build(:token, context: { 'ENV' => { 'FOO' => 'bar' } })

        KurokoRunner.new(node, token).before_execute

        expect(token.context['ENV']).to eq(
          'FOO' => 'bar',
          'BUNDLE_GEMFILE' => Rails.root.join('Gemfile').to_s,
        )
      end

      it 'creates the environment when the token has none' do
        token = build(:token, context: {})

        KurokoRunner.new(node, token).before_execute

        expect(token.context['ENV']).to eq(
          'BUNDLE_GEMFILE' => Rails.root.join('Gemfile').to_s,
        )
      end
    end

    describe '#chdir' do
      it 'runs inside the Rails application root' do
        token = build(:token, context: {})

        expect(KurokoRunner.new(node, token).chdir).to eq Rails.root.to_s
      end
    end

    describe '#shell' do
      it 'runs the named kuroko script through rails runner' do
        token = build(:token, context: {})
        rails = Rails.root.join('bin/rails')
        script = Kuroko2::Engine.root.join('bin/daily.rb')

        expect(KurokoRunner.new(node, token).shell).to eq(
          "bundle exec #{rails} runner -e #{Rails.env} #{script}"
        )
      end
    end
  end
end
