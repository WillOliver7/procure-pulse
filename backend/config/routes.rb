Rails.application.routes.draw do
  mount ActionCable.server => "/cable"

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      resources :purchase_orders, only: [:index, :show]
      get "analytics", to: "analytics#show"

      resources :analysis_runs, only: [:create, :show]
    end
  end
end
