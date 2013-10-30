AWS::CF::Signer.configure do |config|
  config.key_path = '/path/to/keyfile.pem'
  # config.key = ENV.fetch('PRIVATE_KEY') # key_path not required if key supplied directly
  config.key_pair_id  = "XXYYZZ"
  config.default_expires = 3600
end
