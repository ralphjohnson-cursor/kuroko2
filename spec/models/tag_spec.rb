require 'rails_helper'

describe Kuroko2::Tag do
  it 'rejects a name longer than 100 characters' do
    tag = described_class.new(name: 'a' * 101)

    expect(tag).not_to be_valid
    expect(tag.errors[:name]).to be_present
  end

  it 'accepts a name of 100 characters' do
    expect(described_class.new(name: 'a' * 100)).to be_valid
  end

  it 'associates job definitions through job definition tags' do
    definition = create(:job_definition)
    tag = described_class.create!(name: 'billing')
    definition.tags << tag

    expect(tag.reload.job_definitions).to contain_exactly(definition)
    expect(tag.job_definition_tags.map(&:job_definition)).to contain_exactly(definition)
  end
end
