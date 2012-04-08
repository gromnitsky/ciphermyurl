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

    CipherMyUrl::MyDB.pack 'some random text', 'john.doe@example.com', 'mystrongpassword'
  end

  def test_api_unpack
    get "/api/#{Api::VERSION}/unpack?slot=1&pw=mystrongpassword"
    assert last_response.ok?
    assert_equal 'some random text', last_response.body
  end

  def test_api_pack
    j = { "data" => 12345678912, "pw" => 12345678,
      "kpublic" => CipherMyUrl::Auth::BROWSER_USER_PUBLIC,
      "kprivate" => CipherMyUrl::Auth::BROWSER_USER_PRIVATE }.to_json
    
    post "/api/#{Api::VERSION}/pack", j
    assert_equal 201, last_response.status
    assert_equal '2', last_response.body
  end

  def test_b_pack_ok
    Rack::Recaptcha.test_mode! :return => true
    post '/b/pack', {
      'data' => 'some+other+text',
      'pw' => '12345678'
    }

#    pp last_response
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
    
#    pp last_request.env['rack.session']
#    pp last_response.body
    assert_match last_request.env['rack.session']['halt'], /data must be in range/
    assert last_response.ok?

    
    post '/b/pack', nil
    follow_redirect!
#    pp last_request
    assert_match /data must be in range/, last_request.env['rack.session']['halt']
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

  def test_del
    delete "/api/#{Api::VERSION}/del?slot=1&pw=bogus"
    assert_equal 403, last_response.status
    assert_equal "invalid password", last_response.header[HDR_ERROR]

    # delete method must behave like idempotent
    2.times {
      delete "/api/#{Api::VERSION}/del?slot=1&pw=mystrongpassword"
 #     pp last_response
      assert last_response.ok?
    }

    get "/api/#{Api::VERSION}/unpack?slot=1&pw=mystrongpassword"
    assert_equal 404, last_response.status
    assert_equal "no such slot", last_response.header[HDR_ERROR]
  end
end
