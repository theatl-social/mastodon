# frozen_string_literal: true

class ActivityPub::DistributionWorker < ActivityPub::RawDistributionWorker
  # Distribute a new status or an edit of a status to all the places
  # where the status is supposed to go or where it was interacted with
  def perform(status_id)
    @status  = Status.find(status_id)
    @account = @status.account

    distribute!
  rescue ActiveRecord::RecordNotFound
    true
  end

  protected

  def inboxes
    @inboxes ||= StatusReachFinder.new(@status).inboxes
  end

  def payload
    @payload ||= Oj.dump(serialize_payload(activity, ActivityPub::ActivitySerializer, signer: @account))
  end

  def activity
    ActivityPub::ActivityPresenter.from_status(@status)
  end

  def options
    { 'synchronize_followers' => @status.private_visibility? }
  end
end

# # frozen_string_literal: true

# class ActivityPub::DistributionWorker < ActivityPub::RawDistributionWorker
#   # Distribute a new status or an edit of a status to all the places
#   # where the status is supposed to go or where it was interacted with
#   def perform(status_id)
#     @status  = Status.find(status_id)
#     @account = @status.account

#     # Handle local distribution if the status is not federated
#     distribute_locally! unless @status.is_federated?
    
#     # Return early if the status is not federated, preventing external federation
#     return unless @status.is_federated?

#     # Federate the status if it is federated
#     distribute!
#   rescue ActiveRecord::RecordNotFound
#     true
#   end

#   protected

#   def distribute_locally!
#     # Logic to distribute the status locally within the instance
#     FanOutOnWriteService.new.call(@status, **options.symbolize_keys)
#     NotifyService.new.call(@status)
#   end

#   def inboxes
#     @inboxes ||= StatusReachFinder.new(@status).inboxes
#   end

#   def payload
#     @payload ||= Oj.dump(serialize_payload(activity, ActivityPub::ActivitySerializer, signer: @account))
#   end

#   def activity
#     ActivityPub::ActivityPresenter.from_status(@status)
#   end

#   def options
#     { 'synchronize_followers' => @status.private_visibility? }
#   end
# end