# app/workers/external_feed_fetcher_worker.rb
class ExternalFeedFetcherWorker
  include Sidekiq::Worker

  def perform(account_id, additional_posts_to_collect)
    account = Account.find(account_id)
    service = ExternalFeedService.new(account_id, additional_posts_to_collect)
    service.fetch_and_store_posts
  end
end