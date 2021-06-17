# frozen_string_literal: true

require 'spec_helper'

describe NonRssFeeds::Morningstar::RssFeedUploader do
  let(:articles) do
    [
      {
        article_ref: 'article:archive/WSJO000020160609ec69007by',
        title:  'This is a title.',
        author: 'Margot Dougherty',
        published_at: Time.zone.parse('2016-06-09T16:29:00.000Z'),
        summary: 'This is a summary.',
        image_url: 'https://www.image.com/image.jp',
        image_size: 35_643,
        image_type: 'image/jpeg',
        id: 'article:archive/WSJO000020160609ec69007by',
        description: 'This is a description.',
        content: '<p>This is some content.</p>'
      }
    ]
  end
  let(:channel_data) do
    {
      title: 'Blah',
      link: 'http://www.blah.com',
      description: 'This is a description.'
    }
  end

  describe '#upload' do
    let(:xml_rss_feed) do
      NonRssFeeds::Morningstar::ArticlesToRssFeeder.new(
        articles,
        channel_data
      ).xml_rss_feed
    end
    let(:subject) do
      described_class.new(xml_rss_feed, 'blah', 'blah.xml')
    end

    context 'when an exception occurs' do
      before do
        allow_any_instance_of(described_class).to receive(
          :write
        ).and_raise('boom')
      end
      it 'returns nil' do
        expect(
          subject.upload
        ).to be_nil
      end
    end
    context 'when the xml_feed is not parseable' do
      before do
        allow_any_instance_of(described_class).to receive(
          :parsable?
        ).and_return(false)
      end
      it 'returns nil' do
        expect(
          subject.upload
        ).to be_nil
      end
    end
    context 'when the xml_feed is uploaded' do
      before do
        allow_any_instance_of(described_class).to receive(
          :object
        ).and_return(double(public_url: URI('https://www.blah.com/blah.xml')))
        expect_any_instance_of(described_class).to receive(
          :write
        ).and_return(nil)
      end
      it 'returns the public url' do
        expect(
          subject.upload
        ).to eq('https://www.blah.com/blah.xml')
      end
    end
  end
end
