# == Schema Information
#
# Table name: status_extras
#
#  id           :bigint(8)        not null, primary key
#  status_id    :bigint(8)        not null
#  is_federated :boolean          default(TRUE)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class StatusExtra < ApplicationRecord
  belongs_to :status
end
