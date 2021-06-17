require 'spec_helper'

describe NonRssFeeds::Morningstar::ArticlesToSectionRssFeeder do
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
  let(:articles) do
    [article_1, article_2]
  end
  let(:non_rss_feed) do
    NonRssFeed.new(name: 'Feed', url: 'http://feed.com')
  end

  describe '#xml_rss_feeds' do
    let(:subject) do
      described_class.new(articles, non_rss_feed)
    end
    let(:article_to_rss_feeder_double) do
      instance_double(NonRssFeeds::Morningstar::ArticlesToRssFeeder)
    end
    let(:channel_params) do
      {
        title: 'Feed Life',
        link: 'http://feed.com',
        description: ''
      }
    end

    it 'calls the ArticlesToRssFeeder' do
      expect(article_to_rss_feeder_double)
        .to receive(:xml_rss_feed)
        .exactly(2).times
      expect(NonRssFeeds::Morningstar::ArticlesToRssFeeder)
        .to receive(:new) do |article_arg, channel_params_arg|
          expect(article_arg).to be_in [[article_1], [article_2]]
          expect(channel_params_arg[:title]).to be_in ['Life', 'Business']
          expect(channel_params_arg[:link]).to eq 'http://feed.com'
        end
        .exactly(2).times
        .and_return(article_to_rss_feeder_double)
      subject.xml_rss_feeds
    end
  end
end
