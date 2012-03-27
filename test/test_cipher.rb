require_relative 'helper'

require_relative '../lib/ciphermyurl/db'
require_relative '../lib/ciphermyurl/auth'

class TestCiphermyurl_1931669932 < MiniTest::Unit::TestCase
  def setup
    # this runs every time before test_*

    cd_to_tests
  end

  def test_pack
    data = 'example/01/data'
    rm_rf data
    CipherMyUrl::MyDB.setAdapter :pstore, file: data
    
    assert_equal 0, CipherMyUrl::MyDB.getCount

    CipherMyUrl::MyDB.pack 'q w e r t ykjfdskdjfhs', 'qaz11111111111'
    assert_equal 1, CipherMyUrl::MyDB.getCount

    CipherMyUrl::MyDB.pack 'asdfghsdfsdfsdf', 'wsx22222222222222'
    CipherMyUrl::MyDB.pack 'zxcvbnsdfdffdff', 'rfv333333333333'
    assert_equal 3, CipherMyUrl::MyDB.getCount

    assert_equal({
                   data: 'asdfghsdfsdfsdf',
                   pw: 'wsx22222222222222'
                 }, CipherMyUrl::MyDB['2'])
    
  end

  def test_uri
    assert_equal false, CipherMyUrl::Data.valid_uri?('123')
    assert_equal true, CipherMyUrl::Data.valid_uri?('http://localhost?q=qwq&=323')
  end
  
  def test_clean
    assert_raises(RuntimeError) { CipherMyUrl::Data.clean '' }
    assert_equal 'http://localhost?q=qwq&=323', CipherMyUrl::Data.clean('  http://localhost?q=qwq&=323')
    assert_equal "&lt;script&gt;alert(&quot;I'm evil!&quot;);&lt;/script&gt;", CipherMyUrl::Data.clean('<script>alert("I\'m evil!");</script>')
  end

  def test_pw
    assert_equal false, CipherMyUrl::Data.valid_pw?(nil)
    assert_equal false, CipherMyUrl::Data.valid_pw?('')
    assert_equal false, CipherMyUrl::Data.valid_pw?('toosh')
    assert_equal true, CipherMyUrl::Data.valid_pw?('qqqqqqqqqqqqq')
  end

  include CipherMyUrl::Auth
  def test_auth
    apikeys_load 'example/01/apikeys.yaml'
    assert_equal 'john.doe@example.com', getBrowserUser[:email]
    assert_equal BROWSER_USER_PUBLIC, apikeys_findBy('john.doe@example.com')
    assert_equal 'john.doe@example.com', apikeys_findBy(BROWSER_USER_PUBLIC)
    assert_equal nil, apikeys_findBy('q@b.com')
  end
end
