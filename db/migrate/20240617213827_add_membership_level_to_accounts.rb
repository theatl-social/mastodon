# frozen_string_literal: true

class AddMembershipLevelToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :membership_level, :integer, default: 0, null: true
  end
end
