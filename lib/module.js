var Module = function() {
  var providers = [];

  this.factory = function(name, factory) {
    providers.push([name, 'factory', factory]);
  };

  this.value = function(name, value) {
    providers.push([name, 'value', value]);
  };

  this.type = function(name, type) {
    providers.push([name, 'type', type]);
  };

  this.forEach = function(iterator) {
    providers.forEach(iterator);
  };
};

module.exports = Module;
