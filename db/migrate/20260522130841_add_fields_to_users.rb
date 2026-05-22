class AddFieldsToUsers < ActiveRecord::Migration[8.2]
  def change
    add_column :users, :language, :integer, default: 2, null: false
    add_column :users, :frequency, :integer, default: 2, null: false
    add_column :users, :confirmed, :boolean, default: false, null: false
    add_column :users, :confirmation_token, :string
    add_column :users, :plan, :integer, default: 0, null: false
    add_column :users, :plan_expires_at, :datetime
    add_index :users, :confirmation_token, unique: true
  end
end
