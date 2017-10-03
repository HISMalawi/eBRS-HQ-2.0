Rails.application.routes.draw do

  ####################### reports ################################

  ### Printed certofocates
  get '/printed_certificates' => 'report#printed_certificates'
  get 'get_printed_certificates/:location_id/:start_date/:end_date' => 'report#get_printed_certificates'


  get '/reported_births' => 'report#reported_births'
  get 'get_reported_births/:location_id/:start_date/:end_date' => 'report#get_reported_births'
  
  get '/approved_at_hq' => 'report#approved_at_hq'
  get 'get_approved_at_hq/:location_id/:start_date/:end_date' => 'report#get_approved_at_hq'

  get '/voided_records' => 'report#voided_records'
  get 'get_voided_records/:start_date/:end_date' => 'report#get_voided_records'

  get '/registered_births' => 'report#registered_births'
  get 'get_registered_births/:location_id/:start_date/:end_date' => 'report#get_registered_births'

  get '/user_audit_trail' => 'report#user_audit_trail'
  get 'get_user_audit_trail' => 'report#get_user_audit_trail'

  get "/report/birth_reports"
  ####################### reports end ################################

  get 'global_property/paper'

  get 'global_property/signature'

  get 'global_property/set_paper'

  get 'global_property/set_signature'

  get 'global_property/update_paper'

  get 'global_property/update_signature'

  get 'task/:task_id'  => 'person#task'

  get '/sites' => 'location#sites'

  get 'location/:location_tag' => 'location#tag'

  get 'get_location/:location_tag_id/:record_limit' => 'location#get_location'

  get 'get_tas/:district_id' => 'location#get_traditional_authorities'
  
  get 'get_villages/:ta_id' => 'location#get_villages'

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

  get "person/duplicates_menu"

  get "person/duplicate"

  get "/duplicate_processing/:id" =>"person#duplicate_processing"

  post 'person/create'

  post '/application/get_registration_type'

  get 'records/:status' => 'person#records'

  ############################### Main Tasks routes #####################################
  get "/person/manage_cases"
  get "/person/rejected_cases"
  get "/person/special_cases"
  get "/person/print_out"
  get "/person/amendments"
  get "/person/ammend_case"
  get "/person/dispatch_certificates"
  get "/person/dispatch_list"
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
  get 'search/:identifier_type' => 'person#search'
  get 'search_by_identifier/:identifier_type/:identifier' => 'person#search_by_identifier'
  ########################### (create record form) routes end

  get '/get_comments' => 'person#get_comments'
  get '/ajax_status_change' => 'person#ajax_status_change'
  post '/multiple_status_change' => 'person#multiple_status_change'

  get '/print_preview' => 'person#print_preview'
  post '/print_preview' => 'person#print_preview'
  get '/birth_certificate' => 'person#birth_certificate'
  get '/print' => 'person#print'
  post '/print_dispatched_certs' => 'person#print_dispatched_certs'
  get '/paper' => 'global_property#paper'
  get '/signature' => 'global_property#signature'

  get '/search' => "search#general_search"
  get '/search_cases' => "search#search_cases"
  post '/search_cases' => "search#search_cases"
  get '/person/map_main'
  get '/person/get_district_stats'
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
