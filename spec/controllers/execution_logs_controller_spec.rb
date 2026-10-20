require 'rails_helper'

describe Kuroko2::ExecutionLogsController do
  render_views

  routes { Kuroko2::Engine.routes }

  before { sign_in }

  let(:definition) { create(:job_definition) }
  let(:instance) { create(:job_instance, job_definition: definition) }

  describe '#index' do
    it 'responds with not found when the execution logger has no stream' do
      get :index, params: {
        job_definition_id: definition.id,
        job_instance_id: instance.id,
        format: :json,
      }

      expect(response).to have_http_status(:not_found)
    end

    it 'renders events from the execution logger' do
      events = [
        double('json event', timestamp: 1_577_836_800_000, message: { message: 'hello http://example.com', pid: 7, uuid: 'abc' }.to_json),
        double('plain event', timestamp: 1_577_836_801_000, message: 'plain <text>'),
      ]
      logger = instance_double(Kuroko2::ExecutionLogger::Void)
      allow(logger).to receive(:get_logs).with('next-token').and_return(
        double('response', next_forward_token: 'forward', events: events)
      )
      expect(Kuroko2::ExecutionLogger).to receive(:get_logger).with(
        stream_name: format('JOB%010d/%d', definition.id, instance.id)
      ).and_return(logger)

      get :index, params: {
        job_definition_id: definition.id,
        job_instance_id: instance.id,
        token: 'next-token',
        format: :json,
      }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['token']).to eq 'forward'
      expect(body['events'][0]['message']).to include('hello')
      expect(body['events'][0]['message']).to include('http://example.com')
      expect(body['events'][0]['pid']).to eq 7
      expect(body['events'][0]['uuid']).to eq 'abc'
      expect(body['events'][1]['message']).to include('plain &lt;text&gt;')
    end
  end
end
