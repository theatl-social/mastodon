# == Schema Information
#
# Table name: memberships
#
#  id           :bigint(8)        not null, primary key
#  account_id   :bigint(8)        not null
#  level        :integer
#  last_updated :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Membership < ApplicationRecord
  belongs_to :account

  before_save :update_last_updated

  private

  def update_last_updated
    self.last_updated = Time.current
  end
end