# This file is loaded by the application at start-up.

configure do
  set :logging, nil
  $log.level = Logger::INFO

  # http://www.google.com/recaptcha/whyrecaptcha
  set :recaptcha_public_key, $opt[:recaptcha][:kpublic]
  set :recaptcha_private_key, $opt[:recaptcha][:kprivate]
end

configure :production, :development do
  # databases
  begin
    if $opt[:dbadapter] == :pstore
      $opt[:db][:pstore][:params][:file] = settings.root + '/db/data.marshall'
    end
    MyDB.setAdapter $opt[:dbadapter], $opt[:db][$opt[:dbadapter]][:params]
    Api.apikeys_load
  rescue
    fail "DB connection problem: #{$!}"
  end
end

configure :development do
  $log.level = Logger::DEBUG
  
  # Ignore captcha
  Rack::Recaptcha.test_mode! :return => true

  # Captcha do not displayed if true
  set :debug, true
end

configure :production do
  set :haml, ugly: true
end

### For :test config, see test/helpers.rb ###
