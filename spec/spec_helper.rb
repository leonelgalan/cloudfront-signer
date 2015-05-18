require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'cloudfront-signer'

def get_query_value(url, key)
  query_string = url.slice((url =~ /\?/) + 1..-1)
  pairs = query_string.split('&')
  pairs.each do |item|
    return item.split('=')[1] if item.start_with?(key)
  end
end

RSpec.configure do |_config|

end
