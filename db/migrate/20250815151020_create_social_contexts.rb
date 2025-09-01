class CreateSocialContexts < ActiveRecord::Migration[7.0]
  def change
    create_table :social_contexts do |t|
      t.string :key
      t.jsonb :context

      t.timestamps
    end
  end
end
