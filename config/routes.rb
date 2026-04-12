Rails.application.routes.draw do
  resources :tasks
  resources :deadlines
  resources :case_events
  resources :legal_cases
  resources :clients
  resources :courts
  resources :districts, only: [] do
    resources :courts_lookup, only: :index
  end
  resources :districts
  resources :districts
  resources :legal_areas, only: [] do
    resources :process_types, only: :index
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.

  root "legal_cases#index"

  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
