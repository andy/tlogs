class PublishController < ApplicationController
  before_filter :require_current_user, :require_owner, :filter_entry
  
  # protect_from_forgery :except => [:index]

  def index
  end
  
  def preview
    render :nothing => true and return unless request.post?

    @entry = nil

    if params[:entry][:id]
      @entry = Entry.find_by_id_and_user_id(params[:entry][:id], current_user.id)
      @entry.has_attachment = !@entry.attachments.empty? if @entry
    end
    
    if @entry.nil?
      type = params[:entry][:type] rescue 'TextEntry'
      @entry = type.constantize.new
      @entry.author = current_user
      @entry.has_attachment = false
    end
    @entry.attributes = params[:entry]
    @entry.valid?
    render :update do |page|
      page.call :clear_all_errors
      
      if @entry.errors.size > 0
        page.replace_html 'preview_holder', ''
        @entry.errors.each do |element, message|
          page.call :error_message_on, "entry_#{element}", message
        end
      else
        page.replace_html 'preview_holder', :partial => 'preview'
      end
    end
  end

  def text
    process_entry_request 'TextEntry'
  end
  
  def link
    process_entry_request 'LinkEntry'
  end
  
  def quote
    process_entry_request 'QuoteEntry'
  end
  
  def image
    process_entry_request 'ImageEntry'
  end
  
  def song
    # @new_record = true
    # @entry = SongEntry.new
    # render :action => 'limit_song' and return
    # 
    process_entry_request 'SongEntry'
  end
  
  def video
    process_entry_request 'VideoEntry'
  end
  
  def convo
    process_entry_request 'ConvoEntry'
  end
  
  def code
    process_entry_request 'CodeEntry'
  end
  
  def anonymous
    process_entry_request 'AnonymousEntry'
  end

  def mentions
    @mentions = User.find(current_user.all_friend_ids, :select => 'id, url, userpic_file_name, userpic_updated_at, userpic_meta', :include => :avatar)
    render :template => 'mentions/index'
  end
  
  private
    # страница для произвольной записи
    def process_entry_request(type)
      klass = type.constantize
      @new_record = true
      @attachment = nil
      
      @reason = current_user.can_create?(klass)
      if @reason && !params[:id]
        @entry = klass.new
        render :action => 'limit_exceeded'
        return
      end
      
      # запрашивается уже существующая запись
      if params[:id]
        @entry = Entry.find_by_id_and_user_id(params[:id], current_user.id)
        @entry = nil if @entry && @entry.class.to_s != type

        if @entry.nil?
          redirect_to user_url(current_user, publish_path(:id => nil))
          return
        end
        
        # set this virtual attribute
        @entry.has_attachment = !@entry.attachments.empty?
      end

      if request.post?
        if @entry.nil?
          @entry = klass.new
          @entry.has_attachment = params[:attachment] && !params[:attachment][:uploaded_data].blank?
          @entry.author = current_user
          @entry.visibility = @entry.is_anonymous? ? 'private' : current_user.tlog_settings.default_visibility
          Rails.logger.info "creating new entry of type #{type}" if @entry.new_record?
        end
        
        @new_record = @entry.new_record?
        # TODO: update only with data_part_[1..3] 
        @entry.attributes = params[:entry].slice(:data_part_1, :data_part_2, :data_part_3)
        if @entry.visibility != 'voteable' || @new_record
          @entry.visibility = params[:entry][:visibility] || current_user.tlog_settings.default_visibility
        end unless @entry.is_anonymous?
        
        # inherit commenting options, but always enable for anonymous entries
        @entry.comments_enabled = @entry.is_anonymous? ? true : current_user.tlog_settings.comments_enabled?
        
        # set tag lists
        @entry.metadata ||= {}
        @entry.nsfw     = params[:entry][:nsfw].to_i rescue false
        @entry.tag_list = params[:entry][:tag_list]

        Entry.transaction do
          @new_record = @entry.new_record?
          @entry.save!
        
          if @entry.can_have_attachments? && @entry.has_attachment && @new_record
            @attachment = @entry.attachment_class.new params[:attachment]
            Rails.logger.info "adding attachment to entry id = #{@entry.id}"
            @attachment.entry = @entry
            @attachment.user = current_user
            @attachment.save!
          end

          @entry.make_voteable(true) if @entry.is_voteable?
        end
        if in_bookmarklet?
          redirect_to service_url(bookmarklet_path(:action => 'published'))
        elsif in_flash?
          render :text => tlog_url_for_entry(@entry)
        else
          redirect_to tlog_url_for_entry(@entry)
        end
        return
      else
        @entry ||= in_bookmarklet? ? klass.new_from_bm(params[:bm]) : klass.new
        @new_record = @entry.new_record?
        if in_bookmarklet?
          @entry.tag_list.add(params[:bm][:tags]) if params[:bm][:tags]
          visibility = params[:bm][:vis] if params[:bm][:vis]
          @entry.visibility = visibility || current_user.tlog_settings.default_visibility
        else
          # выставляем флаг видимости в значение по-умолчанию, сама модель этого сделать не может
          if @new_record
            @entry.visibility = current_user.tlog_settings.default_visibility
            @entry.visibility = 'public' unless current_user.is_allowed_visibility?(@entry.visibility)
          end
        end
        @attachment = Attachment.new
      end

      render :action => 'edit'
    rescue ActiveRecord::RecordInvalid => ex
      # HoptoadNotifier.notify(
      #   :error_class    => ex.class.name,
      #   :error_message  => "#{ex.class.name}: #{ex.message}",
      #   :backtrace      => ex.backtrace,
      #   :parameters     => params
      # )

      @attachment.valid? unless @attachment.nil? # force error checking
      render :action => 'edit'
    rescue Exception => ex
      HoptoadNotifier.notify(
        :error_class    => ex.class.name,
        :error_message  => "#{ex.class.name}: #{ex.message}",
        :backtrace      => ex.backtrace,
        :parameters     => params
      )
      
      raise ex if Rails.env.development?

      @attachment.valid? unless @attachment.nil?
      render :action => 'edit'
    end

    # проверяем что entry.type имеет допустимое значение
    def filter_entry
      return true unless params[:entry] && params[:entry][:type]
      return true if %w(TextEntry LinkEntry QuoteEntry ImageEntry SongEntry VideoEntry ConvoEntry CodeEntry AnonymousEntry).include?(params[:entry][:type])
      render :text => 'oops, bad entry type', :status => 403
      false
    end
    
    def in_bookmarklet?
      !!params[:bm]
    end
    helper_method :in_bookmarklet?
    
    def in_flash?
      !!params[:fl]
    end
end
