# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130621143837) do

  create_table "actions", :force => true do |t|
    t.string   "branch",     :limit => 50
    t.string   "name",       :limit => 50
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  create_table "branches", :force => true do |t|
    t.string   "name",        :limit => 50
    t.integer  "country_id"
    t.string   "region",      :limit => 100
    t.string   "description"
    t.boolean  "is_active",                  :default => false
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
  end

  add_index "branches", ["name"], :name => "index_branches_on_name", :unique => true

  create_table "countries", :force => true do |t|
    t.string "code", :limit => 2
    t.string "name"
  end

  create_table "dropbox_sessions", :force => true do |t|
    t.string   "token",      :null => false
    t.string   "secret",     :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "entries", :force => true do |t|
    t.string   "file_location"
    t.string   "public_url"
    t.integer  "size"
    t.integer  "length"
    t.string   "mime_type",                   :limit => 40
    t.string   "dropbox_dir"
    t.string   "dropbox_file"
    t.string   "phone_number",                :limit => 50
    t.string   "branch",                      :limit => 50
    t.integer  "you_tube_upload_status"
    t.boolean  "downloaded_from_sky_drive"
    t.boolean  "is_private"
    t.string   "you_tube_video_id",           :limit => 400
    t.integer  "cloud_storage_upload_status"
    t.integer  "facebook_upload_status"
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
    t.string   "option",                      :limit => 20
  end

  add_index "entries", ["branch", "dropbox_file"], :name => "index_entries_on_branch_and_dropbox_file", :unique => true

  create_table "events", :force => true do |t|
    t.string   "branch",     :limit => 50
    t.string   "session_id", :limit => 40
    t.string   "caller_id",  :limit => 50
    t.integer  "page_id"
    t.integer  "action_id"
    t.string   "identifier"
    t.integer  "option"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  add_index "events", ["caller_id"], :name => "index_events_on_caller_id"

  create_table "messages", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "oauth_access_grants", :force => true do |t|
    t.integer  "resource_owner_id", :null => false
    t.integer  "application_id",    :null => false
    t.string   "token",             :null => false
    t.integer  "expires_in",        :null => false
    t.string   "redirect_uri",      :null => false
    t.datetime "created_at",        :null => false
    t.datetime "revoked_at"
    t.string   "scopes"
  end

  add_index "oauth_access_grants", ["token"], :name => "index_oauth_access_grants_on_token", :unique => true

  create_table "oauth_access_tokens", :force => true do |t|
    t.integer  "resource_owner_id"
    t.integer  "application_id",    :null => false
    t.string   "token",             :null => false
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        :null => false
    t.string   "scopes"
  end

  add_index "oauth_access_tokens", ["refresh_token"], :name => "index_oauth_access_tokens_on_refresh_token", :unique => true
  add_index "oauth_access_tokens", ["resource_owner_id"], :name => "index_oauth_access_tokens_on_resource_owner_id"
  add_index "oauth_access_tokens", ["token"], :name => "index_oauth_access_tokens_on_token", :unique => true

  create_table "oauth_applications", :force => true do |t|
    t.string   "name",         :null => false
    t.string   "uid",          :null => false
    t.string   "secret",       :null => false
    t.string   "redirect_uri", :null => false
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "oauth_applications", ["uid"], :name => "index_oauth_applications_on_uid", :unique => true

  create_table "options", :force => true do |t|
    t.string   "branch",      :limit => 50
    t.string   "name",        :limit => 40
    t.string   "value"
    t.string   "description"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "options", ["branch"], :name => "index_options_on_branch"

  create_table "pages", :force => true do |t|
    t.string   "name",       :limit => 50
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  create_table "prompts", :force => true do |t|
    t.string   "branch",       :limit => 50
    t.string   "name"
    t.string   "sound_file"
    t.string   "content_type"
    t.string   "url"
    t.string   "description"
    t.boolean  "is_active",                  :default => true
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
  end

  add_index "prompts", ["branch"], :name => "index_prompts_on_branch"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 40
    t.string   "name",                      :limit => 100, :default => ""
    t.string   "email",                     :limit => 100
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.string   "state",                                    :default => "passive"
    t.datetime "deleted_at"
    t.string   "role"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

end
