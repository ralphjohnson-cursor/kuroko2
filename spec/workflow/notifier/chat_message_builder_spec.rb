require 'rails_helper'

module Kuroko2::Workflow::Notifier::Concerns
  describe ChatMessageBuilder do
    let(:definition) { create(:job_definition, name: 'Nightly', hipchat_additional_text: '@ops') }
    let(:instance) { create(:job_instance, job_definition: definition) }
    let(:builder) { described_class.new(instance) }

    it 'builds status messages from the definition name' do
      expect(builder.failure_text).to eq("Failed to execute 'Nightly'")
      expect(builder.finished_text).to eq("Finished executing 'Nightly'")
      expect(builder.launched_text).to eq("Launched 'Nightly'")
      expect(builder.back_to_normal_text).to eq("'Nightly' is back to normal")
      expect(builder.retrying_text).to eq("Retrying the current task in 'Nightly'")
      expect(builder.skipping_text).to eq("Skipping the current task in 'Nightly'")
      expect(builder.long_elapsed_time_text).to eq("The running time of 'Nightly' is longer than expected.")
      expect(builder.additional_text).to eq("Failed to execute 'Nightly' @ops")
    end

    it 'builds an absolute job instance url from the configured host' do
      expect(builder.job_instance_path).to eq(
        "http://localhost/definitions/#{definition.id}/instances/#{instance.id}"
      )
    end
  end
end
