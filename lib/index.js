module.exports = {
  annotate: require('./annotation').annotate,
  Module: require('./module'),
  Injector: require('./injector'),
  factory  : function (fn) {
    fn.$type = 'factory';
    return fn;
  },
  type : function (fn) {
    fn.$type = 'type';
    return fn;
  }
};
