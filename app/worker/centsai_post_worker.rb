class CentsaiPostWorker
  include Sidekiq::Worker
  sidekiq_options  :retry => 1
  
  def perform
    NonRssFeeds::CentsaiPosts::RssFeedUploader.new().call
    NonRssFeeds::FmexDirect::RssFeedUploader.new().call
    NonRssFeeds::NorthernTrust::RssFeedUploader.new().call
  end
end