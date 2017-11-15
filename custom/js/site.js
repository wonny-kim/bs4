/*
    site initial function
*/
var cookies = {
  group: new Cookie(),
  page: new Cookie()
};

function init(group,page,is_ajax) {
  var page = page || 'index';
  var is_ajax = (typeof is_ajax !== 'undefined')?is_ajax:true;

  var host = $(location).attr('hostname');
  var cgroup = cookies.group.getCookie("group");
  var cpage = cookies.page.getCookie("page");
  // nav & menu active
  $('#topmenu-content #nav-'+cgroup+' a').removeClass('active');
  $('#topmenu-content #nav-'+group+' a').addClass('active');

  if(!is_ajax) {
    /*
        init function is not ajax
    */
    // add popover
    $('[data-toggle="popover"]').popover({html:true,trigger:"click",container:"body", placement:"auto"});
    // add tooltip
    $('[data-toggle="tooltip"]').tooltip({container:"body", placement:"auto"});
    // custom-file-iput
    $("input.custom-file-input").change(function() {
      var path = $(this).val().split('\\');
      var name = (path.length > 0)?path[path.length-1]:'';
      $(this).parent().find("span.custom-file-control").html(name);
    });
  }
  else {
    /*
        init function is ajax
    */
    if(cgroup !== group) {
      show_html("sidemenu",group);
      var History = window.History;
      var pageUrl = "http://"+host+"/"+group+".php";
      if(History.enabled) {
        History.pushState({_index: History.getCurrentIndex(), path:pageUrl},"타이틀",pageUrl);
      }
      else {
        return false;
      }
    }
    // nav & menu active
    $('#sidemenu-content #nav-'+cpage).removeClass('active');
    $('#sidemenu-content #nav-'+page).addClass('active');

    show_html("main",group,page);
    show_html("modal",group,page);

  }


  cookies.group.setCookie("group",group, {"expire_hour":1});
  cookies.page.setCookie("page",page, {"expire_hour":1});

  /* each page action */
  switch(group) {
    case "":
    case "index":
      // add modal initial input value
      $('#modalLogin').on('show.bs.modal',function(event) {
        var button = $(event.relatedTarget);
        var temp = button.data('tempid');
        $(this).find('.modal-body input#USERID').val(temp);
      });
    break;
    case "components":
      if(page === '') {
      }
      else if(page === "table") {
        // add modal button active
        $('#modalInput').on("show.bs.modal",function(event) {
          var button = $(event.relatedTarget);
          var cmd = button.data('cmd');

          if(cmd == 'write') {
            // write new article, reset all input values
            $(this).find(':text,:password').val('');
            $(this).find(':checkbox,:radio').parent().filter('.btn').button('toggle');
            $(this).find(':checked').prop('checked',false);
          }
          else {
            var idx = button.data('idx');
            // ajax (request data)
            $.ajax({
              url: "./process/members_ajax.php",
              type: "POST",
              dataType: "json",
              data: {"idx" : idx },
              success: function(data) {
                /*  json style
                *   [{"type": input_type,"name": input_name,"value":input_value},...]
                */
                data.forEach(function(val) {
                  switch (val.type) {
                    case "text" :
                    break;
                    case "radio" :
                    break;
                    case "checkbox" :
                    break;
                    case "select" :
                    break;
                    case "textarea" :
                    break;
                  }
                })
              },
              error: function(jqXHR, textStatus, errorThrown) {
                console.log(textStatus);
              }
          });
        }});
      }
      else if(page === "carousel") {
        $('#carousel-1').carousel(2);
      }

    break;
  }
}

/* site function */
function show_html(type, group, page) {
  page = page || '';
  switch(type) {
    case "sidemenu":
    file = {"type": type, "group": group};
    break;
    default :
    file = {"type": type, "group": group, "page": page};
    break;
  }

  $.ajax({
    url: "/process/page_ajax.php",
    type: "POST",
    data: file,
    dataType: "html",
    success: function(result) {
      /*  json style
      *   [{"type": input_type,"name": input_name,"value":input_value},...]
      */
      $('#'+type+'-content').html($(result).filter('#result-content').html());
      //$('#'+type+'-content').html(result);
    },
    beforeSend:function() {
      $(".loader").css("display","block");
    },
    complete: function() {
      if(type !== "main") {
        $(".loader").css("display","none");
        Holder.addTheme(
          "dark",
          {
            bg: "black",
            fg: "white",
            size: 8
          }
        ).run();
        if(page === "carousel") {
          $('#carousel-1').carousel({interval: 1000, ride: "carousel"});
          $('#carousel-2').carousel({interval: 2000, ride: "carousel-fade"});
        }

        // add popover
        $('[data-toggle="popover"]').popover({html:true,trigger:"click",container:"body", placement:"auto"});
        // add tooltip
        $('[data-toggle="tooltip"]').tooltip({container:"body", placement:"auto"});
        //add scroll-spy
        var t_scroll_spy = $('[data-spy="scroll"]');
        t_scroll_spy.scrollspy({ target: '#'+t_scroll_spy.siblings('nav').prop('id') });

        // custom-file-iput
        $("input.custom-file-input").change(function() {
          var path = $(this).val().split('\\');
          var name = (path.length > 0)?path[path.length-1]:'';
          $(this).parent().find("span.custom-file-control").html(name);
        });
      }
    },
    error: function(e) {
      if(type ==="main") {
        alert_msg($('#'+type+'-content'),"","I'm sorry!!","Page <mark>"+page+"</mark> is Under construction!","Page <mark>"+page+"</mark> is Under construction!");
      }
    },
    timeout:100000
  });
}
