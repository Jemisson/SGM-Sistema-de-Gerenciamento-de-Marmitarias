Rails.application.routes.draw do
  devise_for :users, skip: :all

  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  namespace :api do
    namespace :v1 do
      resources :audit_logs, only: :index
      resources :categories
      resources :ingredients
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
