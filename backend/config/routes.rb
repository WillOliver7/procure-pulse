Rails.application.routes.draw do
  devise_for :users
  mount ActionCable.server => "/cable"

  # Defines the root path route ("/")
  # root "posts#index"

  devise_scope :user do
    post "api/v1/signup",
         to: "api/v1/registrations#create"

    post "api/v1/login",
         to: "api/v1/sessions#create"

    delete "api/v1/logout",
           to: "api/v1/sessions#destroy"
  end

  namespace :api do
    namespace :v1 do
      resources :purchase_orders, only: [:index, :show]
      get "analytics", to: "analytics#show"

      get "me", to: "users#show"

      resources :analysis_runs, only: [:create, :show]
    end
  end
end
