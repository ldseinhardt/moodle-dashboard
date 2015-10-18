(function(chrome, $, mdash, graph) {
  "use strict";
  
  chrome.storage.local.get({
    data: "",
    sync: false
  }, function(items) {
    if (items.sync && items.data !== "") {
      //Chama a visualização da tela apropriada
      console.log("listOfActions");
      var listOfActions = mdash.listOfActions(items.data);
      console.log(listOfActions);
      
      console.log("listOfUsers");
      var listOfUsers = mdash.listOfUsers(items.data);
      console.log(listOfUsers);
      
      graph
        .Bubble({
          data: listOfActions,
          context: "#content",
          diameter: 430
        })
        .Bar({
          data: listOfUsers,
          context: "#content",
          width: 430
        });
    
    }
  });
})(this.chrome, this.jQuery, this.mdash, this.graph);