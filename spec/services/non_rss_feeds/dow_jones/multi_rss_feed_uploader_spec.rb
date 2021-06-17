# frozen_string_literal: true

require 'spec_helper'

describe NonRssFeeds::DowJones::MultiRssFeedUploader do
  let(:non_rss_feed) do
    NonRssFeed.new(name: 'Feed', url: 'http://feed.com')
  end
  let(:article_1) do
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
      content: '<p>This is some content.</p>',
      section: 'Life'
    }
  end
  let(:article_2) do
    {
      article_ref: 'article:archive/WSJO000020160609ec69007by',
      title:  'Another title.',
      author: 'Dougherty Margot',
      published_at: Time.zone.parse('2013-06-09T16:29:00.000Z'),
      summary: 'Another summary.',
      image_url: 'https://www.image.com/image.jp',
      image_size: 35_643,
      image_type: 'image/jpeg',
      id: 'article:archive/WSJO000020160609ec69007by',
      description: 'Another description.',
      content: '<p>More content.</p>',
      section: 'Business'
    }
  end
  let(:channel_data) do
    {
      title: 'Blah',
      link: 'http://www.blah.com',
      description: 'This is a description.'
    }
  end

  describe '#upload' do
    let(:xml_rss_feeds) do
      NonRssFeeds::DowJones::ArticlesToSectionRssFeeder.new(
        [article_1, article_2],
        non_rss_feed
      ).xml_rss_feeds
    end
    let(:rss_feed_uploader_double) do
      instance_double(NonRssFeeds::DowJones::RssFeedUploader)
    end
    let(:subject) do
      described_class.new(xml_rss_feeds, 'bucket_name', 'blah.xml')
    end

    context 'when the xml_feed is uploaded' do
      it 'it calls the rss feed uploader' do
        expect(NonRssFeeds::DowJones::RssFeedUploader)
          .to receive(:new) do |rss_feed, bucket_name, path|
            expect(rss_feed).to be_in xml_rss_feeds
            expect(bucket_name).to eq 'bucket_name'
            expect(path).to be_in ['life.xml', 'business.xml']
          end
          .exactly(2).times
          .and_return(rss_feed_uploader_double)
        expect(rss_feed_uploader_double)
          .to receive(:upload)
          .and_return('https://www.blah.com/blah1.xml', 'https://www.blah.com/blah2.xml')
          .exactly(2).times
        expect(
          subject.upload
        ).to eq(
          [
            {
              rss_feed_name: 'Life',
              rss_feed_url: 'https://www.blah.com/blah1.xml'
            },
            {
              rss_feed_name: 'Business',
              rss_feed_url: 'https://www.blah.com/blah2.xml'
            }
          ]
        )
      end
    end
  end
end
