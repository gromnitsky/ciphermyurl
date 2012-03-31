configure do
  # Databases for production and developer modes
  MyDB.setAdapter(:pstore, file: settings.root + '/db/data.marshall')
  Api.apikeys_load settings.root + '/db/apikeys.yaml'
  
end

configure :production do
  set :haml, ugly: true
end

configure :test do
  set :db_dir, File.dirname(__FILE__).parent + 'test/example/01'
  MyDB.setAdapter(:pstore, file: settings.db_dir + 'data.marshall')
  Api.apikeys_load settings.db_dir + 'apikeys.yaml'
end
