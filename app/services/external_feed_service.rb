require 'net/http'
require 'uri'
require 'json'

class ExternalFeedService
  MAX_RETRIES = 5
  BASE_INTERVAL = 1
  MAX_POSTS_TO_COLLECT = 15

  def initialize(account_id, additional_posts_to_collect)
    @account = Account.find(account_id)
    @account_uri = @account.uri
    @additional_posts_to_collect = additional_posts_to_collect
    @collected_posts = []
    @cached_post_ids = cached_post_ids_for_account
    puts "Initialized ExternalFeedService for Account ID: #{@account.id}, URI: #{@account.uri}, Additional Posts to Collect: #{@additional_posts_to_collect}"
  end

  def fetch_and_store_posts
    retries = 0


    max_id = fetch_max_uri_from_database(@account.id)

    puts 'ACCOUNT: ' << @account.id.to_s
    puts 'ACCOUNT URI: ' << @account.uri

    begin

      outbox_url = "#{@account_uri}/outbox"
      outbox_url += "?max_id=#{max_id}" if max_id
      puts "COLLECTING OUTBOX #{outbox_url}"
  
      response = fetch_response(outbox_url)

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

  def cached_post_ids_for_account
    cached_ids = Status.where(account: @account).pluck(:uri)
    puts "Cached Post IDs for Account #{@account.id}: #{cached_ids}"
    cached_ids
  end

  def fetch_response(url)
    uri = URI.parse(url)
    params = URI.decode_www_form(uri.query || '') << ['type', 'Create']
    uri.query = URI.encode_www_form(params)
  
    request = Net::HTTP::Get.new(uri)
    puts "Fetching URL: #{uri}"
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      response = http.request(request)
      puts "Fetched Response: #{response.code}"
      response
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
        posts = posts_data['orderedItems'].select { |post| post['type'] == 'Create' }
        puts "POSTS FETCHED: #{posts.map { |post| post['id'] }}"

        filtered_posts = posts.reject { |post| @cached_post_ids.include?(post['id'].sub('/activity','')) }
        puts "FILTERED POSTS: #{filtered_posts.map { |post| post['id'] }}"

        filtered_posts.each do |post|

          @collected_posts << post

          if @collected_posts.size >= @additional_posts_to_collect
            send_collected_posts_to_remote_service
            return
          end
        end

        next_page_url = posts_data['next']
        if next_page_url
          puts "NEXT PAGE URL: #{next_page_url}"
          fetch_posts_from_page(next_page_url)
        else
          puts "No more pages available."
          send_collected_posts_to_remote_service
        end
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


  def fetch_max_uri_from_database(account_id)
    # Fetch all URIs for the given account_id from the database
    uris = Status.where(account_id: account_id).pluck(:uri)
    puts "Fetched URIs from database for Account ID #{account_id}: #{uris}"
  
    # Return nil if there are no URIs
    return nil if uris.empty?
  
    # Extract the last item in the path of each URI and convert to integers
    last_items = uris.map { |uri| uri.split('/').last.to_i }
    puts "Extracted last items: #{last_items}"
  
    # Find the maximum value
    max_id = last_items.min
    puts "Max (min) ID from database URIs: #{max_id}"
  
    max_id
  end

  def send_collected_posts_to_remote_service
    puts "SENDING COLLECTED POSTS TO REMOTE SERVICE"
    @collected_posts.each do |post|
      puts "SENDING POST ID: #{post['id']} TO REMOTE SERVICE"
      ActivityPub::FetchRemoteStatusService.new.call(post['id'])
    end
  end
end