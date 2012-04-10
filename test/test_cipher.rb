require 'stringio'

require_relative 'helper'
require_relative '../lib/ciphermyurl/db'
require_relative '../lib/ciphermyurl/auth'
require_relative '../lib/ciphermyurl/api'
require_relative '../lib/ciphermyurl/options'

class TestCiphermyurl_1931669932 < MiniTest::Unit::TestCase
  def setup
    # this runs every time before test_*

    cd_to_tests
    CipherMyUrl::Api.apikeys_load 'example/01/apikeys.yaml'
    
    data = 'example/01/data'
    rm_rf data
    CipherMyUrl::MyDB.setAdapter :pstore, file: data

    @opt = CipherMyUrl::Options.load
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
                   pwhash: '75b3412a5ac9d403ce34889c4ce4033ace7c3c5e6526d84e241367153e0d2d5a'
                 }, CipherMyUrl::MyDB['2'])

    assert_raises(RuntimeError) {
      CipherMyUrl::MyDB.pack 'zxcvbnsdfdffdff', 'a@b.com', 'qwe'
    }
    
  end

  def test_del
    CipherMyUrl::MyDB.pack 'asdfghsdfsdfsdf', 'a@b.com', 'wsx22222222222222'
    assert_equal({
                   data: 'asdfghsdfsdfsdf',
                   user: 'a@b.com', 
                   pwhash: '75b3412a5ac9d403ce34889c4ce4033ace7c3c5e6526d84e241367153e0d2d5a'
                 }, CipherMyUrl::MyDB['1'])
    
    assert_raises(RuntimeError) { CipherMyUrl::MyDB.del nil }
    CipherMyUrl::MyDB.del 1
    assert_equal nil, CipherMyUrl::MyDB[1]
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
    assert_equal 'john.doe@example.com', CipherMyUrl::Api.authenticated?(@opt[:webclient][:kpublic], @opt[:webclient][:kprivate])[:email]
    
    assert_equal @opt[:webclient][:kpublic], CipherMyUrl::Api.kpublic_findBy('john.doe@example.com')
    assert_equal @opt[:webclient][:kpublic], CipherMyUrl::Api.kpublic_findBy(CipherMyUrl::Auth.keyshash(@opt[:webclient][:kpublic], @opt[:webclient][:kprivate]))
    assert_equal nil, CipherMyUrl::Api.kpublic_findBy('q@b.com')
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
    sio = StringIO.new '{"data": 1, "pw": 2, "kpublic": 3, "kprivate": 4}'
    assert_raises(CipherMyUrl::ApiUnauthorizedError) {
      CipherMyUrl::Api.packRequestRead sio
    }

    sio = StringIO.new({ "data" => 1, "pw" => 2,
                         "kpublic" => @opt[:webclient][:kpublic],
                         "kprivate" => @opt[:webclient][:kprivate] }.to_json)
    e = assert_raises(RuntimeError) {
      CipherMyUrl::Api.pack CipherMyUrl::Api.packRequestRead(sio)
    }
    assert_match /password length/, e.message

    sio = StringIO.new({ "data" => 1, "pw" => 12345678,
                         "kpublic" => @opt[:webclient][:kpublic],
                         "kprivate" => @opt[:webclient][:kprivate] }.to_json)
    e = assert_raises(RuntimeError) {
      CipherMyUrl::Api.pack CipherMyUrl::Api.packRequestRead(sio)
    }
    assert_match /data must be in range/, e.message

    sio = StringIO.new({ "data" => 12345678912, "pw" => 12345678,
                         "kpublic" => @opt[:webclient][:kpublic],
                         "kprivate" => @opt[:webclient][:kprivate] }.to_json)
    CipherMyUrl::Api.pack CipherMyUrl::Api.packRequestRead(sio)
  end

  def test_api_unpack
    CipherMyUrl::MyDB.pack 'asdfghsdfsdfsdf', 'a@b.com', 'wsx22222222222222'
    CipherMyUrl::MyDB.pack 'zxcvbnsdfdffdff', 'a@b.com', 'rfv333333333333'

    assert_raises(CipherMyUrl::ApiBadRequestError) {
      CipherMyUrl::Api.unpackRequestRead nil
    }
    assert_raises(CipherMyUrl::ApiBadRequestError) {
      CipherMyUrl::Api.unpack nil
    }
    assert_raises(CipherMyUrl::ApiInvalidSlotError) {
      CipherMyUrl::Api.unpack({slot: '0', pw: '2'})
    }
    assert_raises(CipherMyUrl::ApiUnauthorizedError) {
      CipherMyUrl::Api.unpack({slot: '1', pw: '2'})
    }
    assert_equal 'asdfghsdfsdfsdf', CipherMyUrl::Api.unpack({slot: '1', pw: 'wsx22222222222222'})
  end

  def test_api_delete
    CipherMyUrl::MyDB.pack 'asdfghsdfsdfsdf', 'john.doe@example.com', 'wsx22222222222222'
    CipherMyUrl::MyDB.pack 'zxcvbnsdfdffdff', 'john.doe@example.com', 'rfv333333333333'
    
    assert_raises(CipherMyUrl::ApiBadRequestError) {
      CipherMyUrl::Api.delRequestRead nil
    }
    assert_raises(CipherMyUrl::ApiBadRequestError) {
      CipherMyUrl::Api.del nil
    }

    CipherMyUrl::Api.del({slot: '1', pw: 'wsx22222222222222'})
    assert_raises(CipherMyUrl::ApiInvalidSlotError) {
      CipherMyUrl::Api.unpack({slot: '1', pw: 'wsx22222222222222'})
    }
   end
  
end
