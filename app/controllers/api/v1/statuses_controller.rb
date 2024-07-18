# frozen_string_literal: true

MAX_DEPTH_CHECK_NOT_FEDERATED = 25

class Api::V1::StatusesController < Api::BaseController
  include Authorization

  before_action -> { authorize_if_got_token! :read, :'read:statuses' }, except: [:create, :update, :destroy]
  before_action -> { doorkeeper_authorize! :write, :'write:statuses' }, only:   [:create, :update, :destroy]
  before_action :require_user!, except:  [:show, :context]
  before_action :set_status, only:       [:show, :context]
  before_action :set_thread, only:       [:create]


  
  override_rate_limit_headers :create, family: :statuses
  override_rate_limit_headers :update, family: :statuses

  # This API was originally unlimited, pagination cannot be introduced without
  # breaking backwards-compatibility. Arbitrarily high number to cover most
  # conversations as quasi-unlimited, it would be too much work to render more
  # than this anyway
  CONTEXT_LIMIT = 4_096

  # This remains expensive and we don't want to show everything to logged-out users
  ANCESTORS_LIMIT         = 40
  DESCENDANTS_LIMIT       = 60
  DESCENDANTS_DEPTH_LIMIT = 20

  def show
    cache_if_unauthenticated!
    @status = cache_collection([@status], Status).first
    render json: @status, serializer: REST::StatusSerializer
  end

  def context
    cache_if_unauthenticated!

    ancestors_limit         = CONTEXT_LIMIT
    descendants_limit       = CONTEXT_LIMIT
    descendants_depth_limit = nil

    if current_account.nil?
      ancestors_limit         = ANCESTORS_LIMIT
      descendants_limit       = DESCENDANTS_LIMIT
      descendants_depth_limit = DESCENDANTS_DEPTH_LIMIT
    end

    ancestors_results   = @status.in_reply_to_id.nil? ? [] : @status.ancestors(ancestors_limit, current_account)
    descendants_results = @status.descendants(descendants_limit, current_account, descendants_depth_limit)
    loaded_ancestors    = cache_collection(ancestors_results, Status)
    loaded_descendants  = cache_collection(descendants_results, Status)

    @context = Context.new(ancestors: loaded_ancestors, descendants: loaded_descendants)
    statuses = [@status] + @context.ancestors + @context.descendants

    render json: @context, serializer: REST::ContextSerializer, relationships: StatusRelationshipsPresenter.new(statuses, current_user&.account_id)
  end

  def check_parent_visibility(thread, initial_visibility)
    return initial_visibility unless thread.present?
  
    parent_status = thread
    depth = 0
  
    while parent_status.present? && depth < MAX_DEPTH_CHECK_NOT_FEDERATED
      if parent_status.visibility == 'not_federated'
        return :not_federated
      end
      # Print all methods
      # puts "Methods:"
      # puts parent_status.methods.sort

      # # Print all instance variables and their values
      # puts "\nInstance Variables:"
      # parent_status.instance_variables.each do |var|
      #   puts "#{var} = #{parent_status.instance_variable_get(var).inspect}"
      # end
      parent_status = parent_status.in_reply_to_id.present? ? Status.find(parent_status.in_reply_to_id) : nil
      depth += 1
    end
  
    initial_visibility
  end

  def create
    status_text = status_params[:status]
    visibility = check_parent_visibility(@thread, status_params[:visibility])
  
    if status_text.include?('!local')
      status_text = status_text.gsub('!local', '').strip
      visibility = :not_federated
    end
  
    @status = PostStatusService.new.call(
      current_user.account,
      text: status_text,
      thread: @thread,
      media_ids: status_params[:media_ids],
      sensitive: status_params[:sensitive],
      spoiler_text: status_params[:spoiler_text],
      visibility: visibility,
      language: status_params[:language],
      scheduled_at: status_params[:scheduled_at],
      application: doorkeeper_token.application,
      poll: status_params[:poll],
      allowed_mentions: status_params[:allowed_mentions],
      idempotency: request.headers['Idempotency-Key'],
      with_rate_limit: true
    )

    render json: @status, serializer: @status.is_a?(ScheduledStatus) ? REST::ScheduledStatusSerializer : REST::StatusSerializer
  rescue PostStatusService::UnexpectedMentionsError => e
    unexpected_accounts = ActiveModel::Serializer::CollectionSerializer.new(
      e.accounts,
      serializer: REST::AccountSerializer
    )
    render json: { error: e.message, unexpected_accounts: unexpected_accounts }, status: 422
  end

  def update
    @status = Status.where(account: current_account).find(params[:id])
    authorize @status, :update?

    UpdateStatusService.new.call(
      @status,
      current_account.id,
      text: status_params[:status],
      media_ids: status_params[:media_ids],
      media_attributes: status_params[:media_attributes],
      sensitive: status_params[:sensitive],
      language: status_params[:language],
      spoiler_text: status_params[:spoiler_text],
      poll: status_params[:poll]
    )

    render json: @status, serializer: REST::StatusSerializer
  end

  def destroy
    @status = Status.where(account: current_account).find(params[:id])
    authorize @status, :destroy?

    @status.discard_with_reblogs
    StatusPin.find_by(status: @status)&.destroy
    @status.account.statuses_count = @status.account.statuses_count - 1
    json = render_to_body json: @status, serializer: REST::StatusSerializer, source_requested: true

    RemovalWorker.perform_async(@status.id, { 'redraft' => true })

    render json: json
  end

  private

  def set_status
    @status = Status.find(params[:id])
    authorize @status, :show?
  rescue Mastodon::NotPermittedError
    not_found
  end

  def set_thread
    @thread = Status.find(status_params[:in_reply_to_id]) if status_params[:in_reply_to_id].present?
    authorize(@thread, :show?) if @thread.present?
  rescue ActiveRecord::RecordNotFound, Mastodon::NotPermittedError
    render json: { error: I18n.t('statuses.errors.in_reply_not_found') }, status: 404
  end

  def status_params
    params.permit(
      :status,
      :in_reply_to_id,
      :sensitive,
      :spoiler_text,
      :visibility,
      :language,
      :scheduled_at,
      allowed_mentions: [],
      media_ids: [],
      media_attributes: [
        :id,
        :thumbnail,
        :description,
        :focus,
      ],
      poll: [
        :multiple,
        :hide_totals,
        :expires_in,
        options: [],
      ]
    )
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end

  def push_to_feed_or_list
    @status = Status.find_by(id: params[:id])
    if @status.nil?
      render json: { error: 'Post not found' }, status: 404
      return
    end

    authorize @status, :show?

    if current_user.role == 'Admin'
      target_user = User.find_by(id: params[:user_id])
      if target_user.nil?
        render json: { error: 'User not found' }, status: 404
        return
      end
      if params[:list_id].present?
        @list = List.find_by(id: params[:list_id])
        if @list.nil?
          render json: { error: 'List not found' }, status: 404
          return
        end
        authorize @list, :push?, target_user
        @list.statuses << @status
      else
        target_user.home_feed.insert_status(@status)
      end
      render json: @status, serializer: REST::StatusSerializer
    else
      render json: { error: 'Unauthorized' }, status: 403
    end
  end
end
