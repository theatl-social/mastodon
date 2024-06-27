require 'net/http'
require 'uri'
require 'json'

# we are not currently using this.

class ExternalPostsService
  MAX_RETRIES = 1
  BASE_INTERVAL = 1
  MAX_POSTS = 3

  def initialize(local_account)
    @local_account = local_account
    @local_account_id = local_account.id
    @instance_uri = extract_domain(local_account.uri)
    puts "Initialized ExternalPostsService with local_account_id: #{@local_account_id}, instance_uri: #{@instance_uri}"
  end

  def fetch_posts(max_id: nil, exclude_replies: true, only_media: false, pinned: false)
    raise ArgumentError, 'Account information is missing' unless @local_account.present?
    puts "Fetching posts with parameters - max_id: #{max_id}, exclude_replies: #{exclude_replies}, only_media: #{only_media}, pinned: #{pinned}"

    @username, @domain = lookup_local_account_info(@local_account_id)
    @external_account_id, @external_account_url = lookup_external_account(@username, @domain)
    puts "Resolved External Account - username: #{@username}, domain: #{@domain}, external_account_id: #{@external_account_id}, external_account_url: #{@external_account_url}"

    collected_posts = []
    retries = 0

    begin
      puts "COLLECTING USER'S PUBLIC TIMELINE"
      response = fetch_user_timeline(max_id: max_id, exclude_replies: exclude_replies, only_media: only_media, pinned: pinned)

      if response.is_a?(Net::HTTPSuccess)
        posts_data = JSON.parse(response.body)
        puts "Fetched #{posts_data.size} posts from external server"
        collected_posts = process_posts(posts_data, collected_posts)
      else
        Rails.logger.error "Failed to fetch user's public timeline: #{response.body}"
        raise StandardError, "Non-success response: #{response.code}"
      end
    rescue => e
      retries += 1
      if retries <= MAX_RETRIES
        sleep_interval = BASE_INTERVAL * (2**(retries - 1))
        Rails.logger.warn "Retrying fetch for account #{@external_account_id} in #{sleep_interval} seconds. Attempt #{retries}."
        puts "Retry attempt #{retries} after error: #{e.message}"
        sleep sleep_interval
        retry
      else
        Rails.logger.error "Error fetching user's public timeline for account #{@external_account_id}: #{e.message}. Exceeded retry limits."
        puts "Error: #{e.message}. Exceeded retry limits."
      end
    end

    puts "Total collected posts: #{collected_posts.size}"
    collected_posts.take(MAX_POSTS)
  end

  private

  def lookup_local_account_info(local_account_id)
    puts "Looking up local account info for account ID: #{local_account_id}"
    account = Account.find(local_account_id)
    raise StandardError, "Account not found for ID: #{local_account_id}" unless account

    puts "Found local account - username: #{account.username}, domain: #{account.domain}"
    [account.username, account.domain]
  end

  def lookup_external_account(username, domain)
    puts "Looking up external account for username: #{username}, domain: #{domain}"
    uri = URI.parse("https://#{domain}/api/v1/accounts/lookup")
    params = { acct: "#{username}@#{domain}" }
    uri.query = URI.encode_www_form(params)

    response = fetch_data(uri)
    if response.is_a?(Net::HTTPSuccess)
      account_data = JSON.parse(response.body)
      puts "Found external account - ID: #{account_data['id']}, URL: #{account_data['url']}"
      return account_data['id'], account_data['url']
    else
      Rails.logger.error "Failed to lookup external account: #{response.body}"
      raise StandardError, "Failed to lookup external account: #{response.body}"
    end
  end

  def fetch_user_timeline(max_id: nil, exclude_replies: false, only_media: false, pinned: false)
    domain = @instance_uri
    raise ArgumentError, 'Invalid account URI' unless domain

    external_max_id = max_id && max_id != 0 ? extract_external_post_id(max_id) + 1 : nil

    puts "Fetching user timeline with external_max_id: #{external_max_id}"

    uri = URI.parse("https://#{domain}/api/v1/accounts/#{@external_account_id}/statuses")
    params = { limit: MAX_POSTS } # Adjust limit as needed
    params[:max_id] = external_max_id if external_max_id
    params[:exclude_replies] = exclude_replies if exclude_replies
    params[:only_media] = only_media if only_media
    params[:pinned] = pinned if pinned
    uri.query = URI.encode_www_form(params)
    request = Net::HTTP::Get.new(uri)
    puts "Fetching user's public timeline from #{domain} with params #{params}"
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end
  end

  def process_posts(posts_data, collected_posts)
    puts "Processing posts data..."
    posts_data.each do |post|
      break if collected_posts.size >= MAX_POSTS
      puts "Processing post ID: #{post['id']}, URI: #{post['uri']}"
      processed_status = process_post_activity(post)
      if processed_status
        collected_posts << processed_status
        puts "Collected post #{collected_posts.size}: #{processed_status.id}"
      end
    end
    collected_posts
  end

  def process_post_activity(post)
    puts "Processing post activity for URI: #{post['uri']}"
    
    fetch_remote_status_service = FetchRemoteStatusService.new
    result = fetch_remote_status_service.call(post['uri'])
    puts "FetchRemoteStatusService result: #{result.inspect}"
    
    status = result
    
    status # Return the processed status
  end
  def fetch_data(uri)
    puts "Fetching data from URI: #{uri}"
    request = Net::HTTP::Get.new(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      response = http.request(request)
      puts "Response code: #{response.code}"
      response
    end
  end

  def extract_domain(uri)
    domain = URI.parse(uri).host
    puts "Extracted domain: #{domain}"
    domain
  end

  def extract_external_post_id(local_status_id)
    puts "Looking up local status for ID: #{local_status_id}"
    status = Status.find(local_status_id)
    raise StandardError, "Status not found for ID: #{local_status_id}" unless status
  
    local_status_uri = status.uri
    external_post_id = local_status_uri.split('/').last.to_i + 1
    puts "Extracted external post ID: #{external_post_id} from local status URI: #{local_status_uri}"
    external_post_id
  end

end