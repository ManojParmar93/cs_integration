# frozen_string_literal: true

require 'spec_helper'

describe NonRssFeeds::Morningstar::LastModifiedChecker do

  let!(:non_rss_feed) do
    NonRssFeed.destroy_all
    create(
      :non_rss_feed,
      name: Time.zone.now.to_i.to_s,
      miscellaneous: {}
    )
  end

  let(:instance) do
    described_class.new(non_rss_feed)
  end

  describe '#up_to_date?' do
    before do
      allow_any_instance_of(
        described_class
      ).to receive(
        :request_modified_time
      ).and_return(1473180882)
    end
    context 'when not up to date' do
      before do
        non_rss_feed.update!(
          updated_at: Time.zone.parse('2015-01-01T00:00:00')
        )
      end
      it 'returns false' do
        expect(
          instance.up_to_date?
        ).to eq false
      end
    end
    context 'when up to date' do
      before do
        non_rss_feed.update!(
          updated_at: Time.zone.parse('2016-09-08')
        )
      end
      it 'returns true' do
        expect(
          instance.up_to_date?
        ).to eq true
      end
    end
  end
end
