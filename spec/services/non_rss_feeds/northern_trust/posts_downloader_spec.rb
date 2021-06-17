require 'spec_helper'

RSpec.describe NonRssFeeds::NorthernTrust::PostsDownloader, type: :service do
  let(:northern_trust_service) { NonRssFeeds::NorthernTrust::PostsDownloader.new({file_name: 'northern_trust_test.rss'}) }

  context '#northern trust connection' do
    it 'should be check http connection with faraday cilent' do
      VCR.use_cassette('northern trust/http connection', match_requests_on: [:method, :uri]) do
        result = northern_trust_service.http_connection
        response = result.get
        expect(response.status).to eq(200)
        expect(response.env[:method]).to eq(:get)
      end
    end
  end

  context '#northern trust initialize data and vaildate' do
    before do
      ArticleItem.destroy_all
      VCR.use_cassette 'northern trust/posts downloader' do
        expect {
          @articles = northern_trust_service.articles
        }.to change { ArticleItem.count }
      end
    end

    it 'should be vaildate northern trust of article_item source and scope' do
      expect(ArticleItem.northern_trust.first.source).to eq(ArticleItem::NORTHERN_TRUST_ITEM)
      expect(ArticleItem.first.guid).not_to be_nil
      expect(ArticleItem.northern_trust.pluck(:guid).uniq).to eq(ArticleItem.northern_trust.pluck(:guid))
    end

    it 'should be vaildate northern trust articles data' do
      expect(@articles.present?).to eq(@articles.is_a?(Array))
      expect(@articles&.first&.keys&.map(&:to_sym)).to include(
        :title, :summary, :url, :articleContentType,
        :articleDate, :articlePdfUrl, :articleImageUrl,
        :articleAltText, :onlineDate, :offlineDate,
        :publicationType, :newItem, :linkText, :renderType,
        :articleCaption, :experts, :articleDescription,
        :articleURL, :articleTitle
      )
    end

    it 'should be vaildate initialize channel data' do
      expect(northern_trust_service.channel_data.is_a?(Hash)).to be_truthy
      expect(northern_trust_service.channel_data.empty?).to be_truthy
    end
  end

  context '#northern trust for make feed' do
    before do
      ArticleItem.northern_trust.destroy_all
      VCR.use_cassette 'northern trust/xml rss feed' do
        @xml_rss_feed = Hash.from_xml(northern_trust_service.send(:make_feed))
        @rss_feed_data = @xml_rss_feed["rss"]
      end
    end

    it 'should vaildate make feed for posts to xml content' do
      expect(northern_trust_service.articles.present?).to eq(northern_trust_service.articles.is_a?(Array))
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
      @rss_feed_data.dig("channel", "item")
      item_details = @rss_feed_data.dig("channel", "item")
      expect(item_details.present?).to eq(item_details.is_a?(Array))
      %i[guid title link description encoded].each do |key|
        expect(item_details.first.keys.map(&:to_sym)).to include(key)
      end
    end
  end
end
