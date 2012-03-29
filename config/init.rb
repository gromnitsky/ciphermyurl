MyDB.setAdapter(:pstore,
                file: Pathname.new(File.dirname(__FILE__)).parent + 'db/data.marshall')

Api.apikeys_load Pathname.new(File.dirname(__FILE__)).parent + 'db/apikeys.yaml'
