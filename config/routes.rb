Rails.application.routes.draw do
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "/painel", to: "dashboard#index"
  patch "/painel/processos/:id/responsavel", to: "dashboard#quick_update_case_responsible", as: :quick_update_case_responsible
  patch "/painel/processos/:id/providencia", to: "dashboard#quick_update_case_next_action", as: :quick_update_case_next_action
  patch "/painel/prazos/:id/justificativa", to: "dashboard#quick_update_deadline_reason", as: :quick_update_deadline_reason
  patch "/painel/tarefas/:id/responsavel", to: "dashboard#quick_update_task_responsible", as: :quick_update_task_responsible
  get "/calendario_interno", to: "internal_calendars#index", as: :internal_calendar
  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"
  get "/logout", to: "sessions#destroy"
  resource :unit_session, only: %i[new create]
  resource :office_setting, only: %i[show edit update] do
    resources :users, controller: "office_users", except: :show
  end

  resources :tasks
  resources :deadlines do
    member do
      patch :quick_update
    end
  end
  resources :deadline_settings, except: :show
  resources :case_events
  resources :movement_types
  resources :movement_templates
  resources :process_movements

  resources :legal_cases do
    collection do
      get :daily_closure
    end

    member do
      get :print
      get :pdf
      get :google_calendar
    end

    resources :process_exams, only: [ :new, :create ]
  end

  get "calendar_feeds/legal_case/:token.ics", to: "calendar_feeds#legal_case", as: :legal_case_calendar_feed
  get "calendar_feeds/legal_case", to: "calendar_feeds#legal_case"

  resources :process_exams, only: [ :edit, :update, :destroy ]
  resources :clients do
    collection do
      post :quick_create
    end
  end
  resources :courts
  resources :units
  resources :districts, only: [] do
    resources :courts_lookup, only: :index
  end
  resources :districts

  resources :legal_areas, only: [] do
    resources :process_types, only: :index
  end

  root "dashboard#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
