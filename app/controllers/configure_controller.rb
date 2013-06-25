class ConfigureController < ApplicationController
  #  doorkeeper_for :create
  skip_before_filter :verify_authenticity_token, :only => [:create]
  before_filter :authorize, :only=>[:index]

  active_scaffold :configure do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
    config.actions.exclude :show
    config.columns = [:branch,:feed_limit, :feed_url,
      :feed_source]
    config.columns[:feed_source].form_ui = :select
    config.columns[:feed_limit].description = "feed limit"
    config.columns[:feed_source].description = "dropbox or static_rss"
  
    config.action_links.add 'branches',
      :label => 'Branch',
      :type => :collection,
      :controller=>"/branches",
      :action=>"index",
      :page => true,
      :inline => false
      
    config.action_links.add 'prompts',
              :label => 'Voice Forum',
              :type => :collection,
              :controller=>"/prompts",
              :action=>"index",
              :page => true,
              :inline => false
  end
  #  def action_links_order
  #      links = active_scaffold_config.action_links
  #      links << ActiveScaffold::DataStructures::ActionLink.new('destroy',
  #      :label =>:delete, :type => :member, :confirm => :are_you_sure_to_delete,
  #       :method => :delete, :crud_type => :delete,
  #       :position => false, :parameters =>
  #       {:destroy_action => true, :branch=>''})
  #  end

  # override active_scaffold-3.3.0/lib/active_scaffold/actions/create.rb
  def do_create(options = {})
    attr =  params[:record]
    begin
      active_scaffold_config.model.transaction do
        Option.create :branch=>attr[:branch], :name=>"feed_limit", :value=>attr[:feed_limit]
        Option.create :branch=>attr[:branch], :name=>"feed_source", :value=>attr[:feed_source]
        Option.create :branch=>attr[:branch], :name=>"feed_url", :value=>attr[:feed_url]
      end
    rescue ActiveRecord::ActiveRecordError => ex
      flash[:error] = ex.message
      self.successful = false
    end
  end

  # override active_scaffold-3.3.0/lib/active_scaffold/actions/update.rb
  def update
    do_update
    redirect_to configure_index_url
  end

  def update_save(options = {})
    attr = params[:record]
    begin
      Configure.transaction do
        @record = Configure.find_me(attr[:branch], 'feed_limit')
        @record.value = attr[:feed_limit]
        @record1 = Configure.find_me(attr[:branch], 'feed_source')
        @record1.value = attr[:feed_source]
        @record2 = Configure.find_me(attr[:branch], 'feed_url')
        @record2.value = attr[:feed_url]
        self.successful = @record.valid?
        if successful?
          @record.save!
          @record1.save!
          @record2.save!
        else
          # some associations such as habtm are saved before saved is called on parent object
          # we have to revert these changes if validation fails
          raise ActiveRecord::Rollback, "don't save habtm associations unless record is valid"
        end
      end
    rescue ActiveRecord::StaleObjectError
      @record.errors.add(:base, as_(:version_inconsistency))
      self.successful = false
    rescue ActiveRecord::RecordNotSaved
      @record.errors.add(:base, as_(:record_not_saved)) if @record.errors.empty?
      self.successful = false
    rescue ActiveRecord::ActiveRecordError => ex
      flash[:error] = ex.message
      self.successful = false
    end
  end

  def do_destroy
    # params[:branch_id] is set in def render_action_link
    # of configure_helper.rb
    Configure.where("branch='#{params[:branch_id]}'").all.each do |record|
      begin
        self.successful = record.destroy
      rescue Exception => ex
        flash[:warning] = as_(:cant_destroy_record, :record => @record.to_label)
        self.successful = false
        logger.debug ex.message
        logger.debug ex.backtrace.join("\n")
      end
    end
  end

end