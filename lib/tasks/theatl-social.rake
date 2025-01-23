# frozen_string_literal: true

task stats: 'theatl_social:reset_otp'

namespace :theatl_social do
  desc 'Removes all otps from users. Run with caution'
  task :reset_otp, [:dry_run] => :environment do |t, args|
    user_ids = User.where.not(otp_secret: nil).pluck(:id)
    if args[:dry_run]
      puts user_ids.count
    else
      user_ids.each do |id|
        ResetOtpWorker.perform_async(id)
      end
    end
  end
end
