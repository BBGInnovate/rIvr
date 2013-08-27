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
			var name = this.id;
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
					jQuery('#template-popup').css({
						"cursor" : "wait"
					});
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
			jQuery("[name='todo']").val(this.id);
			jQuery('#template-popup').css({
        "cursor" : "wait"
      });
			var options = {
				beforeSubmit : function(arr, $form, options) {
				},
				success : function(data) {
				  jQuery('.error').hide();
					jQuery('#template-popup').css({
						"cursor" : "hand",
						"cursor" : "pointer"
					});
					jQuery("#forum-upload").html(data);
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
		$(reportUpload.myId).css("cursor", "pointer");
	}
}

var branchManage = {
	init : function() {
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
				"input[name='forum_type']",
				function(e) {
					var forum_type = this.value;
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
		  jQuery("#forum_type_" + obj.forum).prop('checked', true);
		  jQuery('#go-template').attr('href', "/templates?branch=" + obj.branch);
		  jQuery('#go-template').show();
		  if (obj.forum=='vote' || obj.forum=='poll') {
		    jQuery('#go-template-result').attr('href', "/templates?result=1&branch=" + obj.branch);
		    jQuery('#go-template-result').show();
		  }
		} else {
		  jQuery("[id*='forum_type_']").prop('checked', false);
		  jQuery("[id^='go-template']").hide();
		}
	},
	update : function(data) {
		jQuery("#new-branch").html(data);
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
function dump() {
}
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
