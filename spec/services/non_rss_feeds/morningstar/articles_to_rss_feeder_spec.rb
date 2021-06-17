# frozen_string_literal: true

require 'spec_helper'

describe NonRssFeeds::Morningstar::ArticlesToRssFeeder do
  let(:article) do
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
  end
  let(:articles) do
    [article]
  end
  let(:channel_data) do
    {
      title: 'Blah',
      link: 'http://www.blah.com',
      description: 'This is a description.'
    }
  end

  describe '#xml_rss_feed' do
    let(:subject) do
      described_class.new(articles, channel_data)
    end
    let(:result) do
      Feedjira::Feed.parse(
        subject.xml_rss_feed
      ).entries.first
    end

    it 'adds the correct id' do
      expect(
        result.entry_id
      ).to eq articles.first[:article_ref]
    end

    it 'adds the correct title' do
      expect(
        result.title
      ).to eq articles.first[:title]
    end

    it 'adds the correct author' do
      expect(
        result.author
      ).to eq articles.first[:author]
    end

    it 'adds the correct image' do
      expect(
        result.image
      ).to eq articles.first[:image_url]
    end

    it 'adds the correct summary' do
      expect(
        result.summary
      ).to eq articles.first[:summary]
    end

    it 'adds the correct published' do
      expect(
        result.published
      ).to eq articles.first[:published_at]
    end

    it 'adds the correct content' do
      expect(
        result.content
      ).to eq articles.first[:content]
    end
    context 'when article has no author' do
      let(:article) do
        {
          article_ref: 'article:archive/WSJO000020160609ec69007by',
          title:  'This is a title.',
          author: nil,
          published_at: Time.zone.parse('2016-06-09T16:29:00.000Z'),
          summary: 'This is a summary.',
          image_url: 'https://www.image.com/image.jp',
          image_size: 35_643,
          image_type: 'image/jpeg',
          id: 'article:archive/WSJO000020160609ec69007by',
          description: 'This is a description.',
          content: '<p>This is some content.</p>'
        }
      end

      it 'adds the correct author' do
        expect(
          result.author
        ).to eq nil
      end
    end
  end
end
