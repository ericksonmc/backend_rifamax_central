# frozen_string_literal: true

# == Schema Information
#
# Table name: shared_users
#
#  id              :bigint           not null, primary key
#  avatar          :string
#  dni             :string
#  email           :string
#  is_active       :boolean
#  is_first_entry  :boolean          default(FALSE)
#  is_integration  :boolean          default(FALSE)
#  module_assigned :integer          default([]), is an Array
#  name            :string
#  password_digest :string
#  phone           :string
#  rifero_ids      :integer          default([]), is an Array
#  role            :string
#  slug            :string
#  welcoming       :boolean          default(TRUE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  integrator_id   :integer
#  structure_id    :integer
#
require 'test_helper'

module Shared
  class UserTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end
