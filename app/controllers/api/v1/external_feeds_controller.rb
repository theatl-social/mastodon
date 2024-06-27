# app/controllers/api/v1/external_feeds_controller.rb
module Api
    module V1
      class ExternalFeedsController < ApplicationController
        before_action :authenticate_user!
  
        def fetch_posts
          account_id = params[:account_id]
          additional_posts_to_collect = params[:additional_posts_to_collect].to_i
  
          ExternalFeedFetcherWorker.perform_async(account_id, additional_posts_to_collect)
          
          render json: { message: 'External feed fetch initiated.' }, status: :accepted
        end
      end
    end
  end