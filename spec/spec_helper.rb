$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'cloudfront-signer'

def get_query_value(url, key)
  query_string = url.slice((url =~ /\?/) + 1..-1) 
  pairs = query_string.split('&')
  pairs.each do |item|
    if item.start_with?(key)
      return item.split('=')[1]
    end
  end
end


RSpec.configure do |config|

end
