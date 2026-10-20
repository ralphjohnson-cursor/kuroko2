require 'rails_helper'

describe Kuroko2::ExecutionLogsController do
  routes { Kuroko2::Engine.routes }

  before { sign_in }

  let(:definition) { create(:job_definition) }
  let(:instance) { create(:job_instance, job_definition: definition) }

  describe '#index' do
    it 'responds with 404 when the logger has no stream' do
      get :index, params: {
        job_definition_id: definition.id,
        job_instance_id: instance.id,
        token: 'abc',
      }

      expect(response).to have_http_status(:not_found)
    end

    it 'assigns the logs returned for the padded stream name' do
      # This action has no template, so rendering raises after the assignments.
      execution_logger = instance_double(Kuroko2::ExecutionLogger::Void)
      allow(execution_logger).to receive(:get_logs).with('abc').and_return('line 1')
      expect(Kuroko2::ExecutionLogger).to receive(:get_logger).with(
        stream_name: format('JOB%010d/%d', definition.id, instance.id),
      ).and_return(execution_logger)

      expect {
        get :index, params: {
          job_definition_id: definition.id,
          job_instance_id: instance.id,
          token: 'abc',
        }
      }.to raise_error(ActionController::UnknownFormat)

      expect(assigns(:definition)).to eq(definition)
      expect(assigns(:instance)).to eq(instance)
      expect(assigns(:response)).to eq('line 1')
    end
  end
end
