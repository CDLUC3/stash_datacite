// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(document).ready(function(){
  $( "#title" ).on('blur', function(e){
    alert("hello");
    var form =  $("#title").parents('form');
    $(form).trigger('submit.rails');
  });
});