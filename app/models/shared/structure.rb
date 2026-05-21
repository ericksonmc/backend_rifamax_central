# == Schema Information
#
# Table name: shared_structures
#
#  id             :bigint           not null, primary key
#  access_to      :string           default([]), is an Array
#  known_as       :string
#  name           :string
#  promotional    :string
#  token          :string           default("rm_live_2a411784-4c73-4b43-9c66-ddcc5ffdc7ea")
#  url_base       :string
#  user_path      :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  shared_user_id :bigint           not null
#
# Indexes
#
#  index_shared_structures_on_shared_user_id  (shared_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (shared_user_id => shared_users.id)
#
class Shared::Structure < ApplicationRecord
  belongs_to :shared_user, class_name: 'Shared::User', foreign_key: 'shared_user_id'

  after_create :generate_token

  def self.token_preview
    'rm_live_' + SecureRandom.uuid
  end

  private

  def generate_token
    update(token: "rm_live_#{SecureRandom.uuid}")
  end
end
