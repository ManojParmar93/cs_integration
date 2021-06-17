require 'spec_helper'

RSpec.describe NonRssFeeds::CentsaiPosts::RssFeedUploader, type: :service do
  let(:s3) { AWS::S3.new }
  let(:bucket) { s3.buckets[ENV['S3_BUCKET']].objects["centsai/#{file_name}"] }
  let(:file_content) { NonRssFeeds::CentsaiPosts::PostsDownloader.new().xml_rss_feed }
  let(:file_name) { "centsai_post_test.rss" }
  let(:file_location) { "public/centsai/#{file_name}" }

  context '#centsai posts of rss feed uploader' do
    before do
      VCR.use_cassette('centsai posts/uploader call', match_requests_on: [:method, :uri]) do
        @response = NonRssFeeds::CentsaiPosts::RssFeedUploader.new({file_name: 'centsai_post_test.rss'}).call
      end
    end

    it 'should be call centsai posts of rss feed uploader' do
      expect(@response).not_to be_nil
    end

    xit 'should be write in correct bucket' do
      expect(@response).to include(ENV['S3_BUCKET'])
    end

    xit 'should be validate file name' do
      expect(@response).to include(file_name)
    end
  end

  context '#centsai posts are present when s3 will not upload file' do
    before do
      file_content
    end

    xit 'validate centsai of items are present before calling again' do
      expect(ArticleItem.present?).to be_truthy
      expect(ArticleItem.centsai.count).not_to eq(0)
      expect(ArticleItem.centsai.first.source).to include ("centsai")
    end

    xit 'centsai post items are present when it should return error message' do
      response = NonRssFeeds::CentsaiPosts::RssFeedUploader.new({file_name: 'centsai_post_test.rss'}).call
      expect(response).to eq("\n\n---No new articles available for centsai---\n\n")
      expect(ArticleItem.present?).to be_truthy
    end
  end
end
