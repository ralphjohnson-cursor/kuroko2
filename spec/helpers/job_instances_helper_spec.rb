require 'rails_helper'

describe Kuroko2::JobInstancesHelper do
  describe '#labeled_token_status' do
    {
      'working' => 'label-primary',
      'finished' => 'label-success',
      'waiting' => 'label-warning',
      'failure' => 'label-danger',
      'critical' => 'label-warning',
      'unknown' => 'label-default',
    }.each do |status, modifier|
      it "renders #{status} with #{modifier}" do
        html = helper.labeled_token_status(status)

        expect(html).to include(status.upcase)
        expect(html).to include(modifier)
      end
    end
  end

  describe '#labeled_status' do
    it 'renders a placeholder when the instance is missing' do
      expect(helper.labeled_status(nil)).to eq('--')
    end

    {
      'success' => 'label-success',
      'canceled' => 'label-warning',
      'error' => 'label-danger',
      'working' => 'label-primary',
      'mystery' => 'label-default',
    }.each do |status, modifier|
      it "renders #{status} with #{modifier}" do
        html = helper.labeled_status(instance_double(Kuroko2::JobInstance, status: status))

        expect(html).to include(status.upcase)
        expect(html).to include(modifier)
      end
    end
  end

  describe '#first_line' do
    it 'returns the first line' do
      expect(helper.first_line("one\ntwo")).to eq('one')
    end
  end

  describe '#distance_of_time' do
    let(:from) { Time.zone.parse('2026-01-01 00:00:00') }

    it 'formats an elapsed time under a day' do
      expect(helper.distance_of_time(from, from + 3661)).to eq('01:01:01')
    end

    it 'includes whole days' do
      to = from + 2.days + 3.hours + 4.minutes + 5.seconds

      expect(helper.distance_of_time(from, to)).to eq('2days 03:04:05')
    end
  end
end
