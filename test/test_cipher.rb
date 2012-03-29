require 'stringio'

require_relative 'helper'
require_relative '../lib/ciphermyurl/db'
require_relative '../lib/ciphermyurl/auth'
require_relative '../lib/ciphermyurl/api'

class TestCiphermyurl_1931669932 < MiniTest::Unit::TestCase
  def setup
    # this runs every time before test_*

    cd_to_tests
    CipherMyUrl::Api.apikeys_load 'example/01/apikeys.yaml'
    
    data = 'example/01/data'
    rm_rf data
    CipherMyUrl::MyDB.setAdapter :pstore, file: data
  end

  def test_pack
    
    assert_equal 0, CipherMyUrl::MyDB.getCount

    CipherMyUrl::MyDB.pack 'q w e r t ykjfdskdjfhs', 'a@b.com', 'qaz11111111111'
    assert_equal 1, CipherMyUrl::MyDB.getCount

    CipherMyUrl::MyDB.pack 'asdfghsdfsdfsdf', 'a@b.com', 'wsx22222222222222'
    CipherMyUrl::MyDB.pack 'zxcvbnsdfdffdff', 'a@b.com', 'rfv333333333333'
    assert_equal 3, CipherMyUrl::MyDB.getCount

    assert_equal({
                   data: 'asdfghsdfsdfsdf',
                   user: 'a@b.com', 
                   pwhash: '8b73016783258b9c87390d9c5a676324'
                 }, CipherMyUrl::MyDB['2'])

    assert_raises(RuntimeError) {
      CipherMyUrl::MyDB.pack 'zxcvbnsdfdffdff', 'a@b.com', 'qwe'
    }
    
  end

  def test_uri
    assert_equal false, CipherMyUrl::Data.valid_uri?('123')
    assert_equal true, CipherMyUrl::Data.valid_uri?('http://localhost?q=qwq&=323')
  end
  
  def test_clean
    assert_raises(RuntimeError) { CipherMyUrl::Data.clean nil }
    assert_raises(RuntimeError) { CipherMyUrl::Data.clean '' }
    assert_equal 'http://localhost?q=qwq&=323', CipherMyUrl::Data.clean('  http://localhost?q=qwq&=323')
    assert_equal "&lt;script&gt;alert(&quot;I'm evil!&quot;);&lt;/script&gt;", CipherMyUrl::Data.clean('<script>alert("I\'m evil!");</script>')
  end

  def test_pw
    assert_raises(RuntimeError) { CipherMyUrl::Data.valid_pw?(nil) }
    assert_raises(RuntimeError) { CipherMyUrl::Data.valid_pw?('') }
    assert_raises(RuntimeError) { CipherMyUrl::Data.valid_pw?('toosh') }
    CipherMyUrl::Data.valid_pw?('qqqqqqqqqqqqq')
  end

  def test_auth
    assert_equal 'john.doe@example.com', CipherMyUrl::Api.getBrowserUser[:email]
    assert_equal CipherMyUrl::Api::BROWSER_USER_PUBLIC, CipherMyUrl::Api.apikeys_findBy('john.doe@example.com')
    assert_equal 'john.doe@example.com', CipherMyUrl::Api.apikeys_findBy(CipherMyUrl::Api::BROWSER_USER_PUBLIC)
    assert_equal nil, CipherMyUrl::Api.apikeys_findBy('q@b.com')
  end

  def test_api_pack
    CipherMyUrl::MyDB.pack 'asdfghsdfsdfsdf', 'a@b.com', 'wsx22222222222222'
    CipherMyUrl::MyDB.pack 'zxcvbnsdfdffdff', 'a@b.com', 'rfv333333333333'
    
    sio = StringIO.new '{}'
    assert_raises(CipherMyUrl::ApiBadRequestError) {
      CipherMyUrl::Api.packRequestRead sio
    }
    sio = StringIO.new '{q: 1}'
    assert_raises(CipherMyUrl::ApiBadRequestError) {
      CipherMyUrl::Api.packRequestRead sio
    }
    sio = StringIO.new '{"data": 1, "pw": 2, "keyshash": 3}'
    assert_raises(CipherMyUrl::ApiUnauthorizedError) {
      CipherMyUrl::Api.packRequestRead sio
    }

    sio = StringIO.new '{"data": 1, "pw": 2, "keyshash": "%s"}' % [CipherMyUrl::Api::BROWSER_USER_KEYSHASH]
    e = assert_raises(RuntimeError) {
      CipherMyUrl::Api.pack CipherMyUrl::Api.packRequestRead(sio)
    }
    assert_match /password length/, e.message

    sio = StringIO.new '{"data": 1, "pw": 12345678, "keyshash": "%s"}' % [CipherMyUrl::Api::BROWSER_USER_KEYSHASH]
    e = assert_raises(RuntimeError) {
      CipherMyUrl::Api.pack CipherMyUrl::Api.packRequestRead(sio)
    }
    assert_match /data must be in range/, e.message
    
    sio = StringIO.new '{"data": 12345678912, "pw": 12345678, "keyshash": "%s"}' % [CipherMyUrl::Api::BROWSER_USER_KEYSHASH]
    CipherMyUrl::Api.pack CipherMyUrl::Api.packRequestRead(sio)
  end
end
