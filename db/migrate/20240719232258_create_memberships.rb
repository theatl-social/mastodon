class CreateMemberships < ActiveRecord::Migration[7.0]
  def change
    create_table :memberships do |t|
      t.references :account, null: false, foreign_key: true
      t.integer :level
      t.datetime :last_updated

      t.timestamps
    end
  end
end
