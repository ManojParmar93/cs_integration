# frozen_string_literal: true

require 'spec_helper'

describe NonRssFeeds::DowJones::LastModifiedChecker do
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
      response = double(
        body: {
          'Collections' => [
            {
              'Code' => 'NP_Lifestyle_1',
              'CreatedDate' => '2016-05-23',
              'CreatedDateTime' => '/Date(1464019840000)/',
              'CreatedTime' => '16:10:40Z',
              'CreatedTimeSpecified' => true,
              'Description' => '',
              'Id' => 664_724,
              'LastModifiedDate' => '2016-09-06',
              'LastModifiedDateTime' => '/Date(1473180882000)/',
              'LastModifiedTime' => '16:54:42Z',
              'LastModifiedTimeSpecified' => true,
              'Name' => 'NP_Lifestyle_1'
            }
          ]
        }.to_json
      )
      allow_any_instance_of(
        described_class
      ).to receive(
        :request_collection_code
      ).and_return(response)
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
          updated_at: Time.zone.parse('2016-09-07')
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
