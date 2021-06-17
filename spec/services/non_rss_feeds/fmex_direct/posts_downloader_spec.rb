require 'spec_helper'

RSpec.describe NonRssFeeds::FmexDirect::PostsDownloader, type: :service do
  let(:fmex_direct_service) { NonRssFeeds::FmexDirect::PostsDownloader.new }

  context '#fmex direct connection' do
    it 'should be check http connection with faraday cilent' do
      VCR.use_cassette('fmex direct/http connection', match_requests_on: [:method, :uri]) do
        result = fmex_direct_service.http_connection
        response = result.get
        expect(response.status).to eq(200)
        expect(response.env[:method]).to eq(:get)
      end
    end
  end

  context '#fmex direct initialize data and vaildate' do
    before do
      ArticleItem.destroy_all
      VCR.use_cassette 'fmex direct/posts downloader' do
        expect {
          get_posts = fmex_direct_service.http_connection.get()
          @post_response = JSON.parse(get_posts.body)
        }.to change { ArticleItem.count }
      end
    end

    it 'should be vaildate fmex direct article_item source and scope' do
      expect(ArticleItem.fmex_direct.first.source).to eq(ArticleItem::FMEX_ITEM)
      expect(ArticleItem.first.guid).not_to be_nil
      expect(ArticleItem.fmex_direct.pluck(:guid).uniq).to eq(ArticleItem.fmex_direct.pluck(:guid))
    end

    it 'should be vaildate fmex direct articles data' do
      expect(@post_response.present?).to eq(@post_response.is_a?(Hash))
      expect(@post_response.keys.map(&:to_sym)).to include(
        :content_id, :content_title, :content_description,
        :content_file_types, :content_url, :content_word_count,
        :content_category_id, :content_date_updated, :content_publisher,
        :content_author, :content_section_id, :content_type,
        :content_update_reason, :content_section, :content_category,
        :preview, :content_generation, :social_share_240x140
      )
      expect(fmex_direct_service.articles.first.keys.map(&:to_sym)).to include(
        :category_id, :category_title, :category_image, :category_description,
        :category_header_image
      )
    end

    it 'should be vaildate author details data' do
      expect(fmex_direct_service.author_details.keys.map(&:to_sym)).to include(
        :author_id, :author_name, :author_url, :author_description, :author_image,
        :author_facebook, :author_linkedin, :author_twitter, :author_website,
        :author_profile
      )
    end

    it 'should be vaildate channel data' do
      expect(fmex_direct_service.channel_data.keys.map(&:to_sym)).to include(
        :title, :link, :description
      )
    end

    it 'should be vaildate published_at date' do
      expect(fmex_direct_service.published_at).to eq(Time.zone.parse(@post_response['content_date_updated']) || Time.now)
    end
  end

  context '#fmex direct for make feed' do
    before do
      VCR.use_cassette 'fmex direct/xml rss feed' do
        xml_rss_feed = Hash.from_xml(fmex_direct_service.send(:make_feed))
        @rss_feed_data = xml_rss_feed["rss"]
      end
    end

    it 'should vaildate make feed for posts to xml content' do
      expect(fmex_direct_service.articles.present?).to eq(fmex_direct_service.articles.is_a?(Array))
      expect(@rss_feed_data["version"]).to eq("2.0")
      expect(@rss_feed_data["xmlns:content"]).to eq("http://purl.org/rss/1.0/modules/content/")
      expect(@rss_feed_data["xmlns:dc"]).to eq("http://purl.org/dc/elements/1.1/")
      expect(@rss_feed_data["xmlns:media"]).to eq("http://search.yahoo.com/mrss/")
    end

    it 'should vaildate xml data of channel' do
      channel_details = @rss_feed_data.dig("channel")
      expect(channel_details).not_to be_nil
      expect(channel_details.is_a?(Hash)).to be_truthy
      expect(channel_details.keys.map(&:to_sym)).to include(
        :title, :link, :description, :pubDate, :item
      )
    end

    it 'should vaildate xml channel of item data' do
      item_details = @rss_feed_data.dig("channel", "item")
      expect(item_details.present?).to eq(item_details.is_a?(Array))
      expect(item_details.first.keys.map(&:to_sym)).to include(
        :guid, :title, :pubDate, :description, :content, :encoded
      )
    end
  end
end
