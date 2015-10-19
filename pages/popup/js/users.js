(function(chrome, $, mdash, graph) {
  "use strict";
  
  chrome.storage.local.get({
    data: "",
    sync: false
  }, function(items) {
    if (items.sync && items.data !== "") {
      //Chama a visualização da tela apropriada
      console.log("listOfUsers");
      var listOfUsers = mdash.listOfUsers(items.data);
      console.log(listOfUsers);
      
      $(".mdl-card__title-text", "#card-graph").html("Usuários e interações");
      $("#card-graph > .mdl-card__supporting-text").html();

      graph.Bar({
        data: listOfUsers,
        context: "#card-graph > .mdl-card__supporting-text",
        width: 400
      });

      $("#card-graph").show();
    }
  });
})(this.chrome, this.jQuery, this.mdash, this.graph);