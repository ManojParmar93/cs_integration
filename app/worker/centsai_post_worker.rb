class CentsaiPostWorker
  include Sidekiq::Worker
  sidekiq_options  :retry => 1
  
  def perform
    CentsaiPosts::RssFeedUploader.new().call
    FmexDirect::RssFeedUploader.new().call
    NorthernTrust::RssFeedUploader.new().call
  end
end