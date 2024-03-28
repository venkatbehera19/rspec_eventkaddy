$(document).ready(function() {
  $(".profile-pic-file").on("change", function() {
    if (this.files && this.files[0]){
      let reader = new FileReader();
  
      reader.onload = function(e){
        $(".profile-pic").attr('src', e.target.result);
      }
      reader.readAsDataURL(this.files[0]);
    }
  });
});