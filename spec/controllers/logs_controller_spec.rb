require 'rails_helper'

describe Kuroko2::LogsController do
  routes { Kuroko2::Engine.routes }

  before { sign_in }

  let(:definition) { create(:job_definition) }
  let(:instance) { create(:job_instance, job_definition: definition) }

  describe '#index' do
    before do
      instance.logs.info('see http://example.com/run')
      instance.logs.error('boom <script>')
      instance.logs.warn('careful')
      instance.logs.create!(level: 'DEBUG', message: 'detail')
    end

    def logs_json
      get :index, params: { job_definition_id: definition.id, job_instance_id: instance.id }
      JSON.parse(response.body)
    end

    it 'returns log rows with a label class and an autolinked message' do
      body = logs_json

      expect(response).to have_http_status(:ok)
      expect(body['reload']).to eq true
      expect(body['logs'].map { |log| log['level'] }).to eq %w(INFO ERROR WARN DEBUG)
      expect(body['logs'].map { |log| log['class_for_label'] }).to eq %w(
        label-info label-danger label-warning label-default
      )
      expect(body['logs'][0]['message_html']).to include('href="http://example.com/run"')
      expect(body['logs'][1]['message_html']).to include('boom &lt;script&gt;')
    end

    it 'stops asking the client to reload after the instance errors' do
      instance.update!(error_at: Time.current)

      expect(logs_json['reload']).to eq false
    end

    it 'stops asking the client to reload after the instance finishes' do
      instance.update!(finished_at: Time.current)

      expect(logs_json['reload']).to eq false
    end
  end
end
