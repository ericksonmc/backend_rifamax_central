class AddIntegrationMetadataToSharedUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :shared_users, :structure_id, :integer
    add_column :shared_users, :integrator_id, :integer
  end
end
