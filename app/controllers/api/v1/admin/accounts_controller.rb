# frozen_string_literal: true

class Api::V1::Admin::AccountsController < Api::BaseController
  include Authorization
  include AccountableConcern

  LIMIT = 100

  before_action -> { authorize_if_got_token! :'admin:read', :'admin:read:accounts' }, only: [:index, :show]
  before_action -> { authorize_if_got_token! :'admin:write', :'admin:write:accounts' }, except: [:index, :show]
  before_action :set_accounts, only: :index
  before_action :set_account, except: [:index, :admin_create]
  before_action :require_local_account!, only: [:enable, :approve, :reject]

  after_action :verify_authorized
  after_action :insert_pagination_headers, only: :index

  FILTER_PARAMS = %i(
    local
    remote
    by_domain
    active
    pending
    disabled
    sensitized
    silenced
    suspended
    username
    display_name
    email
    ip
    staff
  ).freeze

  PAGINATION_PARAMS = (%i(limit) + FILTER_PARAMS).freeze

  def index
    authorize :account, :index?
    render json: @accounts, each_serializer: REST::Admin::AccountSerializer
  end

  def show
    authorize @account, :show?
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def enable
    authorize @account.user, :enable?
    @account.user.enable!
    log_action :enable, @account.user
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def approve
    authorize @account.user, :approve?
    @account.user.approve!
    log_action :approve, @account.user
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def reject
    authorize @account.user, :reject?
    DeleteAccountService.new.call(@account, reserve_email: false, reserve_username: false)
    log_action :reject, @account.user
    render_empty
  end

  def destroy
    authorize @account, :destroy?
    Admin::AccountDeletionWorker.perform_async(@account.id)
    render_empty
  end

  def unsensitive
    authorize @account, :unsensitive?
    @account.unsensitize!
    log_action :unsensitive, @account
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def unsilence
    authorize @account, :unsilence?
    @account.unsilence!
    log_action :unsilence, @account
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def unsuspend
    authorize @account, :unsuspend?
    @account.unsuspend!
    Admin::UnsuspensionWorker.perform_async(@account.id)
    log_action :unsuspend, @account
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def update_membership_level
    account = Account.find(params[:id])
    authorize account, :update_membership_level?
    membership_level = params[:level]
  
    if account.membership
      if account.membership.update(level: membership_level)
        render json: { message: 'Membership level updated successfully' }, status: :ok
      else
        render json: { error: account.membership.errors.full_messages }, status: :unprocessable_entity
      end
    else
      membership = account.build_membership(level: membership_level, last_updated: Time.current)
      if membership.save
        render json: { message: 'Membership level updated successfully' }, status: :ok
      else
        render json: { error: membership.errors.full_messages }, status: :unprocessable_entity
      end
    end
  rescue Pundit::NotAuthorizedError
    render json: { error: 'You are not authorized to perform this action' }, status: :forbidden
  end

  
  def admin_create
    authorize :account, :admin_create?
  
    role_id = nil
    username = params[:username]
    email = params[:email]
    confirmed = params[:confirmed] || false
    reattach = params[:reattach] || false
    force = params[:force] || false
    approve = params[:approve] || false
    role_name = params[:role]
    is_bot = params[:is_bot] || false
  
    json_data = JSON.parse(request.body.read)
    bio = json_data['bio']
    extra_fields = json_data['extra_fields']
    header_picture = json_data['header_picture']
    avatar_picture = json_data['avatar_picture']
  
    if role_name
      role = UserRole.find_by(name: role_name)
      if role.nil?
        render json: { error: 'Cannot find user role with that name' }, status: :unprocessable_entity
        return
      end
      role_id = role.id
    end
  
  
    # # Decode base64 images if provided
    # if avatar_picture
    #   decoded_avatar = Base64.decode64(avatar_picture.split(',').last)
    # end
    # if header_picture
    #   decoded_header = Base64.decode64(header_picture.split(',').last)
    # end
  
    # Create account with conditional attributes
    account_attributes = {
      username: username,
      actor_type: is_bot ? 'Service' : 'Person'
    }
    account_attributes[:display_name] = json_data['display_name'] if json_data['display_name'].present?
    account_attributes[:note] = bio if bio.present?
    account_attributes[:fields] = extra_fields if extra_fields.present?
  
    account = Account.new(account_attributes)
  
    password = SecureRandom.hex
    user = User.new(
      email: email, 
      password: password, 
      agreement: true, 
      role_id: role_id, 
      confirmed_at: confirmed ? Time.now.utc : nil, 
      bypass_invite_request_check: true
    )
  
    if reattach
      account = Account.find_local(username) || Account.new(username: username)
  
      if account.user.present? && !force
        render json: { error: 'The chosen username is currently in use. Use force to reattach it anyway and delete the other user' }, status: :unprocessable_entity
        return
      elsif account.user.present?
        DeleteAccountService.new.call(account, reserve_email: false, reserve_username: false)
        account = Account.new(username: username)
      end
    end
  
    account.suspended_at = nil
    user.account = account
  
    if user.save
      # if avatar_picture
      #   account.avatar.attach(io: StringIO.new(decoded_avatar), filename: "#{username}_avatar.png", content_type: 'image/png')
      # end
  
      # if header_picture
      #   account.header.attach(io: StringIO.new(decoded_header), filename: "#{username}_header.png", content_type: 'image/png')
      # end
  
      if confirmed
        user.confirmed_at = nil
        user.confirm!
      end
  
      user.approve! if approve
  
      render json: { message: 'Account created successfully', password: password }, status: :ok
    else
      render json: { error: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_accounts
    @accounts = filtered_accounts.order(id: :desc).includes(user: [:invite_request, :invite, :ips]).to_a_paginated_by_id(limit_param(LIMIT), params_slice(:max_id, :since_id, :min_id))
  end

  def set_account
    @account = Account.find(params[:id])
  end

  def filtered_accounts
    AccountFilter.new(translated_filter_params).results
  end

  def filter_params
    params.permit(*FILTER_PARAMS)
  end

  def translated_filter_params
    translated_params = { origin: 'local', status: 'active' }.merge(filter_params.slice(*AccountFilter::KEYS))

    translated_params[:origin] = 'remote' if params[:remote].present?

    %i(active pending disabled silenced suspended).each do |status|
      translated_params[:status] = status.to_s if params[status].present?
    end

    translated_params[:role_ids] = UserRole.that_can(:manage_reports).map(&:id) if params[:staff].present?

    translated_params
  end

  def insert_pagination_headers
    set_pagination_headers(next_path, prev_path)
  end

  def next_path
    api_v1_admin_accounts_url(pagination_params(max_id: pagination_max_id)) if records_continue?
  end

  def prev_path
    api_v1_admin_accounts_url(pagination_params(min_id: pagination_since_id)) unless @accounts.empty?
  end

  def pagination_max_id
    @accounts.last.id
  end

  def pagination_since_id
    @accounts.first.id
  end

  def records_continue?
    @accounts.size == limit_param(LIMIT)
  end

  def pagination_params(core_params)
    params.slice(*PAGINATION_PARAMS).permit(*PAGINATION_PARAMS).merge(core_params)
  end

  def require_local_account!
    forbidden unless @account.local? && @account.user.present?
  end
end
