AWS::CF::Signer.configure do |config|
  config.key_path = '/path/to/keyfile.pem'
  config.key_pair_id  = "XXYYZZ"
  config.default_expires = 3600
end
