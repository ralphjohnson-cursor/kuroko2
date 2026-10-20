require 'rails_helper'

describe Kuroko2::ScriptRevision do
  describe '#html_diff' do
    let(:current) { build(:script_revision, script: "echo: hi\n") }

    it 'renders an html diff against the previous script' do
      previous = build(:script_revision, script: "noop:\n")

      html = current.html_diff(previous)

      expect(html).to include('echo: hi')
      expect(html).to be_html_safe
    end

    it 'diffs against an empty script when there is no previous revision' do
      expect(current.html_diff(nil)).to include('echo: hi')
    end
  end
end
