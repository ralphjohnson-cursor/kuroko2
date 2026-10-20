require 'rails_helper'

describe Kuroko2::Tag do
  it 'accepts a name of 100 characters' do
    expect(described_class.new(name: 'a' * 100)).to be_valid
  end

  it 'rejects a name longer than 100 characters' do
    tag = described_class.new(name: 'a' * 101)

    expect(tag).not_to be_valid
    expect(tag.errors[:name]).to be_present
  end

  it 'exposes job definitions through job definition tags' do
    tag = described_class.create!(name: 'daily')
    definition = create(:job_definition, text_tags: 'daily')

    expect(tag.job_definitions).to eq([definition])
  end
end
