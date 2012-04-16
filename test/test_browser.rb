require 'selenium-webdriver'

require_relative 'helper'

class FuckMyLife
  class Unit < MiniTest::Unit

    def before_suites
      # code to run before the first test
    end

    def after_suites
      # code to run after the last test
    end

    def _run_suites(suites, type)
      begin
        before_suites
        super(suites, type)
      ensure
        after_suites
      end
    end

    def _run_suite(suite, type)
      begin
        suite.before_suite if suite.respond_to?(:before_suite)
        super(suite, type)
      ensure
        suite.after_suite if suite.respond_to?(:after_suite)
      end
    end

  end
end

MiniTest::Unit.runner = FuckMyLife::Unit.new

def localInit
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile.proxy = Selenium::WebDriver::Proxy.new(http: nil)
  profile.native_events = true
  
  Selenium::WebDriver.for :firefox, profile: profile
end

def makeurl host, port, path
  "http://#{host}:#{port}#{path}"
end
  

class TestBrowser < MiniTest::Unit::TestCase
  def self.before_suite
    @@d = localInit
  end

  def self.after_suite
    @@d.quit
  end
  
  def setup
    @host = '127.0.0.1'
    @port = 9393
  end

  def navigate host, port, path
    @@d.get makeurl(host, port, path)
  end

  def test_pack
    navigate @host, @port, '/'
    #element = driver.find_element :name => "q"
    #element.send_keys "Cheese!"
    #element.submit

    assert_equal "#{CipherMyUrl::Meta::NAME} :: Pack", @@d.title

    #wait = Selenium::WebDriver::Wait.new(:timeout => 10)
    #wait.until { driver.title.downcase.start_with? "cheese!" }
    
    #puts "Page title is #{d.title}"
    
    #d.quit
  end

  def test_unpack
    navigate @host, @port, '/1'
    assert_equal "#{CipherMyUrl::Meta::NAME} :: Unpack", @@d.title
  end
end

