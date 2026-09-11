Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "analytics", to: "analytics#show"
      get "meta", to: "meta#index"
      get "exports/employees", to: "exports#employees"

      resources :employees, only: [ :index, :show, :create, :update, :destroy ] do
        resources :salaries, only: [ :index, :create ]
      end
    end
  end

  # Serves public/index.html (the React SPA) for the root path.
  root to: ->(_env) { [ 200, { "Content-Type" => "text/html" }, [ File.read(Rails.public_path.join("index.html")) ] ] }
end