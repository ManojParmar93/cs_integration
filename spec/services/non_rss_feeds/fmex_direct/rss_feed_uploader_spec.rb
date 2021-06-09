require 'rails_helper'

RSpec.describe NonRssFeeds::FmexDirect::RssFeedUploader, type: :service do
  let(:s3) { AWS::S3.new }
  let(:bucket) { s3.buckets[ENV['S3_BUCKET']].objects["fmax_direct/#{file_name}"] }
  let(:file_details) { NonRssFeeds::FmexDirect::PostsDownloader.new().call }
  let(:file_content) { file_details[:xml_rss_feed] }
  let(:file_name) { file_details[:file_name] }
  let(:file_location) { "public/fmax_direct/#{file_name}" }

  context '#fmex direct of rss feed uploader' do
    before do
      VCR.use_cassette('fmex direct/uploader call', match_requests_on: [:method, :uri]) do
        @response = NonRssFeeds::FmexDirect::RssFeedUploader.new.call
      end
    end

    it 'should be call fmex direct of rss feed uploader' do
      expect(@response).not_to be_nil
    end

    it 'should be write in correct bucket' do
      expect(@response).to include(ENV['S3_BUCKET'])
    end

    it 'should be validate file name' do
      expect(@response).to include(file_name)
    end
  end

  context '#fmex direct are present when s3 will not upload file' do
    before do
      file_details
    end

    it 'validate fmex direct of items are present before calling again' do
      expect(ArticleItem.present?).to be_truthy
      expect(ArticleItem.fmex_direct.count).not_to eq(0)
      expect(ArticleItem.fmex_direct.first.source).to include ("fmex_direct")
    end

    it 'fmex direct items are present when it should return error message' do
      VCR.use_cassette('fmex direct/are items present', match_requests_on: [:method, :uri]) do
        response = NonRssFeeds::FmexDirect::RssFeedUploader.new.call
        expect(response).to eq("\n\n---No new articles available for Fmex Direct---\n\n")
        expect(ArticleItem.present?).to be_truthy
      end
    end
  end
end
