Rails.application.routes.draw do
  devise_for :users, skip: :all

  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  namespace :api do
    namespace :v1 do
      resources :audit_logs, only: :index
      resources :cash_sessions, only: %i[index show] do
        post :open, on: :collection
        get :current, on: :collection
        patch :close, on: :member
      end
      resources :categories
      resources :financial_entries
      resources :ingredients
      resources :menus do
        get :current, on: :collection
      end
      resources :products
      resources :recipes
      resources :sales, only: %i[index create show] do
        patch :cancel, on: :member
      end
      namespace :reports do
        get :overview
        get :statistics
        get :stock
        get :financial
      end
      namespace :analytics do
        get :abc
        get :profitability
        get :trends
        get :product_performance
        get :ingredient_consumption
      end
      resources :stock_movements, only: %i[index create show]
      resources :suppliers

      namespace :auth do
        post "login", to: "sessions#create"
        delete "logout", to: "sessions#destroy"
        get "me", to: "sessions#me"
        post "password", to: "passwords#create"
        patch "password", to: "passwords#update"
      end
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
