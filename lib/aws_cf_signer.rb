# A re-write of https://github.com/stlondemand/aws_cf_signer
#
require 'openssl'
require 'time'
require 'base64'

module AWS
  module CloudFront
    class Signer

      # Public non-inheritable class accessors
      #----------------------------------------------------------------------------
      class << self
        attr_accessor :key_pair_id

        def key_path
          @key_path
        end

        def key_path=(path)
          raise ArgumentError.new("The signing key could not be found at #{path}") unless File.exists?(path)
          @key_path = path
          @key = OpenSSL::PKey::RSA.new(File.readlines(path).join(""))
        end

        def html_escape
          @html_escape = true if @html_escape.nil? 
          @html_escape
        end

        def html_escape=(value)
          @html_escape = value
        end

        def default_expires
          @default_expires ||= Time.now + 3600 #Expires in 1 hour 
        end

        # Private key
        #----------------------------------------------------------------------------
        def private_key
          @key
        end
      end

      #----------------------------------------------------------------------------
      def self.is_configured?
        if self.key_path && self.key_pair_id && private_key
          return true
        else
          return false
        end 
      end


      # Configure the signing class. 
      #----------------------------------------------------------------------------
      def self.configure!(key_path, options = {})
        raise ArgumentError.new("You must supply the path to a PKCS#12 format private RSA key.") if key_path.nil?
        self.key_path = key_path

        @default_expires = options[:default_expires] unless options[:default_expires].nil?
        self.html_escape = options[:html_escape] unless options[:html_escape].nil?

        @key_pair_id = options[:key_pair_id] || extract_key_pair_id(key_path)
        unless @key_pair_id
          raise ArgumentError.new("The Cloudfront signing key id could not be inferred from #{key_path}. Please supply the key pair id as a configuration arguemet.")
        end

      end

      # Sign a subject url or stream resource name
      #----------------------------------------------------------------------------
      def self.sign(subject, policy_options = {})

        raise "Configure using AWS::CloudFront.Singer.configure! before signing." unless self.is_configured?

        # If the url or stream path already has a query string parameter - append to that.
        separator = subject =~ /\?/ ? '&' : '?'

        if policy_options[:policy_file]
          policy = IO.read(policy_options[:policy_file])
          result = "#{subject}#{separator}Policy=#{encode_policy(policy)}&Signature=#{create_signature(policy)}&Key-Pair-Id=#{@key_pair_id}"
        else
          if policy_options.keys.size <= 1
            # Canned Policy - shorter URL
            expires_at = epoch_time(policy_options[:expires] || self.default_expires)
            policy = %({"Statement":[{"Resource":"#{subject}","Condition":{"DateLessThan":{"AWS:EpochTime":#{expires_at}}}}]})
            result = "#{subject}#{separator}Expires=#{expires_at}&Signature=#{create_signature(policy)}&Key-Pair-Id=#{@key_pair_id}"
          else
            # Custom Policy
            resource = policy_options[:resource] || subject
            policy = generate_custom_policy(resource, policy_options)
            result = "#{subject}#{separator}Policy=#{encode_policy(policy)}&Signature=#{create_signature(policy)}&Key-Pair-Id=#{@key_pair_id}"
          end
        end

        if @html_escape
          return html_encode(result)    
        else
          return result
        end
      end



      # Private helper methods
      #----------------------------------------------------------------------------
      private


      #----------------------------------------------------------------------------
      def self.generate_custom_policy(resource, options)
        conditions = ["\"DateLessThan\":{\"AWS:EpochTime\":#{epoch_time(options[:expires])}}"]
        conditions << "\"DateGreaterThan\":{\"AWS:EpochTime\":#{epoch_time(options[:starting])}}" if options[:starting]
        conditions << "\"IpAddress\":{\"AWS:SourceIp\":\"#{options[:ip_range]}\"" if options[:ip_range]
                %({"Statement":[{"Resource":"#{resource}","Condition":{#{conditions.join(',')}}}}]})
      end

      #----------------------------------------------------------------------------
      def self.epoch_time(timelike)
        case timelike
        when String then Time.parse(timelike).to_i
        when Time   then timelike.to_i
        else raise ArgumentError.new("Invalid argument - String or Time required - #{timelike.class} passed.")
        end
      end

      #----------------------------------------------------------------------------
      def self.encode_policy(policy)
        url_encode(Base64.encode64(policy))
      end

      #----------------------------------------------------------------------------
      def self.create_signature(policy)
        url_encode(Base64.encode64(private_key.sign(OpenSSL::Digest::SHA1.new, (policy))))
      end

      #----------------------------------------------------------------------------
      def self.extract_key_pair_id(key_path)
        File.basename(key_path) =~ /^pk-(.*).pem$/ ? $1 : nil
      end

      #----------------------------------------------------------------------------
      def self.url_encode(s)
        s.gsub('+','-').gsub('=','_').gsub('/','~').gsub(/\n/,'').gsub(' ','')
      end

      #----------------------------------------------------------------------------
      def self.html_encode(s)
        return s.gsub('?', '%3F').gsub('=', '%3D').gsub('&', '%26')
      end
    end
  end
end
