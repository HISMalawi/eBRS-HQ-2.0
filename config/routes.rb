Rails.application.routes.draw do
  get 'task/:task_id'  => 'person#task'

  get '/sites' => 'location#sites'

  get 'location/:location_tag' => 'location#tag'

  get 'get_location/:location_tag_id/:record_limit' => 'location#get_location'

  get '/tasks' => 'person#tasks'

  get 'users/index'

  root 'person#index'

  get '/show_person/:person_id' => 'person#show'

  get 'user/:user_id' => 'users#show'

  get '/users' => 'users#view'

  get 'users/new'

  get "block/:user_id" => "users#block"

  get "unblock/:user_id" => "users#unblock"

  get "/void_user/:user_id" => "users#void_user"

  get "/block_user/:user_id" => "users#block_user"

  get '/query_users' =>"users#query_users"

  get "/view" => "person#view"

  get "/view_users" => "users#view"

  get 'users/my_account'

  post 'users/update_password'

  get 'users/change_password'

  get "/query" => "person#query"

  get "query_sync" =>"person#query_sync"

  get '/deleted_users' => 'users#deleted'

  get 'recover/:user_id' => 'users#recover'

  get "/logout" => "logins#logout"

  get "/change_password" => "users#change_password"

  get "/login" => "logins#login"

  get "/search_by_fullname/:id" => "person#search_by_fullname"

  get "/search_by_name" => "person#search_by_name"

  get "/set_context/:id" => "logins#set_context"

  get "/edit_account" => "users#edit_account"

  get "edit/:user_id" => "users#edit"

  get "change_password/:user_id" => "users#change_password"

  get "update_password/:user_id" => "users#update_password"

  post "update/:user_id" => "users#update"

  post '/create_user' => 'users#create'

  get 'person/index'

  get 'person/show'

  get 'person/new'

  post 'person/create'

  post '/application/get_registration_type'

  get 'records/:status' => 'person#records'

  ############################### Main Tasks routes #####################################
  get "/person/manage_cases"
  get "/person/view"

  ########################### (create record form) routes
  get '/get_last_names' => 'person#get_names', :defaults => {last_name: 'last_name'}
  get '/get_first_names' => 'person#get_names', :defaults => {first_name: 'first_name'}
  get '/search_by_nationality' => 'person#get_nationality'
  get '/search_by_country' => 'person#get_country'
  get '/search_by_district' => 'person#get_district'
  get '/search_by_ta' => 'person#get_ta'
  get '/search_by_village' => 'person#get_village'
  get '/search_by_hospital' => 'person#get_hospital'
  ########################### (create record form) routes end










  resources :person

  resources :users

  resource :login do
    collection do
      get :logout
    end
  end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
