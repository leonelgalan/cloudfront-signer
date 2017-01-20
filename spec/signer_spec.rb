require 'spec_helper'

RSpec.shared_examples 'is configured' do
  it 'is configured' do
    expect(Aws::CF::Signer.is_configured?).to be true
  end

  it 'sets the private_key' do
    expect(Aws::CF::Signer.send(:private_key)).to(
      be_an_instance_of(OpenSSL::PKey::RSA)
    )
  end
end

RSpec.describe Aws::CF::Signer do
  let(:key_pair_id) { 'APKAIKUROOUNR2BAFUUU' }
  let(:key_path) do
    File.expand_path File.dirname(__FILE__) + "/keys/pk-#{key_pair_id}.pem"
  end
  let(:key) { File.readlines(key_path).join '' }

  describe 'defaults' do
    it 'expire urls and paths in one hour by default' do
      expect(Aws::CF::Signer.default_expires).to eq 3600
    end

    it 'expires when specified' do
      Aws::CF::Signer.default_expires = 600
      expect(Aws::CF::Signer.default_expires).to eq 600
      Aws::CF::Signer.default_expires = nil
    end
  end

  context 'configured with key and key_pair_id' do
    before do
      Aws::CF::Signer.configure do |config|
        config.key_pair_id = key_pair_id
        config.key = key
      end
    end

    include_examples 'is configured'
  end

  context 'configured with key_path' do
    before(:each) do
      Aws::CF::Signer.configure { |config| config.key_path = key_path }
    end

    describe 'before default use' do
      include_examples 'is configured'
    end

    describe 'when signing a url' do
      it "doesn't modifies the passed url" do
        url = 'http://somedomain.com/sign'.freeze
        expect(Aws::CF::Signer.sign_url(url)).not_to match(/\s/)
      end

      it 'removes spaces' do
        url = 'http://somedomain.com/sign me'
        expect(Aws::CF::Signer.sign_url(url)).not_to match(/\s/)
      end

      it "doesn't HTML encode the signed url by default" do
        url = 'http://somedomain.com/someresource?opt1=one&opt2=two'
        expect(Aws::CF::Signer.sign_url(url)).to match(/\?|=|&/)
      end

      it 'HTML encodes the signed url when using sign_url_safe' do
        url = 'http://somedomain.com/someresource?opt1=one&opt2=two'
        expect(Aws::CF::Signer.sign_url_safe(url)).not_to match(/\?|=|&/)
      end

      it 'expires when specified inline' do
        url = 'http://somedomain.com/sign'
        signed_url = Aws::CF::Signer.sign_url(url, expires: Time.now + 600)
        expires_value = get_query_value(signed_url, 'Expires').to_i
        expect(expires_value).to eq(Time.now.to_i + 600)
      end
    end

    describe 'when signing a path' do
      it "doesn't remove spaces" do
        path = '/prefix/sign me'
        expect(Aws::CF::Signer.sign_path(path)).to match(/\s/)
      end
    end
  end
end
