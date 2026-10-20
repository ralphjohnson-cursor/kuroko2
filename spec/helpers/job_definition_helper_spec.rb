require 'rails_helper'

describe Kuroko2::JobDefinitionsHelper do
  include Kuroko2::Engine.routes.url_helpers

  describe '#first_line' do
    subject { first_line(text) }

    let(:line) { 'First Line' }

    context 'multi line text' do
      let(:text) do
        <<-EOF.strip_heredoc
          #{line}

          Additional
        EOF
      end

      it { is_expected.to eq line }
    end

    context 'single line text' do
      let(:text) { line }

      it { is_expected.to eq line }
    end
  end

  describe '#markdown_format' do
    subject { markdown_format(text) }

    let(:text) do
      <<-EOF.strip_heredoc
        # Title
        LGTM
      EOF
    end

    # commonmarker >= 1 includes an anchor in headings
    it { is_expected.to match %r(<h1\b[^>]*>(<a\b[^>]*></a>)?Title(<a\b[^>]*></a>)?</h1>) }
    it { is_expected.to match %r(LGTM) }
  end

  describe "#format_kuroko_script" do
    subject { format_kuroko_script(text) }
    let(:definition1) { create(:job_definition) }
    let(:definition2) { create(:job_definition) }
    let(:definition3) { create(:job_definition) }

    let(:text) do
      <<-EOF.strip_heredoc
        wait: #{definition1.id}/daily #{definition2.id}/daily timeout=100
        sub_process: #{definition3.id}
      EOF
    end

    it do
      expect(subject).to eq(<<-HTML.strip_heredoc)
        wait: <a href="/definitions/#{definition1.id}">#{definition1.id}/daily</a> <a href="/definitions/#{definition2.id}">#{definition2.id}/daily</a> timeout=100 <span class="note"># #{definition1.name}, #{definition2.name}</span>
        <a href="/definitions/#{definition3.id}">sub_process: #{definition3.id}</a> <span class="note"># #{definition3.name}</span>
      HTML
    end

    context 'when the referenced definitions do not exist' do
      let(:text) do
        <<-EOF.strip_heredoc
          wait: 999999/daily
          sub_process: 999999
          echo: hello <world>
        EOF
      end

      it 'escapes the unresolved tasks' do
        expect(subject).to eq(<<-HTML.strip_heredoc)
          wait: 999999/daily <span class="note"># </span>
          sub_process: 999999
          echo: hello &lt;world&gt;
        HTML
      end
    end
  end

  describe '#star_link_for' do
    let(:user) { create(:user) }
    let(:definition) { create(:job_definition) }

    def current_user
      user
    end

    it 'posts a new star when the user has not starred the definition' do
      html = star_link_for(definition)

      expect(stared_with(definition)).to be_nil
      expect(html).to include('fa-star-o')
      expect(html).to include(%(/definitions/#{definition.id}/stars))
    end

    it 'deletes the existing star' do
      star = create(:star, user: user, job_definition: definition)

      html = star_link_for(definition)

      expect(stared_with(definition)).to eq star
      expect(html).to include('fa-star"')
      expect(html).to include(%(/definitions/#{definition.id}/stars/#{star.id}))
    end
  end
end
