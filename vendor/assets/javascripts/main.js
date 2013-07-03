var monitor = {
	init : function() {
		var v = jQuery("#record_deliver_method").val();
		monitor.update(v);
		jQuery("body").on('change',"#record_deliver_method", function(e) {
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
			jQuery("body").on('change',"#message-name", function(e) {
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
function dump() {	
}
(function($){ 
  $.fn.extend({  
  limit: function(limit,element) {
    var interval,  f;
    var self = $(this);
    $(this).focus(function(){
      interval = window.setInterval(substring,100);
    });
    $(this).blur(function(){
      clearInterval(interval);
      substring();
    });
    $(this).keyup(function(){
        clearInterval(interval);
        substring();
      });
    substringFunction = "function substring(){ var val = $(self).val();var length = val.length;if(length > limit){$(self).val($(self).val().substring(0,limit));}";
    if(typeof element != 'undefined')
      substringFunction += "if($(element).html() != limit-length){$(element).html((limit-length<=0)?'0':limit-length);}"
      substringFunction += "}";
      eval(substringFunction);
      substring();
    } 
  }); 
})(jQuery);
