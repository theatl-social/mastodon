class CreateStatusExtras < ActiveRecord::Migration[6.0]
  def change
    create_table :status_extras do |t|
      t.references :status, null: false, foreign_key: true
      t.boolean :is_federated, default: true
      t.timestamps
    end
  end
end