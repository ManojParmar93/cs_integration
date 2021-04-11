require 'rails_helper'

RSpec.describe CentsaiPostWorker, type: :worker do
  let(:time) { (Time.zone.today + 2.minutes).to_datetime }
  let(:scheduled_job) { described_class.perform_at(time, 'default', true) }

  describe '#CentsaiPost worker' do
    it 'CentsaiPostWorker jobs are enqueued in the scheduled queue' do
      described_class.perform_async
      expect(described_class.queue).to eq("default")
      expect(described_class.jobs.first["class"]).to eq(described_class.to_s)
    end

    it 'it should go into the jobs array for testing environment' do
      expect {
        described_class.perform_async
      }.to change(described_class.jobs, :size).by(1)
      described_class.new.perform
      expect(described_class.jobs.first["enqueued_at"]).not_to be_nil
    end

    context '#occurs in expected time' do
      it 'it should occurs at 2 minutes' do
        scheduled_job
        expect(described_class.jobs.last['jid'].include?(scheduled_job)).to be_truthy
        expect(described_class).to have_enqueued_sidekiq_job('default', true)
      end
    end

  end
end
