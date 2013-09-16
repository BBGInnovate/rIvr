var datePicker = {
  options : {
  	dateFormat: "yy-mm-dd",
    changeMonth: true,
    changeYear: true,
    showButtonPanel: true,
    minDate: new Date(2013, 0, 1),
    maxDate: '+1Y',
    showOn: 'button',
    buttonImageOnly: true,
    buttonImage: 'assets/calendar.gif' 
  },
  css : {
  	  "vertical-align": "middle",
    "line-height": "24px",
    "margin-left": "5px",
    "width": "20px",
    "height": "20px"
  },
	init : function(start_date_id, end_date_id) {
		$("#"+start_date_id).datepicker(datePicker.options);
		$("#"+end_date_id).datepicker(datePicker.options);
		$('.ui-datepicker-trigger').css(datePicker.css);
	},
	update : function() {
		
	}
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
      jQuery("body").on('click', ".left-nav-bar", function(e) {
        // var name = this.id;
        // var url = '/'+name;
        var url = $(this).attr("data-url");
        window.location = url;
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
      $("body").on('click', "#report-submit", function(e) {
        var br = $('#branch_id').val();
        var start_date = $('#start_date').val();
        var end_date = $('#end_date').val();
        $('#error').html('');
        if (br == null) {
          $('#error').html("Must select a Branch");
          return false;
        }
        if (start_date.length==0 || end_date.length==0 ) {
          $('#error').html("Must select a Start Date and End Date");
          return false;
        }
        var fmt = $("input:radio[name='format']:checked").val();
        var data = {ajax: 1, "branch_id[]": br, start_date: start_date,
            end_date: end_date, format: fmt};
        var url = "/reports/"
        if (fmt=='csv') {
          $('#post-report').submit();   
        } else {
          $.post(url, data, report.update, 'html');
        }
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
      $('#report-results').html(data);
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
    init : function() {
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
         //data.search_for = this.value;
         //var op = $('input:radio[name="moderation"]:checked').val();
         //data.search_for = op;
         var url = "/moderation/search"
         jQuery.get(url, data, searchEntry.update, 'html');
         return true
      });
      // for search Filter link
      $("body").on('click', "input[name='search']", function(e) {
        searchEntry.parent_id = "search-results-id";
        data = searchEntry.getData();
        //var op = $('input:radio[name="moderation"]:checked').val();
        //data.search_for = op;
        var url = "/moderation/search"
        jQuery.get(url, data, searchEntry.update, 'html');
        return false
      });
    },
    update : function(data) {
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
        else
          jQuery.get(url, {}, loadSoundCloud.change, 'html')
          
        return false;
      });
      $('body').on('click', "#soundcloud-upload #submit", function(e) {
        var url="/moderation/" + loadSoundCloud.entry_id.match(/\d+/) + "/edit";
        $(this).css({
          "cursor" : "wait"
        });
        dropbox_url = $('#soundcloud_url').val();
        title = $('#soundcloud_title').val();
        genre = $('#soundcloud_genre').val();
        description = $('#soundcloud_description').val();
        data={};
        data["soundcloud[title]"]=title;
        data["soundcloud[url]"]=dropbox_url;
        data["soundcloud[genre]"]=genre;
        data["soundcloud[description]"]=description; 
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
      loadSoundCloud.openModal(loadSoundCloud.modalId, loadSoundCloud.entry_id);
    },
    updated : function(data) {
      $('.publish-syndicate a').css({
        "cursor" : "pointer"
      });
      var obj = jQuery.parseJSON(data);
      my = jQuery("#publish-to-dropbox")
      my.html(obj.message);
      if (obj.error == 'error')
        my.addClass('color-red');
      else
        my.addClass('color-green');
         
      my.fadeIn("fast").delay(3000).fadeOut("slow");
    },
    openModal : function (modal_id, anchor_id) {
      // modal_id modal window placeholder id
      // anchor_id element id, click which trigers the modal window
      var modalID = "#" + modal_id;
      var anchorID = "#" + anchor_id;
      // get how many pixels that the calling link is from the top of the page -- to be used later.
      var anchorOffset = Math.floor(jQuery(anchorID).offset().top);
      
      // get the modal window's height + padding top + padding bottom
      var modalHeight = Math.floor(jQuery(modalID).height());
      // the modal's width is based off width of the site area, rather than being set off of another value
      // sitewidth - modal padding left - modal padding right - 20 ... dropping any hanging decimals
      var modalWidth = 506;
      
      // set the modal's width, to overwrite any CSS sizes
      jQuery(modalID).css('width', modalWidth);
      //now that the modal width is based off of the sitewidth, instead of other numbers, re-evaluate to get the width + padding (similiar to the height)
      modalWidth = Math.floor(jQuery(modalID).width());
      var windowWidth = jQuery(window).width();
      // find the new left for the modal window
      var newLeft = Math.floor((windowWidth - modalWidth) / 2);
      // set the new left
      jQuery(modalID).css('left', newLeft);
      // instead of using the top of the screen to determine where the modal goes, we're using the offset position of the link that calls the function
      // for the user to see the pop-up they need to click the link
      // so to ensure that the user sees the modal it will appear above the link.
      // This is taking the offset position of the link - half the modal window's height.  So in theory, the modal window's center will be right above the calling link.
      var newTop = anchorOffset - Math.floor(modalHeight / 2);
      // set the new top
      jQuery(modalID).css('top', newTop);
      // fade the modal window in
      jQuery(modalID).fadeIn();
    }
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

var reportUpload = {
  myId : '',
	init : function(forum_type) {
		var ids = "#introduction,#goodbye,#bulletin_question, .square";
		jQuery("#forum-template").on('click', ".square", function(e) {
			var name = this.id; // this div id is used as template.name
			reportUpload.myId = this.id;
			$(this).css("cursor", "progress");
			var b = jQuery('#branch-name').val();
			var url = '/templates/new';
			var data = {
				name : name,
				type : forum_type,
				branch : b
			};
			jQuery.get(url, data, reportUpload.update, 'html');
			jQuery('#forum-upload').show();
		});

		jQuery("#forum-template").on('click', "#headline", function(e) {
			var name = this.id;
			var b = jQuery('#branch-name').val();
			var url = '/templates/headline';
			var data = {
				name : name,
				type : forum_type,
				branch : b
			};
			jQuery.get(url, data, reportUpload.update, 'html');
			jQuery('#forum-upload').show();
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
		jQuery("#template-popup").on('click', "#preview, #save", function(e) {
			var url = '/templates';
			jQuery(this).css("cursor", "progress");
			var v = jQuery("[id*='_sound']").val();
      if(v.length==0 && this.id=="preview") {
        alert("You must select a upload file first")
        return false;
      }
			jQuery("[name='todo']").val(this.id);
			var options = {
				beforeSubmit : function(arr, $form, options) {
				  // jQuery('#template-popup').css("cursor", "progress");
				},
				success : function(data) {
					jQuery('#template-popup').css({
						"cursor" : "hand",
						"cursor" : "pointer"
					});
					jQuery("#forum-upload").html(data);
					jQuery(".error").hide();
					$("[name='vote[identifier]']").attr("readonly", "readonly")
				}
			};
			$('#frm-upload-logo').ajaxForm(options);
			jQuery('#forum-upload').show();
		});
		jQuery(".template-popup").on('click', "#cancel", function(e) {
			jQuery('#forum-upload').hide();
			return false;
		});
	},
	update : function(data) {
		jQuery("#forum-upload").html(data);
		$(".square").css("cursor", "pointer");
	}
}

var branchManage = {
  branchAction : '',
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
		jQuery("#branch").on('change', "#record_id", function(e) {
			var branch_id = this.value;
			if (branch_id==0) {
			  $('#create').val('Create Branch');
			  $(".TabbedPanelsTab").removeClass('TabbedPanelsTabSelected');
			  $('#go-template').hide();
			  $('#new-branch').hide();
			  return false;
			}
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
					jQuery('#branch').css({
						"cursor" : "hand",
						"cursor" : "pointer"
					});

					var obj = jQuery.parseJSON(data);
					if (obj.error == 'error')
						jQuery(".error").html(obj.msg);
					else
						jQuery(".notice").html(obj.msg);
				}
			};
			$('#frm-new-branch').ajaxForm(options);
		});
		jQuery("#branch").on(
				'click',
				".TabbedPanelsTab, input[name='forum_type']",
				function(e) {
				  // var forum_type = this.value;
					var forum_type = this.id;
		      jQuery(".TabbedPanelsTab").removeClass('TabbedPanelsTabSelected');
		      jQuery("#" + forum_type).addClass('TabbedPanelsTabSelected');
		      
					branch_id = jQuery("#record_id").val();
					if (branch_id == '0') {
						jQuery('#return-msg').html('Please select a branch')
						return false;
					}
					var url = '/branch/' + branch_id;
					var data = {
						forum_type : forum_type
					};
					jQuery.get(url, data, function(data) {
						var obj = jQuery.parseJSON(data);
						jQuery('#return-msg').html(
								"Forum Type changed to " + obj.forum_ui.titleize());
						jQuery('#go-template').show();
						jQuery('#go-template').attr('href',"/templates?branch=" + obj.branch);
						if (forum_type=="poll" || forum_type=="vote") {
						  jQuery('#go-template-result').show();
	            jQuery('#go-template-result').attr('href',"/templates?result=1&branch=" + obj.branch);
						} else {
						  jQuery('#go-template-result').hide();
						}
						
					}, 'html');

				});
		jQuery("#frm-new-branch").on('click', "#cancel", function(e) {
			jQuery('#new-branch').hide();
			return false;
		});
	},
	updateForumType : function(data) {
	  $('#create').val('Edit Branch');
		var obj = jQuery.parseJSON(data);
		if (obj.forum.length>0) {
		  jQuery(".TabbedPanelsTab").removeClass('TabbedPanelsTabSelected');
		  jQuery("#" + obj.forum).addClass('TabbedPanelsTabSelected');
		  jQuery("#forum_type_" + obj.forum).prop('checked', true);
		  jQuery('#go-template').attr('href', "/templates?branch=" + obj.branch);
		  jQuery('#go-template').show();
		  if (obj.forum=='vote' || obj.forum=='poll') {
		    jQuery('#go-template-result').attr('href', "/templates?result=1&branch=" + obj.branch);
		    jQuery('#go-template-result').show();
		  }
		} else {
		  // jQuery("[id*='forum_type_']").prop('checked', false);
		  jQuery(".TabbedPanelsTab").removeClass('TabbedPanelsTabSelected');
		  jQuery("[id^='go-template']").hide();
		}
	},
	update : function(data) {
		jQuery("#new-branch").html(data);
		$('#create-branch').html(branchManage.branchAction)
	}
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
var updateLatLonFields = function(lat, lon) {
  lat = lat.toFixed(8);
  lon = lon.toFixed(8);
  document.getElementById("latlon").innerHTML=lat+','+lon;
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
