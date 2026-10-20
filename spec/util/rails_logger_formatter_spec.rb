require 'rails_helper'

describe Kuroko2::Util::RailsLoggerFormatter do
  it 'formats severity, timestamp, and message' do
    timestamp = Time.utc(2020, 1, 2, 3, 4, 5)

    line = described_class.new.call('INFO', timestamp, 'prog', 'hello')

    expect(line).to eq "#{timestamp.iso8601} INFO : hello\n"
  end
end
