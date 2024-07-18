# frozen_string_literal: true

class ExternalFeedFetcherWorker
  include Sidekiq::Worker
  MAX_RETRIES = 5
  BASE_INTERVAL = 1

  def perform(account_id, account_uri)
    account = Account.find(account_id)
    ExternalFeedService.new(account, account_uri).fetch_and_store_posts
  end
end
