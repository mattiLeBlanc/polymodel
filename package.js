Package.describe({
  name: 'leblanc:polymodel',
  version: '0.0.4',
  // Brief, one-line summary of the package.
  summary: 'Simulates the ng-model principal of Angular for Polymer and  HTML5 elements.',
  // URL to the Git repository containing the source code for this package.
  git: 'https://github.com/mattiLeBlanc/polymodel',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.1.0.2');
  api.use('coffeescript');
  api.use('blaze', 'client');
  api.addFiles('polymodel.coffee', 'client');
  api.addFiles('hooks.coffee', 'client');
  api.export('PolyModel', 'client');
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('leblanc:polymodel');
  api.addFiles('polymodel-tests.js');
});
