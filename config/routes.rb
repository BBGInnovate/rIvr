TestIvr::Application.routes.draw do
  use_doorkeeper

  root :to => "entries#index"
  resources :api do
    collection do
      post :feed
      get :feed
      post :mesasge
      get :message
      post :prompt
    end
  end
  resources :users
  resource :session, :only => [:new, :create, :destroy]
  match 'signup' => 'users#new', :as => :signup
  match 'register' => 'users#create', :as => :register
  match 'login' => 'sessions#new', :as => :login
  match 'logout' => 'sessions#destroy', :as => :logout
  match '/activate/:activation_code' => 'users#activate', :as => :activate, :activation_code => nil
  match 'login' => 'sessions#new', :as => :login
  match 'logout' => 'sessions#destroy', :as => :logout
  match 'signup' => 'users#new', :as => :signup
  match 'activate/:activation_code' => 'users#activate', :as => :activate, :activation_code => nil

  resources :actions do
      as_routes
  end
  resources :branches do
      as_routes
  end
  resources :configure do
      as_routes
  end 
  resources :messages do
      as_routes
  end
  resources :pages do
      as_routes
  end
  
  resources :prompts do
      as_routes
  end
    
  resources :users do
    as_routes
    member do
      put :suspend
      put :unsuspend
      delete :purge
    end
  end
  resources :entries do
    as_routes
    member do
      put :suspend
      put :unsuspend
      delete :purge
      get :play
    end
    collection do
      get :authorize
    end
  end

  resources :events do
    as_routes
    collection do
      get :authorize
    end
  end
  resources :options do
    as_routes
    collection do
      get :authorize
    end
  end
     
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end