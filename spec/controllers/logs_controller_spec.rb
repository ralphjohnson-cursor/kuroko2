require 'rails_helper'

describe Kuroko2::LogsController do
  routes { Kuroko2::Engine.routes }

  before { sign_in }

  let(:definition) { create(:job_definition) }
  let(:instance) { create(:job_instance, job_definition: definition) }

  describe '#index' do
    before do
      instance.logs.info('hello https://example.com')
      instance.logs.error('boom <script>')
      instance.logs.warn('careful')
      instance.logs.create!(level: 'DEBUG', message: 'dbg')
    end

    it 'returns logs with label classes and escaped linked messages' do
      get :index, params: { job_definition_id: definition.id, job_instance_id: instance.id }

      body = JSON.parse(response.body)
      expect(body['reload']).to eq(true)
      expect(body['logs'].map { |log| [log['level'], log['class_for_label']] }).to eq([
        ['INFO', 'label-info'],
        ['ERROR', 'label-danger'],
        ['WARN', 'label-warning'],
        ['DEBUG', 'label-default'],
      ])
      expect(body['logs'].first['message_html']).to include('https://example.com')
      expect(body['logs'].second['message_html']).to include('&lt;script&gt;')
      expect(body['logs'].second['message_html']).not_to include('<script>')
    end

    it 'does not ask the client to reload a finished or failed instance' do
      instance.update!(finished_at: Time.current)
      get :index, params: { job_definition_id: definition.id, job_instance_id: instance.id }
      expect(JSON.parse(response.body)['reload']).to eq(false)

      instance.update!(finished_at: nil, error_at: Time.current)
      get :index, params: { job_definition_id: definition.id, job_instance_id: instance.id }
      expect(JSON.parse(response.body)['reload']).to eq(false)
    end
  end
end
