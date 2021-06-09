require 'rails_helper'

RSpec.describe NonRssFeeds::CentsaiPosts::PostsDownloader, type: :service do
  let(:centsai_posts_service) { NonRssFeeds::CentsaiPosts::PostsDownloader.new }
  let(:empty_centsai_posts) { centsai_posts_service.articles.clear }

  context '#centsai posts http connection' do
    it 'should be check http connection with faraday cilent' do
      VCR.use_cassette('centsai posts/http connection', match_requests_on: [:method, :uri]) do
        result = centsai_posts_service.http_connection
        response = result.get
        expect(response.status).to eq(200)
        expect(response.env[:method]).to eq(:get)
        expect(response).not_to be_nil
      end
    end
  end

  context '#centsai posts initialize data and vaildate' do
    before do
      VCR.use_cassette 'centsai posts/posts downloader' do
        expect {
          centsai_posts_service
        }.to change { ArticleItem.count }
      end
    end

    it 'should be vaildate centsai article_item source and scope' do
      expect(ArticleItem.centsai.first.source).to include ("centsai")
      expect(ArticleItem.first.guid).not_to be_nil
      expect(ArticleItem.centsai.pluck(:guid).uniq).to eq(ArticleItem.centsai.pluck(:guid))
    end

    it 'should be initialize and vaildate posts download data' do
      expect(centsai_posts_service.articles.is_a?(Array)).to be_truthy
      expect(centsai_posts_service.articles.present?).to be_truthy
      expect(centsai_posts_service.channel_data.empty?).to be_truthy
    end

    it 'should be vaildate centsai articles and channel_data posts data' do
      expect(centsai_posts_service.articles.last.keys.map(&:to_sym)).to include(
        :post_id, :post_template, :post_title, :post_content, :post_image, :post_url,
        :canonical_url, :post_date, :six_second_take, :author_id, :author_name, :author_url,
        :author_image, :category_id, :category_name, :category_link,:sponsored_content,
        :sponsored_image, :sponsored_url, :video_url, :podcast_url, :featured_partner,
        :featured_partner_url, :featured_part_desc, :featured_part_img
      )
      expect(centsai_posts_service.channel_data.is_a?(Hash)).to be_truthy
    end
  end

  context '#centsai posts for make feed' do
    before do
      VCR.use_cassette 'centsai posts/xml rss feed' do
        xml_rss_feed = Hash.from_xml(centsai_posts_service.send(:make_feed))
        @rss_feed_data = xml_rss_feed["rss"]
      end
    end

    it 'should be make feed for posts to xml' do
      VCR.use_cassette 'centsai posts/xml rss feed' do
        expect(centsai_posts_service.articles.is_a?(Array)).to be_truthy
        expect(@rss_feed_data["version"]).to eq("2.0")
        expect(@rss_feed_data["xmlns:content"]).to eq("http://purl.org/rss/1.0/modules/content/")
        expect(@rss_feed_data["xmlns:dc"]).to eq("http://purl.org/dc/elements/1.1/")
        expect(@rss_feed_data["xmlns:media"]).to eq("http://search.yahoo.com/mrss/")
        expect(@rss_feed_data["channel"]).not_to be_nil
        expect(@rss_feed_data["channel"].is_a?(Hash)).to be_truthy
        expect(@rss_feed_data["channel"].keys.map(&:to_sym)).to include(
          :title, :link, :description, :pubDate
        )
      end
    end
  end

  context '#centsai posts with empty articles' do
    it 'should not make channel when articles is empty' do
      VCR.use_cassette 'centsai posts/empty rss feed' do
        empty_centsai_posts
        expect(centsai_posts_service.articles.empty?).to be_truthy
        channel_rss_feed_data = Hash.from_xml(centsai_posts_service.xml_rss_feed)["rss"]["channel"]
        expect(channel_rss_feed_data["title"]).to be_nil
        expect(channel_rss_feed_data["link"]).to be_nil
        expect(channel_rss_feed_data["description"]).to be_nil
      end
    end
  end
end
