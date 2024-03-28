$(document).ready(function(){
  if (typeof CodeMirror === 'function'){ 
    let codeMirrorConfig = {
      mode: 'css',
      lineNumbers: true,
      lineWrapping: true,
      smartIndent: true,
      matchBrackets: true,
      styleActiveLine: true,
      autoCloseBrackets: true,
      linerWrapping: true,
      lint: true,
      readOnly: false
    };

    let cssEditor;
    $('#event_css_tab').on('shown.bs.tab', function(){
      if (!cssEditor){
        cssEditor = CodeMirror.fromTextArea($('#style_css')[0], codeMirrorConfig);
      }
    });
    
    $('#show_editor_help').on('click', function(){
      $('#editor_help_toast').toast('show');
    });
    function submitCss(){
      cssEditor.options.readOnly = true;
      let btn = $(this);
      btn.attr('disabled', 'disabled');
      $('#saving_progress').show();
      $.post("/save_editor_css", { css_text: cssEditor.doc.getValue() },
        function (data, textStatus, jqXHR) {
          cssEditor.options.readOnly = false;
          btn.removeAttr('disabled');
          $('#saving_progress').hide();
          $('#mobile_preview_iframe').attr('src', $('#mobile_preview_iframe').attr('src'));
          if ($('#mobile_css').length === 0){
            $('#css_tab_heading').after('Uploaded File: <a href="' + data.css_url +'" id="mobile_css" target="_blank">' +
              data.css_filename + '</a><br/>'
            );
          }
        }
      );
    }
    $('#save_css').on('click', function(){
      if ($.trim(cssEditor.doc.getValue()) === '' && window.confirm('Do you want to save blank css?')){
        submitCss();
      } else if ($.trim(cssEditor.doc.getValue()) !== ''){
        submitCss();
      }
    });

    $('#preview_btn').on('click', function(){
      let previewStyleTag = $('#mobile_preview_iframe').contents().find('style#preview_style');
      if (previewStyleTag.length === 0)
        $('#mobile_preview_iframe').contents().find('head').append("<style id='preview_style'></style>")
      $('#mobile_preview_iframe').contents().find('#preview_style')
        .text(cssEditor.doc.getValue());
    });
  }
});