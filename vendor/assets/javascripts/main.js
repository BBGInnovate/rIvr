var Modal = {
	modalID:  null,
		css : function(height) {
			// height is the modal's child height
			height = height || 360;
			var newRule = ".helpPopUp {background: none repeat scroll 0 0 #FFFFFF;border: 1px solid #CFE8F5;";
			newRule = newRule +"border-radius: 11px 11px 11px 11px;padding: 20px;position: absolute;";
			newRule = newRule +"text-align: center; min-height: " + (height) + "px;display: none}";
			$(Modal.modalID + " style").append(newRule);
		},
		open : function (modal_id, anchor_id, height) {
			height = height || 360;
	   // modal_id must have a child <style></style> for Modal.css to work
	   // Modal_id first child must define a width to Modal_id to figure out 
	   // it's width
      // modal_id modal window placeholder id
      // anchor_id element id, click which trigers the modal window
      Modal.modalID = "#" + modal_id;
      
      Modal.css(height);
      var anchorID = "#" + anchor_id;
      // get how many pixels that the calling link is from the top of the page -- to be used later.
      var anchorOffset = Math.floor(jQuery(anchorID).offset().top);
      var mymodal = $(Modal.modalID);
      
      // get the modal window's height + padding top + padding bottom
      var modalHeight = Math.floor(mymodal.height());
      // the modal's width is based off width of the site area, rather than being set off of another value
      // sitewidth - modal padding left - modal padding right - 20 ... dropping any hanging decimals
      // var modalWidth = 506;
      // var c = mymodal.children('div')[0]
      var child = mymodal.children('div')[0];
      // we have pre-define the width of the content div 
      // which is inserted into the modal window
      var modalWidth = Math.floor($(child).width());
      // set the modal's width, to overwrite any CSS sizes

      mymodal.css('width', modalWidth);
      //now that the modal width is based off of the sitewidth, instead of other numbers, re-evaluate to get the width + padding (similiar to the height)
      // modalWidth = Math.floor(mymodal.width());
      var windowWidth = $(window).width();
      // find the new left for the modal window
      var newLeft = Math.floor((windowWidth - modalWidth) / 2);
      // set the new left
      mymodal.css('left', newLeft);
      // instead of using the top of the screen to determine where the modal goes, we're using the offset position of the link that calls the function
      // for the user to see the pop-up they need to click the link
      // so to ensure that the user sees the modal it will appear above the link.
      // This is taking the offset position of the link - half the modal window's height.  So in theory, the modal window's center will be right above the calling link.
      var newTop = anchorOffset - Math.floor(modalHeight / 2);
      // set the new top
      mymodal.css('top', newTop);
      // now set the height of the content div inserted into 
      // the modal
      
      // $(child).css('height', modalHeight)
      $(child).css({
      	   'postion': 'relative',
         'min-height': modalHeight,
         'background-color': '#CCC',
         'border': '1px solid #CCC'
      });

      // fade the modal window in
      mymodal.fadeIn();
    }
}
var datepickerConfigure = {
  init : function() {
    $('#start_date, #end_date').datetimepicker({
      controlType: 'select',
      dateFormat: "yy-mm-dd",
      timeFormat: 'hh:mm tt',
      buttonImage: '/assets/calendar.gif'
    });
    $("#Astart_date, #Aend_date").datepicker({
      	dateFormat: "yy-mm-dd",
      changeMonth: true,
      changeYear: true,
      minDate: new Date(2013, 0, 1),
      maxDate: '+1Y',
      showOn: 'both',
      buttonImageOnly: true,
      buttonImage: '/assets/calendar.gif'
    });
  }, 
}
var autoRefreshHeader = {
    init : function() {
      var header_refresh = setInterval(
        function(){
           jQuery.get("/home/header",{ajax: 1}, autoRefreshHeader.update, 'html');
        }, 30000); // refresh every 30000 milliseconds
    },
    update : function(data) {
      var obj = jQuery.parseJSON(data);
      $('#alerts').html(obj.alerts + ' Alerts');
      $('#calls').html(obj.calls + ' Number of Calls');
      $('#messages').html(obj.messages+' Messages');
      $('.activity').html(obj.activity);
    },
}
var homePage = {
    anchorId : null,
    init : function(content_id) {
      homePage.anchorId = content_id;
      jQuery(".left-nav-bar").hover(function(e) {
      	  
      });
      jQuery("body").on('click', ".left-nav-bar", function(e) {
        // var name = this.id;
        // var url = '/'+name;
        var klass = $(this).attr("data-klass") || '';
        var url = $(this).attr("data-url");
        var branch_id = $(this).attr("data-id") || '';
        if (klass.length>0 && branch_id.length>0)
        	  url = url+"?klass="+klass + "&branch_id="+branch_id;
        else if (branch_id.length>0) 
        		url = url + "?branch_id="+branch_id;
        else if (klass.length>0)
        	  url = url+"?klass="+klass;
        
        window.location = url
        // var data = {ajax: 1};
        // jQuery.get(url, data, homePage.update, 'html');
        return false
      });
    },
    update : function(data) {
      $('#'+homePage.anchorId).html(data);
    }
}
var report = {
    init : function() {
    	  $(".search-results-table").tablesorter({ 
          // pass the headers argument and assing a object 
          headers: { 
              // assign the first column (we start counting zero) 
              0: { 
                  // disable it by setting the property sorter to false 
                  sorter: false 
              }, 
          } 
      }); 
      	$("body").on('click', "#report-cancel", function(e) {
      		$('#branch_id option').attr('selected', false);
      		$('#start_date').val('');
      		$('#end_date').val('');
    	  });
      $("body").on('click', "#report-submit", function(e) {
        var br = $('#branch_id').val();
        if (br == null) {
         // $('#error').html("Must select a Branch");
         // return false;
          $('#branch_id option').attr('selected', true);
          br = $('#branch_id').val();
        }
        var start_date = $('#start_date').val();
        var end_date = $('#end_date').val();
        $('#error').html('');
        
        if (start_date.length==0 || end_date.length==0 ) {
          $('#error').html("Must select a Start Date and End Date");
          return false;
        }
        var fmt = $("input:radio[name='format']:checked").val();
        var data = {ajax: 1, "branch_id[]": br, start_date: start_date,
            end_date: end_date, format: fmt};
        var url = "/analytics/"
        if (fmt=='csv') {
          $('#post-report').submit();   
        } else {
          $.post(url, data, report.update, 'html');
        }
        return false
      });
    },
    update : function(data) {
      $('#report-results').show().html(data);
    }
}
var search = {
    init : function() {
      jQuery("body").on('click', "input[name='search']", function(e) {
        var op = jQuery('input:radio[name="branch[search]"]:checked').val();
        var term = jQuery('input[name="term"]').val();
        var data = {ajax: 1, search_for: op, term: term};
        var url = "/healthcheck/search"
        jQuery.get(url, data, search.update, 'html');
        return false
      });
      jQuery("body").on('change', "#remote-desktop-select", function(e) {
        var branch_id = this.value;
        var data = {ajax: 1, branch_id: branch_id};
        var url = "/healthcheck/branch"
        jQuery.get(url, data,search.remoteDesktop, 'html');
        return false
      });
    },
    update : function(data) {
      $('#search-results-id').html(data);
    },
    remoteDesktop : function(data) {
      var radios = $("input[name='remote-desktop']");
      if (data.length>6) {
        $('#ip-address').text(data); 
        radios[0].checked = true;
      } else {
         $('#ip-address').text('');
         radios[1].checked = true;
      }
    }
}

var searchEntry = {
    checked : null,
    parent_id : null,
    clicked: null,
    init : function() {
      	$("body").on('click', "#search-results-id th a", function(e) {
      		searchEntry.parent_id = $(this).closest("div").attr("id");
      		var order = this.id;
      		searchEntry.clicked = this;
      		$(this).css({
          "cursor":"wait"
        });
      		data = searchEntry.getData();
      		data.order=order;
        url = 'moderation/search';
        jQuery.get(url, data, searchEntry.update, 'html');
        return false
      	});
      $("body").on('click', ".pagination a", function(e) { 
        var url =$(this).attr('href');
        searchEntry.parent_id = $(this).closest("div").attr("id");
        if (searchEntry.parent_id=='search-results-id') {
           data = searchEntry.getData();
           url = url.replace('moderation?','moderation/search?')
        } else if (searchEntry.parent_id=='listen') {
           data = {"partial":"listen", "ajax":1};
        } else if (searchEntry.parent_id=='syndicate') {
           data = {"partial":"syndtcate", "ajax":1};
        }
        jQuery.get(url, data, searchEntry.update, 'html');
        return false
      }); 
      // for search click radio buttons
      $("body").on('click', "input:radio[name='moderation']", function(e) {
         searchEntry.parent_id = "search-results-id";
         data = searchEntry.getData();
         var url = "/moderation/search"
         jQuery.get(url, data, searchEntry.update, 'html');
         return true
      });
      // for search Filter link
      $("body").on('click', "input[name='search']", function(e) {
        searchEntry.parent_id = "search-results-id";
        data = searchEntry.getData();
        var url = "/moderation/search"
        jQuery.get(url, data, searchEntry.update, 'html');
        return false
      });
    },
    update : function(data) {
      	$(searchEntry.clicked).css({
        "cursor":"pointer"
      });
      $('#'+searchEntry.parent_id).html(data);
    },
    getData : function() {
      var start_date = $("#start_date").val();
      var end_date = $("#end_date").val();
      var forum_type = $("#forum_type").val();
      var branch = $('input[name="branch"]').val();
      var location = $('input[name="location"]').val();
      var op = $('input:radio[name="moderation"]:checked').val();
      var data = {};
      data.ajax=1;
      data.search_for = op;
      if (start_date.length>0)
        data.start_date = start_date;
      if (end_date.length>0)
        data.end_date = end_date;
      if (forum_type!=null && forum_type.length>0)
        data["forum_type[]"] = forum_type;
      if (branch.length>0)
        data.branch = branch;
      if (location.length>0)
        data.location = location;
      return data;
    }
}
/** modal window ***/
var emailReport = {
    anchor_id : 0,
    modalId : 'modal-window',
    init : function() {
      jQuery("body").on('click', "#send-email", function(e) {
        emailReport.anchor_id=this.id;
        var modal_height = 100;
        Modal.open(emailReport.modalId, emailReport.anchor_id, modal_height);
        return false;
        
      });
      $('body').on('click', "#email-submit", function(e) {
        	var email = $('input[name="email"]').val();
        $(this).css({
          "cursor" : "wait"
        });
        var url= '/analytics/send_email'
        jQuery.get(url, {email: email}, null, 'html');
        $('#'+emailReport.modalId).hide();
        return false;
      });
      $('body').on('click','input[name="cancel"]', function(e) {
        $('#'+emailReport.modalId).hide();
      });

    },
    change : function(data) {
      	var obj = jQuery.parseJSON(data);
    	  $('#error').addClass(obj.error).html(obj.msg);
      $('body').css({
        "cursor" : "pointer"
      });
    },
    updated : function(data) {
      $('body').css({
        "cursor" : "pointer"
      });
      $('#modal-window').html(data)
      Modal.open(emailReport.modalId, emailReport.anchor_id);
    },
  }
var editHealth = {
    entry_id : 0,
    modalId : 'modal-window',
    init : function() {
      jQuery("body").on('click', ".branch-name", function(e) {
        var name = $(this).text(); // get branch name
        editHealth.entry_id=this.id;
        $(this).css({
          "cursor" : "wait"
        });
        var url= $(this).attr("data-url");
        jQuery.get(url, {}, editHealth.updated, 'html')

        return false;
      });
      $('body').on('click', "#submit", function(e) {
        var url="/healthcheck/" + editHealth.entry_id + "/edit";
        $(this).css({
          "cursor" : "wait"
        });
        data = {};
        records = $('input[name*="record"],select[name*="record"]');
        records.each(function () {
        	  if (this.name=='record[send_alarm]') {
        	    	data[this.name] = this.checked
        	  } else {
            data[this.name] = this.value;
        	  }
        });
        jQuery.get(url, data, editHealth.change, 'html');
        $('#'+editHealth.modalId).hide();
        return false;
      });
      $('body').on('click','input[name="cancel"]', function(e) {
        $('#'+editHealth.modalId).hide();
      });

    },
    change : function(data) {
      	var obj = jQuery.parseJSON(data);
    	  $('#error').addClass(obj.error).html(obj.msg);
      $('body').css({
        "cursor" : "pointer"
      });
    },
    updated : function(data) {
      $('.branch-name').css({
        "cursor" : "pointer"
      });
      $('#modal-window').html(data)
      Modal.open(editHealth.modalId, editHealth.entry_id);
    },
  }
var loadSoundCloud = {
    entry_id : 0,
    modalId : 'modal-window',
    init : function() {
      $("body").on('click','.publish-syndicate a', function(e) {
        loadSoundCloud.entry_id=this.id;
        $(this).css({
          "cursor" : "wait"
        });
        var url= $(this).attr("data-url");
        if ( loadSoundCloud.entry_id.charAt(0) == 'P')
          jQuery.get(url, {}, loadSoundCloud.updated, 'html')
        else if ( loadSoundCloud.entry_id.charAt(0) == 'S')
          jQuery.get(url, {}, loadSoundCloud.change, 'html')
        else {
        	  var myRe = /\?(\w+)=/;
        	  var myArr = myRe.exec(url);
        	$('<div></div>').appendTo('body')
          .html('<div><h3>Are you sure you want to '+myArr[1]+' this message?</h3></div>')
          .dialog({
              modal: true, title: 'Delete message', zIndex: 10000, autoOpen: true,
              width: 'auto', resizable: false,
              buttons: {
                  Yes: function () {
                      $(this).dialog("close");
                      jQuery.get(url, {}, loadSoundCloud.json, 'html')
                  },
                  No: function () {
                      $(this).dialog("close");
                  }
              },
              close: function (event, ui) {
                  $(this).remove();
              }
          });
        }
        return false;
      });
      $('body').on('click', "#soundcloud-upload #submit", function(e) {
        var url="/moderation/" + loadSoundCloud.entry_id.match(/\d+/) + "/edit";
        $(this).css({
          "cursor" : "wait"
        });
        data = {};
        records = $('input[name*="soundcloud"]');
        records.each(function () {
          data[this.name] = this.value;
        });
        jQuery.get(url, data, loadSoundCloud.change, 'html');
        return false;
      });
      $('body').on('click','input[name="cancel"]', function(e) {
        $('#'+loadSoundCloud.modalId).hide();
      });

    },
    change : function(data) {
      $('.publish-syndicate a').css({
        "cursor" : "pointer"
      });
      var o = jQuery('#'+loadSoundCloud.modalId)
      o.html(data);
      Modal.open(loadSoundCloud.modalId, loadSoundCloud.entry_id);
    },
    json : function(data) {
      $('.publish-syndicate a').css({
        "cursor" : "pointer"
      });
      var obj = jQuery.parseJSON(data);
      my = jQuery("."+obj.error);
      my.html(obj.message);
      my.fadeIn("fast").delay(5000).fadeOut("slow");
    },
    updated : function(data) {
      $('.publish-syndicate a').css({
        "cursor" : "pointer"
      });
      var obj = jQuery.parseJSON(data);
      my = jQuery("#publish-to-dropbox")
      my.addClass(obj.error).html(obj.message);
      my.fadeIn("fast").delay(3000).fadeOut("slow");
    },
  }


/******/

var monitor = {
	init : function() {
		var v = jQuery("#record_deliver_method").val();
		monitor.update(v);
		jQuery("body").on('change', "#record_deliver_method", function(e) {
			var v = jQuery(this).val();
			monitor.update(v);
		});
	},
	update : function(value) {
		if (value == 'email') {
			document.getElementById("record_cell_phone").disabled = true;
			document.getElementById("record_phone_carrier").disabled = true;
			document.getElementById("record_email").disabled = false;
		} else {
			document.getElementById("record_cell_phone").disabled = false;
			document.getElementById("record_phone_carrier").disabled = false;
			document.getElementById("record_email").disabled = true;
		}
	}
}
var loadMessage = {
	init : function() {
		jQuery("body").on('change', "#message-name", function(e) {
			var v = jQuery(this).val();
			jQuery.post('/api/prompt', {
				"msg[name]" : v,
				_method : 'post'
			}, loadMessage.updated, 'text');
			return false;
		});
	},
	updated : function(data) {
		jQuery("#record_description_,.description-input").val(data);
	}
}
var required = {
	init : function() {
		jQuery("#submit")
				.click(
						function(e) {
							var v = jQuery("#soundcloud_title").val();
							if (v) {
								// jQuery('#uploadForm').submit();
							} else {
								jQuery('#result')
										.html(
												"<span class='error'>Error: Title is required</span>");
								return false;
							}
						});
	}
}

String.prototype.titleize = function() {
	return this.charAt(0).toUpperCase() + this.slice(1);
}

var sortable = {
	branch_id : null,
	init : function(branch_id) {
	  sortable.branch_id = branch_id;
	  $("#sortable").sortable();
     $("#sortable").sortable("disable");
     $("#sortable").disableSelection();
     $("#sortable").sortable({
       out: function( event, ui ) {
       	/*
         $("#sortable").sortable("cancel");
         $("#sortable").sortable("enable"); */
       }
     });
     
     $('#sortable').on("mousedown",".mbMiniPlayer",function(){
       $("#sortable").sortable("disable");
       $.each($('[id*="mp_"]'), function() { 
         id = $(this).attr('id').match(/JPL_mp_\d+/);
         if (id!= null && id.length>0) {
           // alert($('#'+id).event.playing);
         }
       });
     }); 
     $(".audio").mb_miniPlayer({
     	 //width:240,
       inLine:false,
       id3:false,
       showControls:false,
       animate:false,
       showVolumeLevel:false,
       showTime:true,
       showRew:false,
       addShadow:false,
       onPlay:function() {
         $("#sortable").sortable("disable");
       },
       onEnd:function() {
         $("#sortable").sortable("enable");
       }
     });
	},
	
	showIds : function() {
     var ids = $("#sortable").sortable("toArray");
     var arr = [];
     var url = "/branch/sorted_entries";
     for (var i in ids) {
       if ($('#M'+ids[i]).prop('checked')==true) {
         arr.push(ids[i])
       }
     }
     var data = {
     	 ids: ids,
       sorted: arr,
       branch_id: sortable.branch_id
     }
     $.post(url, data, null, 'html');
   },
   toggle : function() {
   	  $("#sortable").sortable();
   	  var isOff = $("#sortable").sortable( "option", "disabled" );
     // var isOff = $("#sortable").sortable( ".match(/(\w+)_name/);option", "disabled" );
     if (isOff) {
       $("#sortable").sortable("enable");
       $("#moderate-enable").val("Disable Sorting")
     } else {
	    $("#sortable").sortable("disable");
	    $("#moderate-enable").val("Enable Sorting")
     }
   },
}
 
var sortTable = {
	table_id : null,
	player_class : null,
	toggle_id: null,
	sort_id: null,
	init : function(table_id, player_class, toggle_id) {
	  sortTable.table_id = table_id;
	  sortTable.sort_id = "#"+table_id + " tbody";
	  sortTable.player_class = "." + player_class;
	  sortTable.toggle_id = "#"+toggle_id;
	  $(sortTable.sort_id).sortable();
     // $(sortTable.sort_id).sortable("disable");
     $(sortTable.sort_id).disableSelection();
     $(sortTable.sort_id).sortable({
       out: function( event, ui ) {
       	/*
       	$(sortTable.sort_id).sortable();
         $(sortTable.sort_id).sortable("cancel");
         $(sortTable.sort_id).sortable("enable");
         $(sortTable.toggle_id).val("Disable Sorting"); */
       }
     });
     $(sortTable.sort_id).on("mousedown",".mbMiniPlayer",function(){
     	 $(sortTable.sort_id).sortable();
       $(sortTable.sort_id).sortable("Enable");
       $(sortTable.toggle_id).val("Disable Sorting")
     });
     $(sortTable.sort_id).on("mouseup",".mbMiniPlayer",function(){
     	 $(sortTable.sort_id).sortable();
       $(sortTable.sort_id).sortable("disable");
       $(sortTable.toggle_id).val("Enable Sorting")
     });
     $(sortTable.player_class).mb_miniPlayer({
     	 //width:240,
       inLine:false,
       id3:false,
       showControls:false,
       animate:false,
       showVolumeLevel:false,
       showTime:true,
       showRew:false,
       addShadow:false,
       onPlay:function() {
         $(sortTable.sort_id).sortable("disable");
         $(sortTable.toggle_id).val("Enable Sorting")
       },
       onEnd:function() {
         $(sortTable.sort_id).sortable("enable");
         $(sortTable.toggle_id).val("Disable Sorting")
       }
     });
     $(sortTable.sort_id).on("click","input[type='checkbox']",function(){
     	/*
       var op = $(this).prop('checked');
       if (op==false)
         $(this).removeProp('checked');
       else 
       	$(this).prop('checked', true);
       	
       	*/
     });
	},
	
	showIds : function() {
     var ids = $(sortTable.sort_id).sortable("toArray");
     var arr = [];
     var url = "/branch/sorted_entries";
     for (var i in ids) {
       if ($('#M'+ids[i]).prop('checked')==true) {
         arr.push(ids[i])
       }
     }
     var data = {
     	 ids: ids,
       sorted: arr,
     }
     $.post(url, data, null, 'html');
   },
   toggle : function() {
     var isOff = $(sortTable.sort_id).sortable( "option", "disabled" );
     $(sortTable.sort_id).sortable();
     if (isOff) {
       $(sortTable.sort_id).sortable("enable");
       $(sortTable.toggle_id).val("Disable Sorting")
     } else {
	    $(sortTable.sort_id).sortable("disable");
	    $(sortTable.toggle_id).val("Enable Sorting")
     }
   },
}
var reportUpload = {
  myId : '',
	init : function(forum_type) {
		var ids = "#introduction,#goodbye,#bulletin_question, .square";
		jQuery("#forum-template").on('click', ".square", function(e) {
			var name = this.id; // this div id is used as template.name
			var url;
			if (name == 'headline') {
			  url = '/templates/headline';
			} else if (name == 'moderate') {
			  $('#moderate-div').show();
			  $('#forum-upload').hide();
			  return false;
		  } else {
		    url = '/templates/new';
		  }
	     $('#moderate-div').hide();
			reportUpload.myId = this.id;
			$(this).css("cursor", "progress");
			var b = jQuery('#branch-name').val();
			var data = {
				name : name,
				type : forum_type,
				branch : b
			};
			jQuery.get(url, data, reportUpload.update, 'html');
			jQuery('#forum-upload').show();
			$(".square").removeClass('square-clicked');
			$('#'+reportUpload.myId).addClass('square-clicked');
		});
    
		jQuery("#configure_feed_source").on('change', function(e) {
			var feed_source = $(this).val();
			if (feed_source=='upload') {
			  var branch_id = jQuery('#configure_branch_id').val();
			  var url = '/templates/report';
			  var data = {
				  feed_source : feed_source,
				  branch_id : branch_id
			  };
			  // jQuery.get(url, data, reportUpload.update, 'html');
			  Modal.open("report-upload", 'configure_feed_source', 200);
			  jQuery('#report-upload').show();
		   }
		});
		
		jQuery("#template-headline").on('click', "#save", function(e) {
			var url = '/templates/headline';
			jQuery("[name='todo']").val("save");
			var options = {
				beforeSubmit : function(arr, $form, options) {
					jQuery('#template-popup').css("cursor", "progress");
				},
				success : function(data) {
					jQuery('#template-popup').css({
						"cursor" : "hand",
						"cursor" : "pointer"
					});
					jQuery("#forum-upload").html(data);
					jQuery(".error").hide();
				}
			};
			$('#frm-headline').ajaxForm(options);
		});
		
		$("#report-popup").on('click', "#preview-report, #save-report", function(e) {
			var url = $('#frm-upload-report').attr('action');
		   var identifier = $('.custom-combobox-input').val();
	      $("[id*='_identifier']").append('<option value="'+identifier +'" selected="selected">'+identifier+'</option>');
         var temp_name = $("[id*='_name']").attr('value');
         var id = $("[id*='_name']").attr('id').match(/(\w+)_name/);
         var forum_type = id[1];
			var options = {
				beforeSubmit : function(arr, $form, options) {
				$('#report-popup').css("cursor", "progress");
				},
				success : function(data) {
				  $('#report-popup').css({
						"cursor" : "hand",
						"cursor" : "pointer"
				  });
				  $("#notice").html(data);
				}
			};
			$('#frm-upload-report').ajaxForm(options);
		});
		
		
		
		jQuery("#template-popup").on('click', "#preview, #save", function(e) {
			var url = '/templates';
			jQuery(this).css("cursor", "progress");
			var v = jQuery("[id*='_sound']").val();
         if(v.length==0 && this.id=="preview") {
           alert("You must select a upload file first")
           return false;
         }
     
	      jQuery("[name='todo']").val(this.id);
	      // jquery combobox for Voting Session Name
	   
	      
	      var identifier = $('.custom-combobox-input').val();
	      $("[id*='_identifier']").append('<option value="'+identifier +'" selected="selected">'+identifier+'</option>');
         var temp_name = $("[id*='_name']").attr('value');
         var id = $("[id*='_name']").attr('id').match(/(\w+)_name/);
         var forum_type = id[1];
         var description = temp_name.match(/result/);

         if (this.id=="save" && description == "result") {
	         ok =  confirm('Save a Forum Result template indicates the Vote/Poll is ended. Continue?');
            if (!ok)
             return false;      
         }
     
         $( "<input>" ).appendTo('#frm-upload-logo')
          .attr( "type", "hidden" )
          .attr( "name", forum_type+"[description]" )
          .val(description);
          
			var options = {
				beforeSubmit : function(arr, $form, options) {
				  // jQuery('#template-popup').css("cursor", "progress");
				},
				success : function(data) {
					$('#template-popup').css({
						"cursor" : "hand",
						"cursor" : "pointer"
					});
					$("#forum-upload, .forum-upload").html(data);
					$(".error").hide();
					$("[name*='[identifier]']").attr("readonly", "readonly")
				}
			};

			$('#frm-upload-logo').ajaxForm(options);
			$('#forum-upload, .forum-upload').show();
		});
		$(".template-popup").on('click', "#cancel", function(e) {
			$('#forum-upload, .forum-upload').hide();
			return false;
		});
		$("#report-popup").on('click', "#cancel-report", function(e) {
			$('#report-upload').hide();
			return false;
		});
		
		//$(".template-popup").on('click', "#moderate", function(e) {
			// return false;
		//});
	},
	update : function(data) {
		$("#forum-upload").html(data);
		$(".square").css("cursor", "pointer");
	}
}

var branchManage = {
  branchAction : '',
  myId : '',
	init : function() {
	  var branch_id = $("#record_id").val()
	  if (branch_id > 0 ) {
	    var url = '/branch/' + branch_id;
      var data = {};
      jQuery.get(url, data, branchManage.updateForumType, 'html');
	  };
		jQuery("#branch").on('click', "#create", function(e) {
			var name = this.id;
			var url = '/branch/new';
			var branch_id = $("#record_id").val();
			var data={};
	    if (branch_id > 0 ) {
	      branchManage.branchAction = 'Edit Branch'
			  data = {branch_id: branch_id}
	    } else {
	      branchManage.branchAction = 'Create Branch'
	    }
			jQuery.get(url, data, branchManage.update, 'html');
			jQuery('#new-branch').show();
			return false
		});
		jQuery("#branch").on('click', "#delete", function(e) {
			var branch_id = $("#record_id").val();
			var branch_name = $('#record_id :selected').text();
			$('<div></div>').appendTo('body')
      .html('<div><h3>Are you sure you want to delete branch: ' + branch_name + '</h3></div>')
      .dialog({
          modal: true, title: 'Delete Branch', zIndex: 10000, autoOpen: true,
          width: 'auto', resizable: false,
          buttons: {
              Delete: function () {
                  $(this).dialog("close");
                  var url = '/branch/'+branch_id;
                  $.ajax({
                    url: url,
                    type: 'DELETE',
                    success: function(result) {
                    	  $('#record_id').html(result)
                      $('#go-template').hide();
                    	  $('#go-template-result').hide();
                    	  $(".TabbedPanelsTab").removeClass('TabbedPanelsTabSelected');
                  		  
                    }
                });
              },
              Cancel: function () {
                  $(this).dialog("close");
              }
          },
          close: function (event, ui) {
              $(this).remove();
          }
      });
		 
		});
		jQuery("#branch").on('change', "#record_id", function(e) {
			var branch_id = this.value;
			branchManage.myId = this.id
			$("#branch").css("cursor", "progress");
			if (branch_id==0) {
			  $('#create').val('Create Branch');
			  $(".TabbedPanelsTab").removeClass('TabbedPanelsTabSelected');
			  $('#go-template').hide();
			  $('#new-branch').hide();
			  return false;
			}
			$("#delete").show();
			var url = '/branch/' + branch_id;
			var data = {};
			// reset the notice msg
			jQuery('#return-msg').html('');
			jQuery.get(url, data, branchManage.updateForumType, 'html');
		});
		jQuery("#frm-new-branch").on('click', "#save", function(e) {
			var url = '/branch';
			var options = {
				beforeSubmit : function(arr, $form, options) {
					jQuery('#branch').css({
						"cursor" : "wait"
					});
				},
				success : function(data) {
					jQuery('#new-branch').hide();
					jQuery('#go-template').show();
					jQuery('#branch').css({
						"cursor" : "hand",
						"cursor" : "pointer"
					});
					var obj = jQuery.parseJSON(data);
					jQuery('#go-template').attr('href',"/templates?branch=" + obj.branch);
					if (obj.error == 'error')
						jQuery(".error").html(obj.msg);
					else
						jQuery(".notice").html(obj.msg);
				}
			};
			$('#frm-new-branch').ajaxForm(options);
		});
		$("#branch").on('click', ".square", function(e) {
			branchManage.myId = this.id
			var name = this.id; // this div id is used as template.name
			var url;
			if (name == 'headline') {
			  url = '/templates/headline';
		  } else {
		    url = '/templates/new';
		  }
			var forum_type = $('input[name="forum-type"]').val();
			$("#"+branchManage.myId).css("cursor", "wait");
			var b = $('#branch-name').val();
			var data = {
				name : name,
				type : forum_type,
				branch : b
			};
			jQuery.get(url, data, branchManage.updateForum, 'html');
			return false;
		});
		$("#activate-forum-div").on('click', "#save", function(e) {
			branchManage.myId = this.id
			var id = $('#activate_forum :selected').val();
			var url = '/branch/activate_forum';
			$("#"+branchManage.myId).css("cursor", "wait");
			var data = {
				id : id,
				ajax: 1
			};
			jQuery.get(url, data, function(result) {
			   $('#return-msg').html(result);
			}, 'html');
			return false;
		});
		jQuery("#branch").on(
				'click',
				".TabbedPanelsTab, input[name='forum_type']",
				function(e) {	
					var forum_type = this.id;
					branchManage.myId = this.id;
					branch_id = $("#record_id").val();
					if (branch_id == '0') {
						$('#return-msg').html('Please select a branch')
						$("*").css("cursor", "default");
						return false;
					}
					if (branchManage.myId=='active-forum') {
						/* var data = {
				        branch_id : branch_id,
				        ajax: 1
			         };
			         $.get("/branch/activate_forum", data, function(result) {
			            $('#forum-activate').html(result);
			         }, 'html');
			         */
			         Modal.open("forum-activate", branchManage.myId, 140);
			         return false;
					}
					
					$("*").css("cursor", "progress");
		         $(".TabbedPanelsTab").removeClass('TabbedPanelsTabSelected');
		         $("#" + forum_type).addClass('TabbedPanelsTabSelected');
					
					var url = '/branch/' + branch_id;
					var data = {
						forum_type : forum_type
					};
					$.get(url, data, function(data) {
						$("*").css({
						  "cursor" : "default"
						});
						var obj = jQuery.parseJSON(data);
					   jQuery('#audio-player-div').html(obj.audios);
						jQuery('#return-msg').html(
								"Forum Type changed to " + obj.forum_ui.titleize());
						/*
						jQuery('#go-template').show();
						jQuery('#go-template').attr('href',"/templates?branch=" + obj.branch);
						if (forum_type=="poll" || forum_type=="vote") {
						  jQuery('#go-template-result').show();
	                 jQuery('#go-template-result').attr('href',"/templates?result=1&branch=" + obj.branch);
						} else {
						  jQuery('#go-template-result').hide();
						}
						*/
					}, 'html');

				});
		jQuery("#frm-new-branch, #forum-activate").on('click', "#cancel", function(e) {
			jQuery('#new-branch, #forum-activate').hide();
			return false;
		});
	},
	updateForumType : function(data) {
		$("#branch").css({
			"cursor" : "default"
		});
	  $('#create').val('Edit Branch');
		var obj = jQuery.parseJSON(data);
		if (obj.forum.length>0) {
			// $('#audio-player-div').html(obj.audios);
		  jQuery(".TabbedPanelsTab").removeClass('TabbedPanelsTabSelected');
		  jQuery("#" + obj.forum).addClass('TabbedPanelsTabSelected');
		  jQuery("#forum_type_" + obj.forum).prop('checked', true);
		  
		  jQuery('#go-template').attr('href', "/templates?branch=" + obj.branch);
		  jQuery('#go-template').show();
		  if (obj.forum=='vote' || obj.forum=='poll') {
		    jQuery('#go-template-result').attr('href', "/templates?result=1&branch=" + obj.branch);
		    jQuery('#go-template-result').show();
		  } else {
		  	 $('#go-template-result').hide();
		  }
		  jQuery('#go-template-hint').html(obj.hint);
		  
		} else {
		  // jQuery("[id*='forum_type_']").prop('checked', false);
		  jQuery(".TabbedPanelsTab").removeClass('TabbedPanelsTabSelected');
		  jQuery("[id^='go-template']").hide();
		}
	},
	update : function(data) {
		jQuery("#new-branch").html(data);
		$('#create-branch').html(branchManage.branchAction)
	},
	updateForum : function(data) {
		$("#"+branchManage.myId).css({
			"cursor" : "pointer"
		});
		$("#forum-audio-upload").html(data);
      Modal.open("forum-audio-upload", branchManage.myId, 220);
		//jQuery("#forum-audio-upload").show().html(data);
	},
}

var submitReport = {
	init : function() {
		jQuery("#report-logout").on('click', "#report-submit", function(e) {
			var branch_id=$('#branch_id').val();
			var url = '/reports';
			var data = {
				"branch_id[]" : branch_id,
				start_date: $('#start_date').val(),
				end_date: $('#end_date').val(),
			};
			jQuery.post(url, data, function(data) {
				$('#report-detail').show();
				$('#report-detail').html(data)
			});
		});
	}
}

function blinkeffect(selector) {
	$(selector).fadeOut('slow', function() {
		$(this).fadeIn('slow', function() {
			blinkeffect(this);
		});
	});
}
function getwith(to, options) {
	var myForm = document.createElement("form");
	myForm.method = "get";
	myForm.action = to;
	for ( var k in options) {
		var myInput = document.createElement("input");
		myInput.setAttribute("name", k);
		myInput.setAttribute("value", options[k]);
		myForm.appendChild(myInput);
	}
	document.body.appendChild(myForm);
	myForm.submit();
	document.body.removeChild(myForm);
}

// used in _google_map.html.erb
function SaveBbgMap(lat, lng)
{
  var map = Gmaps.map.map;
  var mapzoom=map.getZoom();
// var mapcenter=map.getCenter();
// var maplat=mapcenter.lat();
// var maplng=mapcenter.lng();
  var cookiestring=lat+"_"+lng+"_"+mapzoom;
  var exp = new Date(); //set new date object
  exp.setTime(exp.getTime() + (1000 * 60 * 60 * 24 * 30)); //set it 30 days ahead
  setCookie("DaftLogicGMRLL",cookiestring, exp);
}
function LoadBbgMap()
{
  var loadedstring=getCookie("DaftLogicGMRLL");
  if (loadedstring.length==0 || loadedstring.match(/NaN_NaN_/)) {
	  return;
  } else {
  }
  var splitstr = loadedstring.split("_");
  Gmaps.map.map.setCenter(new google.maps.LatLng(parseFloat(splitstr[0]), parseFloat(splitstr[1])));
  var savedMapZoom = parseFloat(splitstr[2]);
  Gmaps.map.map.setZoom(savedMapZoom);
} 
function setCookie(name, value, expires) 
{
  document.cookie = name + "=" + escape(value) + "; path=/" + ((expires == null) ? "" : "; expires=" + expires.toGMTString());
} 
function getCookie(c_name)
{
  if (document.cookie.length>0) {
    c_start=document.cookie.indexOf(c_name + "=");
    if (c_start!=-1) { 
      c_start=c_start + c_name.length+1; 
      c_end=document.cookie.indexOf(";",c_start);
      if (c_end==-1) 
      	  c_end=document.cookie.length;
      return unescape(document.cookie.substring(c_start,c_end));
    } 
  }
  return "";
}

var updateLatLonFields = function(lat, lon) {
  lat = lat.toFixed(8);
  lon = lon.toFixed(8);
  document.getElementById("latlon").innerHTML=lat+','+lon;
  SaveBbgMap(lat, lon);
};
var googleMapCallback = function() {
  var crosshairShape = {coords:[0,0,0,0],type:'rect'};
  var marker = new google.maps.Marker({
      map: Gmaps.map.map,
      // icon: 'assets/crosshair.gif',
      icon: new google.maps.MarkerImage('assets/crosshair.gif', null, null, new google.maps.Point(10,10)),
      shape: crosshairShape
      });
   marker.bindTo('position', Gmaps.map.map, 'center');
         
   google.maps.event.addListener(Gmaps.map.serviceObject, 'center_changed', function(event){
     // alert(event.toSource()) 
     // Gmaps.map.map.setCenter(event.latLng);
     var center = Gmaps.map.map.getCenter();
     updateLatLonFields(center.lat(), center.lng());
   });
   google.maps.event.addListener(Gmaps.map.serviceObject, "zoom_changed", function() {
     var center = Gmaps.map.map.getCenter();
     updateLatLonFields(center.lat(), center.lng());
   });
};

// for editable select options
(function( $ ) {
  $.widget( "custom.combobox", {
    _create: function() {
      this.wrapper = $( "<span>" )
        .addClass( "custom-combobox" )
        .insertAfter( this.element );

      this.element.hide();
      this._createAutocomplete();
      this._createShowAllButton();
    },

    _createAutocomplete: function() {
      var selected = this.element.children( ":selected" ),
        value = selected.val() ? selected.text() : "";

      this.input = $( "<input>" )
        .appendTo( this.wrapper )
        .val( value )
        .attr( "title", "" )
        .addClass( "custom-combobox-input ui-widget ui-widget-content ui-state-default ui-corner-left" )
        .autocomplete({
          delay: 0,
          minLength: 0,
          source: $.proxy( this, "_source" )
        })
        .tooltip({
          tooltipClass: "ui-state-highlight"
        });

      this._on( this.input, {
        autocompleteselect: function( event, ui ) {
          ui.item.option.selected = true;
          this._trigger( "select", event, {
            item: ui.item.option
          });
        },

        autocompletechange: "_removeIfInvalid"
      });
    },

    _createShowAllButton: function() {
      var input = this.input,
        wasOpen = false;

      $( "<a>" )
        .attr( "tabIndex", -1 )
        .attr( "title", "Show All Items" )
        .tooltip()
        .appendTo( this.wrapper )
        .button({
          icons: {
            primary: "ui-icon-triangle-1-s"
          },
          text: false
        })
        .removeClass( "ui-corner-all" )
        .addClass( "custom-combobox-toggle ui-corner-right" )
        .mousedown(function() {
          wasOpen = input.autocomplete( "widget" ).is( ":visible" );
        })
        .click(function() {
          input.focus();

          // Close if already visible
          if ( wasOpen ) {
            return;
          }

          // Pass empty string as value to search for, displaying all results
          input.autocomplete( "search", "" );
        });
    },

    _source: function( request, response ) {
      var matcher = new RegExp( $.ui.autocomplete.escapeRegex(request.term), "i" );
      response( this.element.children( "option" ).map(function() {
        var text = $( this ).text();
        if ( this.value && ( !request.term || matcher.test(text) ) )
          return {
            label: text,
            value: text,
            option: this
          };
      }) );
    },
    /*
    _removeIfInvalid: function( event, ui ) {

      // Selected an item, nothing to do
      if ( ui.item ) {
        return;
      }

      // Search for a match (case-insensitive)
      var value = this.input.val(),
        valueLowerCase = value.toLowerCase(),
        valid = false;
      this.element.children( "option" ).each(function() {
        if ( $( this ).text().toLowerCase() === valueLowerCase ) {
          this.selected = valid = true;
          return false;
        }
      });

      // Found a match, nothing to do
      if ( valid ) {
        return;
      }

      // Remove invalid value
      this.input
        .val( "" )
        .attr( "title", value + " didn't match any item" )
        .tooltip( "open" );
      this.element.val( "" );
      this._delay(function() {
        this.input.tooltip( "close" ).attr( "title", "" );
      }, 2500 );
      this.input.data( "ui-autocomplete" ).term = "";
    },
    */
    _destroy: function() {
      this.wrapper.remove();
      this.element.show();
    }
  });
})( jQuery );
(function($) {
	$.fn
			.extend({
				limit : function(limit, element) {
					var interval, f;
					var self = $(this);
					$(this).focus(function() {
						interval = window.setInterval(substring, 100);
					});
					$(this).blur(function() {
						clearInterval(interval);
						substring();
					});
					$(this).keyup(function() {
						clearInterval(interval);
						substring();
					});
					substringFunction = "function substring(){ var val = $(self).val();var length = val.length;if(length > limit){$(self).val($(self).val().substring(0,limit));}";
					if (typeof element != 'undefined')
						substringFunction += "if($(element).html() != limit-length){$(element).html((limit-length<=0)?'0':limit-length);}"
					substringFunction += "}";
					eval(substringFunction);
					substring();
				}
			});
})(jQuery);
