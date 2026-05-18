# frozen_string_literal: true

@user_data = JSON.parse(File.open('./old/users_data.json').read)
@belongs = JSON.parse(File.open('./old/dump_belongs.json').read)

@new_all_data = []

@user_data.each do |data|
  @user_parsed = JSON.parse(data['user'])

  @modules = []

  @user_parsed['access_permissions'].each do |module_name|
    case module_name
    when 'Rifamax'
      @modules << 1
    when 'X100'
      @modules << 2
    when '50/50'
      @modules << 3
    end
  end

  @new_all_data << {
    id: @user_parsed['id'],
    name: @user_parsed['name'],
    email: @user_parsed['email'],
    dni: @user_parsed['cedula'],
    password_digest: @user_parsed['password_digest'],
    role: @user_parsed['role'],
    phone: data['phone'],
    created_at: @user_parsed['created_at'],
    updated_at: @user_parsed['updated_at'],
    module_assigned: @modules
  }
end

Shared::User.insert_all(@new_all_data)

# @belongs.each do |belong|
#   Shared::User.find(belong["taquilla_id"]).update(rifero_ids: belong["riferos"])
# end
