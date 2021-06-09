require 'aws-sdk'
require 'vcr'

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock, :faraday
  config.ignore_request { ENV['DISABLE_VCR'] }
  config.ignore_localhost = true
  config.default_cassette_options = { match_requests_on: [:body, :uri, :method] }

  #filter sensitive data
  config.filter_sensitive_data('<<AWS_ACCESS_KEY_ID>>') { ENV['AWS_ACCESS_KEY_ID'] }
  config.filter_sensitive_data('<<AWS_SECRET_ACCESS_KEY>>') { ENV['AWS_SECRET_ACCESS_KEY'] }
  config.filter_sensitive_data('<<S3_BUCKET>>') { ENV['S3_BUCKET'] }
  config.filter_sensitive_data('<<USER_NAME>>') { ENV['USER_NAME'] }
  config.filter_sensitive_data('<<PASSWORD>>') { ENV['PASSWORD'] }
  config.filter_sensitive_data('<<S3_BUCKET_REGION>>') { ENV['S3_BUCKET_REGION'] }
end
