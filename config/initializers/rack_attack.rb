# frozen_string_literal: true

puts "Rack::Attack configuration loaded"

Rack::Attack.safelist_ip("45.175.213.98/24")
Rack::Attack.safelist_ip("200.74.203.91/24")
Rack::Attack.safelist_ip("204.199.249.3/24")