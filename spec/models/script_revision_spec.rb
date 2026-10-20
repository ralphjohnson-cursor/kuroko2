require 'rails_helper'

describe Kuroko2::ScriptRevision do
  describe '#html_diff' do
    let(:definition) { create(:job_definition) }
    let(:previous) { create(:script_revision, job_definition: definition, script: "noop:\n") }
    let(:current) { create(:script_revision, job_definition: definition, script: "echo: hi\n") }

    it 'returns an html diff against the previous script' do
      html = current.html_diff(previous)

      expect(html).to be_html_safe
      expect(html).to include('echo: hi')
      expect(html).to include('noop:')
    end

    it 'diffs against an empty script when there is no previous revision' do
      html = current.html_diff(nil)

      expect(html).to be_html_safe
      expect(html).to include('echo: hi')
    end
  end
end
