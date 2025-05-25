# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'

# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do 
  post '/login', to: 'authentication#login'
  post '/refresh', to: 'authentication#refresh'
  post '/social/login', to: 'authentication#social_login'

  post 'auth/profile', to: 'authentication#profile'
  post 'auth/connect/login', to: 'authentication#integrator_login'
  post 'auth/verify_trz_access', to: 'authentication#verify_trz_access'
 
  namespace :social do
    get 'order/search'
    get 'order/purchase'
    get 'stats/index'
    get 'details/index'
    get 'influencers/index'
    post 'login', to: 'authentication#social_login'
    post 'auth/refresh', to: 'authentication#social_refresh'
    
    resources :networks
    resources :lotteries do 
      collection do
        get :available
      end
      member do
        put :toggle_status
      end
    end
    resources :raffles do
      put 'add_ad', on: :collection
      get 'actives', on: :collection
      get 'live', on: :collection
    end
    resources :stats do
      get 'specific', on: :collection
    end
    resources :clients do 
      get 'phone', on: :collection
      put 'change_address', on: :collection
    end
    resources :payment_methods do
      post 'accept', on: :member
      post 'reject', on: :member
      get 'history', on: :collection
    end
    resources :influencers do
      get 'search', on: :collection
      get 'all', on: :collection
    end
    resources :details do
      post 'admin', on: :collection
    end
    resources :payment_options
  end

  namespace :x100 do
    resources :orders, only: [:index] do
      get 'bill', on: :collection
    end
    resources :raffles do
      get 'progressives', on: :collection
      get 'progress', on: :collection
    end
    resources :clients do
      get 'dni', on: :collection
      post 'integrator', on: :collection
    end
    resources :tickets do
      post 'sell', on: :collection
      post 'apart', on: :collection
      post 'apart_integrator', on: :collection
      post 'buy_infinite', on: :collection
      post 'sell_series', on: :collection
      post 'clear', on: :collection
      post 'refresh', on: :collection
      post 'available', on: :collection
      post 'refund', on: :collection
      post 'combo', on: :collection
    end
    resources :draws do
      get 'raffle_stats', on: :collection
    end
    resources :invoices do
      post 'pay', on: :collection
    end
  end

  namespace :rifamax do
    resources :agencies
    resources :raffles do 
      get 'newest', on: :collection
      get 'initialized', on: :collection
      get 'to_close', on: :collection
      get 'close_day_info', on: :collection
      get 'close_day', on: :collection
      get 'report', on: :collection
      get 'is_blocked', on: :collection
      post 'pay', on: :collection
      post 'triple_pay', on: :collection
      post 'unpay', on: :collection
      post 'refund', on: :collection
      post 'repeat', on: :collection
      post 'send_app', on: :collection
      post 'seller_create', on: :collection
    end
    resources :tickets do 
      get 'get_tickets', on: :collection
      post 'sell_all', on: :collection
      put 'sell_some', on: :collection
    end
  end

  namespace :fifty do
    resources :stadia
    resources :locations
  end

  namespace :shared do
    resources :structures
    resources :currencies
    resources :sprites
    resources :lobby
    resources :exchanges
    resources :users do
      post 'sign_up', on: :collection
      post 'avatar', on: :collection
      post 'toggle_active', on: :collection
      put 'new_terms', on: :collection
      put 'welcome', on: :collection
      put 'update_influencer', on: :collection
      put 'change_password', on: :collection
      get 'profile', on: :collection
      get 'rafflers', on: :collection
    end
  end

  namespace :dev do
    resources :feature_flags do 
      post 'search', on: :collection
    end
    resources :tools do
      get 'server', on: :collection
      post 'restart_server', on: :collection
    end
  end

  mount ActionCable.server => '/cable'
  mount Sidekiq::Web => '/sidekiq'
end
# rubocop:enable Metrics/BlockLength
