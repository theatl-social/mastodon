# frozen_string_literal: true

class ResetOtpWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', lock: :until_executed, lock_ttl: 1.week.to_i

  def perform(user_id, options = {})
    user = User.find(user_id)

    user.disable_two_factor!
  rescue ActiveRecord::RecordNotFound
    true
  end
end
