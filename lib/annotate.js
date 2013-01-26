var annotate = function(vargs) {
  var args = Array.prototype.slice.call(arguments);
  var fn = args.pop();

  fn.$inject = args;

  return fn;
};


module.exports = annotate;
