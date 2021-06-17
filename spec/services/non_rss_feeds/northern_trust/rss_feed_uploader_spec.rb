require 'spec_helper'

RSpec.describe NonRssFeeds::NorthernTrust::RssFeedUploader, type: :service do
  let(:s3) { AWS::S3.new }
  let(:bucket) { s3.buckets[ENV['S3_BUCKET']].objects["northerntrust/#{file_name}"] }
  let(:file_content) { NonRssFeeds::NorthernTrust::PostsDownloader.new().xml_rss_feed }
  let(:file_name) { "northern_trust_test.rss" }
  let(:file_location) { "public/northerntrust/#{file_name}" }

  context '#northern trust of rss feed uploader' do
    before do
      ArticleItem.destroy_all
      VCR.use_cassette('northern trust/uploader call', match_requests_on: [:method, :uri]) do
        @response = NonRssFeeds::NorthernTrust::RssFeedUploader.new(file_name: 'northern_trust_test.rss').call
      end
    end

    it 'should be call northern trust of rss feed uploader' do
      expect(@response).not_to be_nil
    end

    xit 'should be write in correct bucket' do
      expect(@response).to include(ENV['S3_BUCKET'])
    end

    xit 'should be validate file name' do
      expect(@response).to include(file_name)
    end
  end

  context '#northern trust are present when s3 will not upload file' do
    before do
      file_content
    end

    xit 'validate northern trust of items are present before calling again' do
      expect(ArticleItem.present?).to be_truthy
      expect(ArticleItem.northern_trust.count).not_to eq(0)
      expect(ArticleItem.northern_trust.first.source).to include ("northern_trust")
    end

    xit 'northern trust of items are present when it should return error message' do
      VCR.use_cassette('northern trust/are items present', match_requests_on: [:method, :uri]) do
        response = NonRssFeeds::NorthernTrust::RssFeedUploader.new({file_name: 'northern_trust_test.rss'}).call
        expect(response).to eq("\n\n---No new articles available for Northern Trust---\n\n")
        expect(ArticleItem.present?).to be_truthy
      end
    end
  end
end
