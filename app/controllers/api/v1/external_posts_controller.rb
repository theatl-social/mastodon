module Api
  module V1
    class ExternalPostsController < ApplicationController
      before_action :authenticate_user!

      def fetch_external_posts

        puts 'EXTERNAL POSTS CONTROLLER CALLED EPC'

        account_id = params[:account_id]
        max_id = params[:max_id] || 0
        with_replies = params[:with_replies]
        tagged = params[:tagged].present?

        account = Account.find_by(id: account_id)
        if account.nil?
          render json: { error: 'Account not found' }, status: 404
          return
        end

        begin
          service = ExternalPostsService.new(account)
          new_max_id = params[:max_id].nil? ? 0 : params[:max_id]
          posts = service.fetch_posts(max_id: new_max_id, exclude_replies: !with_replies)
          render json: posts
        rescue ArgumentError => e
          render json: { error: e.message }, status: 400
        rescue => e
          Rails.logger.error "Error fetching external posts: #{e.message}"
          render json: { error: 'Failed to fetch external posts' }, status: 500
        end
      end
    end
  end
end
