class AddMembershipLevelToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :membership_level, :integer
  end
end
