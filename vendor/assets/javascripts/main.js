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
        //window.location = url;
        var data = {ajax: 1};
        jQuery.get(url, data, homePage.update, 'html');
        return false
      });
    },
    update : function(data) {
      $('#'+homePage.anchorId).html(data);
    }
}
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
			var data = {};
			jQuery.get(url, data, branchManage.update, 'html');
			jQuery('#new-branch').show();
			return false
		});
		jQuery("#branch").on('change', "#record_id", function(e) {
			var branch_id = this.value;
			var url = '/branch/' + branch_id;
			var data = {};
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
								"Forum Type changed to " + obj.forum.titleize());
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
