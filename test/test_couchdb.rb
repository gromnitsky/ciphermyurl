require 'stringio'

require_relative 'helper'
gem 'multi_json', '~> 1.0.0'
require_relative '../lib/ciphermyurl/db'

include CipherMyUrl

class TestCouchDB < MiniTest::Unit::TestCase
  def db_connect
    MyDB.setAdapter(:couchdb, {
                      login: 'admin',
                      pw: 'qwerty',
                      tls: false,
                      host: '127.0.0.1',
                      port: 5984,
                      dbname: 'ciphermyurl-test'
                    })
  end
  
  def setup
    # this runs every time before test_*
    
    cd_to_tests
    
    # connect to know how to remove
    db_connect
    MyDB.rmdb

    # create new
    db_connect
  end

  def test_pack
    assert_equal 0, MyDB.getCount

    MyDB.pack 'once upon a time', 'a@b.com', 'justmypassword'
    assert_equal 1, MyDB.getCount

    MyDB.pack 'in a distant galaxy', 'a@b.com', '12345678'
    MyDB.pack 'called OOc, there lived', 'c@d.com', '87654321'
    assert_equal 3, MyDB.getCount

    r = MyDB['2']
    assert_equal 'in a distant galaxy', r[:data]
    assert_equal 'a@b.com', r[:user]
    assert_equal 'ed950a434f4cd3ec79a81ae722a8e4b85877769e29e490b92821216893cb0f06', r[:pwhash]
    assert_match /^\d+$/, r[:created].to_s
    assert_equal 4, r.size

    assert_raises(RuntimeError) {
      MyDB.pack 'a computer named R.J. Drofnats.', 'a@b.com', 'small'
    }
  end

  def test_del
    MyDB.pack 'asdfghsdfsdfsdf', 'a@b.com', 'wsx22222222222222'
    MyDB.pack 'qwertyasdfghzxcvbn', 'z@x.com', '12345678'
    r = MyDB['1']
    assert_equal 'asdfghsdfsdfsdf', r[:data]
    assert_equal 'a@b.com', r[:user]
    assert_equal '75b3412a5ac9d403ce34889c4ce4033ace7c3c5e6526d84e241367153e0d2d5a', r[:pwhash]
    assert_match /^\d+$/, r[:created].to_s
    assert_equal 4, r.size
    
    assert_raises(RuntimeError) { MyDB.del nil }
    MyDB.del 1
    assert_equal nil, MyDB['1']
  end
end
