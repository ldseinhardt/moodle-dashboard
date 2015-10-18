(function(chrome, $, mdash, graph) {
  "use strict";
  
  chrome.storage.local.get({
    moodle_data: "",
    moodle_sync: false
  }, function(items) {
    if (items.moodle_sync && items.moodle_data !== "") {
      //Chama a visualização da tela apropriada
      console.log("listOfActions");
      var listOfActions = mdash.listOfActions(items.moodle_data);
      console.log(listOfActions);
      
      console.log("listOfUsers");
      var listOfUsers = mdash.listOfUsers(items.moodle_data);
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