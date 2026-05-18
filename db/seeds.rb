# frozen_string_literal: true

# db/seeds.rb

module_to_run = 'all'

if module_to_run.blank?
  puts "Please provide the module name using the MODULE environment variable, e.g. 'rifamax' \n"
  puts "Available modules ['shared', 'rifamax', 'X100', 'fifty', 'all', 'old']"
  exit
end

if module_to_run === 'all'
  puts 'Running all migrations from all enviroments...'
  module_to_run = '*'
end

# Load the specific seed folder or file dynamically
seed_path = File.join(Rails.root, 'db', 'seeds', module_to_run)
seed_files = Dir[File.join(seed_path, '*.rb')].sort

if seed_files.empty?
  puts "No seed files found for module '#{module_to_run}'"
  exit
end

seed_files.each do |seed_file|
  load seed_file
end
