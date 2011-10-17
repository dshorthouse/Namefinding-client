EmailForm = {
  validate : function(form) {
    var all_valid = true;
    var email_validation_regex = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i;
    
    
    form.find(':input').each(function(index, input){
      if( ! $(input).val() ) {
        all_valid =  false;
        $(input).prev().addClass('error');
      } else if ($(input).attr('type') == 'email' && !email_validation_regex.test( $(input).val() ) ) {
        all_valid =  false;
        $(input).prev().addClass('error');
      } else {
        $(input).prev().removeClass('error');
      }
    });
    
    return all_valid;
  }
  
};