class AddIntegratorTypeToSharedUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :shared_users, :integrator_type, :string
  end
end
