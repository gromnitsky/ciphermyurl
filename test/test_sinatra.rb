require 'rack/test'

require_relative '../app'

require_relative 'helper'

class TestCiphermyurl_4121749810 < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
  
  def setup
    # this runs every time before test_*

    cd_to_tests
    CipherMyUrl::Api.apikeys_load 'example/01/apikeys.yaml'
    
    data = 'example/01/data'
    rm_rf data
    CipherMyUrl::MyDB.setAdapter :pstore, file: data

    CipherMyUrl::MyDB.pack 'some random text', 'q@example.com', 'mystrongpassword'
  end

  def test_api_unpack
    get "/api/#{Api::VERSION}/unpack?slot=1&pw=mystrongpassword"
    assert last_response.ok?
    assert_equal 'some random text', last_response.body
  end

  def test_api_pack
    post "/api/#{Api::VERSION}/pack", '{"data": 12345678912, "pw": 12345678, "keyshash": "%s"}' % [Api::BROWSER_USER_KEYSHASH]
    assert last_response.ok?
    assert_equal '2', last_response.body
  end

  def test_b_pack_ok
    Rack::Recaptcha.test_mode! :return => true
    post '/b/pack', {
      'data' => 'some+other+text',
      'pw' => '12345678'
    }
    
    assert last_response.ok?
    assert_match last_response.body, /your data was successfully added/
  end

  def test_b_pack_fail
    Rack::Recaptcha.test_mode! :return => true
    post '/b/pack', {
      'data' => 'some',
      'pw' => '12345678'
    }
    follow_redirect!
    
#    pp last_request.env['rack.session']['halt']
    assert_match last_request.env['rack.session']['halt'], /data must be in range/
    assert last_response.ok?

    
    post '/b/pack', nil
    follow_redirect!
    assert_equal "validation of JSON failed", last_request.env['rack.session']['halt']
    assert last_response.ok?
  end

  def test_b_captch_fail
    Rack::Recaptcha.test_mode! :return => false
    post '/b/pack', {
      'data' => 'qwertyuiopasdfghjkl',
      'pw' => '12345678'
    }
    follow_redirect!
    
    assert_equal "captcha validation failed", last_request.env['x-rack.flash'][:error]
    assert last_response.ok?
  end
  
end
