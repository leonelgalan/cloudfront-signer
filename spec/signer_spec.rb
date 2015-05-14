require 'spec_helper'

describe Aws::CF::Signer do
  let(:key_pair_id) { 'APKAIKUROOUNR2BAFUUU' }
  let(:key_path) do
    File.expand_path File.dirname(__FILE__) + "/keys/pk-#{key_pair_id}.pem"
  end
  let(:key) { File.readlines(key_path).join '' }

  context 'configured with key and key_pair_id' do
    before do
      Aws::CF::Signer.configure do |config|
        config.key_pair_id = key_pair_id
        config.key = key
      end
    end

    it 'should be configured' do
      expect(Aws::CF::Signer.is_configured?).to be true
    end

    it 'sets the private_key' do
      expect(Aws::CF::Signer.send(:private_key)).to(
        be_an_instance_of OpenSSL::PKey::RSA
      )
    end

    it 'should expire in one hour by default' do
      url = 'http://somedomain.com/sign me'
      result = Aws::CF::Signer.sign_url(url)
      expect(get_query_value(result, 'Expires').to_i).to(
        eq Time.now.to_i + 3600
      )
    end
  end

  context 'configured with key_path' do
    before(:each) do
      Aws::CF::Signer.configure do |config|
        config.key_path = key_path
      end
    end

    describe 'before default use' do
      it 'should be configured' do
        expect(Aws::CF::Signer.is_configured?).to be true
      end

      it 'sets the private_key' do
        expect(Aws::CF::Signer.send(:private_key)).to(
          be_an_instance_of OpenSSL::PKey::RSA
        )
      end

      it 'should expire urls and paths in one hour by default' do
        expect(Aws::CF::Signer.default_expires).to eq 3600
      end

      it 'should optionally be configured to expire urls and paths' do
        Aws::CF::Signer.default_expires =  600
        expect(Aws::CF::Signer.default_expires).to eq 600
        Aws::CF::Signer.default_expires =  nil
      end
    end

    describe 'when signing a url' do
      it 'should remove spaces from the url' do
        url = 'http://somedomain.com/sign me'
        expect(Aws::CF::Signer.sign_url(url)).not_to match(/\s/)
      end

      it 'should not html encode the signed url by default' do
        url = 'http://somedomain.com/someresource?opt1=one&opt2=two'
        expect(Aws::CF::Signer.sign_url(url)).to match(/\?|=|&/)
      end

      it 'should optionally html encode the signed url' do
        url = 'http://somedomain.com/someresource?opt1=one&opt2=two'
        expect(Aws::CF::Signer.sign_url_safe(url)).not_to match(/\?|=|&/)
      end

      it 'should expire in one hour by default' do
        url = 'http://somedomain.com/sign me'
        result = Aws::CF::Signer.sign_url(url)
        expect(get_query_value(result, 'Expires').to_i).to(
          eq Time.now.to_i + 3600
        )
      end

      it 'should optionally expire in ten minutes' do
        url = 'http://somedomain.com/sign me'
        result = Aws::CF::Signer.sign_url(url, expires: Time.now + 600)
        expect(get_query_value(result, 'Expires').to_i).to(
          eq Time.now.to_i + 600
        )
      end
    end

    describe 'when signing a path' do
      it 'should not remove spaces from the path' do
        path = '/someprefix/sign me'
        expect(Aws::CF::Signer.sign_path(path)).to match(/\s/)
      end
    end
  end
end
