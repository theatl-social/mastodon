class AddNewFieldToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :new_field_name, :string
  end
end
