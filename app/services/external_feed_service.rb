require 'net/http'
require 'uri'
require 'json'

class ExternalFeedService
  MAX_RETRIES = 5
  BASE_INTERVAL = 1
  MAX_POSTS = 100

  def initialize(account, account_uri)
    @account = account
    @account_uri = account_uri
  end

  def fetch_and_store_posts
    retries = 0

    puts 'ACCOUNT: ' << @account.id.to_s
    puts 'ACCOUNT URI: ' << @account.uri

    begin
      puts "COLLECTING OUTBOX #{@account_uri}/outbox"
      response = fetch_response("#{@account_uri}/outbox")
      puts 'RESPONSE AWAIT'

      if response.is_a?(Net::HTTPSuccess)
        puts 'RESPONSE SUCCESS IS GOOD'
        outbox_data = JSON.parse(response.body)
        first_page_url = outbox_data['first']
        puts "FIRST PAGE URL IS #{first_page_url}"
        fetch_posts_from_page(first_page_url)
      else
        Rails.logger.error "Failed to fetch outbox for account #{@account.id} from #{@account_uri}: #{response.body}"
        raise StandardError, "Non-success response: #{response.code}"
      end
    rescue => e
      retries += 1
      if retries <= MAX_RETRIES
        sleep_interval = BASE_INTERVAL * (2**(retries - 1))
        puts "Retrying fetch for account #{@account.id} in #{sleep_interval} seconds. Attempt #{retries}."
        sleep sleep_interval
        retry
      else
        Rails.logger.error "Error fetching outbox for account #{@account.id}: #{e.message}. Exceeded retry limits."
      end
    end
  end

  private

  def fetch_response(url)
    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end
  end

  def fetch_posts_from_page(page_url)
    retries = 0
    puts "FETCHING POSTS FROM #{page_url}"
    begin
      response = fetch_response(page_url)
      if response.is_a?(Net::HTTPSuccess)
        puts "FETCHED SUCCESS FROM #{page_url}"
        posts_data = JSON.parse(response.body)
        posts = posts_data['orderedItems']

        posts.each do |post|
          puts "EVALUATING POST #{post['uri']}"
          puts 'STORING POST'
          process_post_activity(post)
        end

        next_page_url = posts_data['next']
        fetch_posts_from_page(next_page_url) if next_page_url && posts.size < MAX_POSTS
      else
        puts 'FAILURE!!!'
        Rails.logger.error "Failed to fetch posts from page: #{page_url}: #{response.body}"
        raise StandardError, "Non-success response: #{response.code}"
      end
    rescue => e
      retries += 1
      if retries <= MAX_RETRIES
        sleep_interval = BASE_INTERVAL * (2**(retries - 1))
        Rails.logger.warn "#{e.message} Retrying fetch for page #{page_url} in #{sleep_interval} seconds. Attempt #{retries}."
        sleep sleep_interval
        retry
      else
        Rails.logger.error "Error fetching posts from page #{page_url}: #{e.message}. Exceeded retry limits."
      end
    end
  end

  def post_already_collected?(post)
    Status.exists?(uri: post['id'])
  end

  def process_post_activity(post)
    # Construct a Create activity JSON
    # Process the activity using ActivityPub::ProcessingService
    ActivityPub::FetchRemoteStatusService.new.call(post['id'])
  end
end
