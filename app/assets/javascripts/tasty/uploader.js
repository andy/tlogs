
var Uploader = {
  // swf upload options
  swfu: null,
  swfu_options: {},
  
  enabled: false,
  
  // elements on page
  swfu_elm: null,
  progress_elm: null,
  
  init: function() {
    jQuery('#submit_button').click(function() {
      if(Uploader.enabled) {
        Uploader.upload();
        return false;
      } else {
        return true;
      }
    });
  },
  
  enable: function() {
    this.enabled = true;

    // disable preview
    Button.disable('#generate_preview')

    // swf upload options
    this.swfu_options = {
  		upload_url: jQuery("#entry_edit_form").attr("action"),
  		flash_url: '/swf/swfupload.swf',

      file_upload_limit: 1,
      file_queue_limit: 1,
  		file_size_limit: "4 MB",
  		
  		requeue_on_error: true,

  		file_post_name: 'attachment[uploaded_data]',
  		file_types : "*.jpg;*.gif;*.png;*.bmp",
      file_types_description: "Image Files",
      
      debug: false,

  		button_placeholder_id: 'attachment_uploaded_data',
  		button_text: "",
  		button_image_url: "/images/upload.png",
  		button_width: 125,
  		button_height: 35,
  		button_action: SWFUpload.BUTTON_ACTION.SELECT_FILES,
  		button_cursor: SWFUpload.CURSOR.HAND,
    	button_window_mode: SWFUpload.WINDOW_MODE.TRANSPARENT,
    	
    	file_queued_handler: Uploader.fileQueued.bind(this),
    	upload_start_handler: Uploader.uploadStart.bind(this),
    	upload_progress_handler: Uploader.uploadProgress.bind(this),
    	upload_error_handler: Uploader.uploadError.bind(this),
    	upload_success_handler: Uploader.uploadSuccess.bind(this),
    	upload_complete_handler: Uploader.uploadComplete.bind(this)
    }
    
    this.swfu = new SWFUpload(this.swfu_options);
    
    this.swfu_elm = jQuery('#' + this.swfu.movieName);
    this.swfu_elm.after('<div style="display: none;"><div></div></div>');
    this.progress_elm = this.swfu_elm.next();
  },
  
  update_params: function() {
    if(jQuery('#entry_id').val() != undefined)
      this.swfu.addPostParam("entry[id]", jQuery("#entry_id").val());
    this.swfu.addPostParam("entry[type]", jQuery("#entry_type").val());
    this.swfu.addPostParam("entry[data_part_3]", jQuery("#entry_data_part_3").val());
    this.swfu.addPostParam("entry[visibility]", jQuery("#entry_visibility").val());
    this.swfu.addPostParam("entry[tag_list]", jQuery("#entry_tag_list").val());
		this.swfu.addPostParam("fl", "1");
    this.swfu.addPostParam("s", _user.sid)  
  },
  
  upload: function() {
    this.update_params();
    this.swfu.startUpload();      
  },
  
  disable: function() {
    this.enabled = false;

    this.swfu.destroy();
    this.swfu = null;
    
    // enable preview
    Button.enable('#generate_preview');      
  },
  
  // The fileQueued event is fired for each file that is queued after the File Selection Dialog window is closed.
  fileQueued: function(file) {
		jQuery('.attachment_file_info').text(file.name);
  },
  
  // uploadStart is called immediately before the file is uploaded. This event provides an opportunity to perform any last minute validation, add post params or do any other work before the file is uploaded.
  // 
  // The upload can be cancelled by returning 'false' from uploadStart. If you return 'true' or do not return any value then the upload proceeds. Returning 'false' will cause an uploadError event to fired.
  uploadStart: function(file) {
    // this.swfu_elm.hide();
    
    p = this.progress_elm;
    
    p.css({
      'width': '510px',
      'height': '30px',
      'border': '1px solid black',
      'background-color': 'white'
    });
    
    p.children().eq(0).css({
      'width': '0%',
      'height': '30px',
      'background-color': 'rgb(247, 243, 209)'
    });
    
    p.show();
    
    return true;
  },
  
  // The uploadProgress event is fired periodically by the Flash Control. This event is useful for providing UI updates on the page.
  // 
  // Note: The Linux Flash Player fires a single uploadProgress event after the entire file has been uploaded. This is a bug in the Linux Flash Player that we cannot work around.
  uploadProgress: function(file, complete, total) {
    this.progress_elm.children().eq(0).css({
      'width': file.percentUploaded + '%'
    });
    
    return true;
  },
  
  // The uploadError event is fired any time an upload is interrupted or does not complete successfully. The error code parameter indicates the type of error that occurred. The error code parameter specifies a constant in SWFUpload.UPLOAD_ERROR.
  // 
  // Stopping, Cancelling or returning 'false' from uploadStart will cause uploadError to fire. Upload error will not fire for files that are cancelled but still waiting in the queue.    
  uploadError: function(file, code, message) {
    // console.log('upload error ' + code + ': ' + message);
  },


  // uploadSuccess is fired when the entire upload has been transmitted and the server returns a HTTP 200 status code. Any data outputted by the server is available in the server data parameter.
  // 
  // Due to some bugs in the Flash Player the server response may not be acknowledged and no uploadSuccess event is fired by Flash. In this case the assume_success_timeout setting is checked to see if enough time has passed to fire uploadSuccess anyway. In this case the received response parameter will be false.
  // 
  // The http_success setting allows uploadSuccess to be fired for HTTP status codes other than 200. In this case no server data is available from the Flash Player.
  // 
  // At this point the upload is not yet complete. Another upload cannot be started from uploadSuccess.    
  uploadSuccess: function(file, data, response) {
		window.location = data;
  },
  
  // uploadComplete is always fired at the end of an upload cycle (after uploadError or uploadSuccess). At this point the upload is complete and another upload can be started.
  // 
  // If you want the next upload to start automatically this is a good place to call this.uploadStart(). Use caution when calling uploadStart inside the uploadComplete event if you also have code that cancels all the uploads in a queue.    
  uploadComplete: function(file) {
    this.progress_elm.children().eq(0).css({ 'width': '100%' });

    return true;
  }
};
