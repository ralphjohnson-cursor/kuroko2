require 'rails_helper'

describe Kuroko2::JobInstancesHelper do
  describe '#labeled_token_status' do
    {
      'working' => 'primary',
      'finished' => 'success',
      'waiting' => 'warning',
      'failure' => 'danger',
      'critical' => 'warning',
      'unknown' => 'default',
    }.each do |status, modifier|
      it "renders #{status} with the #{modifier} label" do
        expect(labeled_token_status(status)).to eq(
          %(<span class="label label-#{modifier}">#{status.upcase}</span>)
        )
      end
    end
  end

  describe '#labeled_status' do
    it 'renders a placeholder when the instance is missing' do
      expect(labeled_status(nil)).to eq '--'
    end

    {
      'success' => 'success',
      'canceled' => 'warning',
      'error' => 'danger',
      'working' => 'primary',
      'skipped' => 'default',
    }.each do |status, modifier|
      it "renders #{status} with the #{modifier} label" do
        instance = instance_double(Kuroko2::JobInstance, status: status)

        expect(labeled_status(instance)).to eq(
          %(<span class="label label-#{modifier}">#{status.upcase}</span>)
        )
      end
    end
  end

  describe '#first_line' do
    it 'returns the first line only' do
      expect(first_line("hello\nworld")).to eq 'hello'
    end
  end

  describe '#distance_of_time' do
    let(:from) { Time.zone.parse('2020-01-01 00:00:00') }

    it 'formats a duration shorter than a day' do
      expect(distance_of_time(from, from + 90)).to eq '00:01:30'
    end

    it 'includes whole days' do
      to = from + 1.day + 2.hours + 3.minutes + 4
      expect(distance_of_time(from, to)).to eq '1days 02:03:04'
    end
  end
end
