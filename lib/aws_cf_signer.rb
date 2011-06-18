# Based on https://github.com/stlondemand/aws_cf_signer
#
require 'openssl'
require 'time'
require 'base64'

module AWS
    module CloudFront
        class Signer

            @@configured = false

            # Configure the signing class. Call this from an initializer. 
            #----------------------------------------------------------------------------
            def self.configure!(pem_path, key_pair_id = nil, default_expires = Time.now + 3600, html_escape = true)

                @@pem_path = pem_path
                @@default_expires = default_expires
                @@html_escape = html_escape
                @@key = OpenSSL::PKey::RSA.new(File.readlines(@@pem_path).join(""))
                @@key_pair_id = key_pair_id ? key_pair_id : extract_key_pair_id(@@pem_path)
                unless @@key_pair_id
                    raise ArgumentError.new("key_pair_id couldn't be inferred from #{@@pem_path} - please pass in explicitly")
                end

                @@configured = true
            end

            # Sign a subject url or stream resource name
            #----------------------------------------------------------------------------
            def self.sign(subject, policy_options = {})
                raise "Configure using AWS::CloudFront.Singer.configure! before signing." unless @@configured

                # If the url or stream path already has a query string parameter - append to that.
                separator = subject =~ /\?/ ? '&' : '?'

                if policy_options[:policy_file]
                    policy = IO.read(policy_options[:policy_file])
                    result = "#{subject}#{separator}Policy=#{encode_policy(policy)}&Signature=#{create_signature(policy)}&Key-Pair-Id=#{@@key_pair_id}"
                else
                    if policy_options.keys.size <= 1
                        # Canned Policy - shorter URL
                        expires_at = epoch_time(policy_options[:expires] || @@default_expires)
                        policy = %({"Statement":[{"Resource":"#{subject}","Condition":{"DateLessThan":{"AWS:EpochTime":#{expires_at}}}}]})
                        result = "#{subject}#{separator}Expires=#{expires_at}&Signature=#{create_signature(policy)}&Key-Pair-Id=#{@@key_pair_id}"
                    else
                        # Custom Policy
                        resource = policy_options[:resource] || subject
                        policy = generate_custom_policy(resource, policy_options)
                        result = "#{subject}#{separator}Policy=#{encode_policy(policy)}&Signature=#{create_signature(policy)}&Key-Pair-Id=#{@@key_pair_id}"
                    end
                end

                if @@html_escape
                    return html_escape(result)    
                else
                    return result
                end
            end

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
                url_safe(Base64.encode64(policy))
            end

            #----------------------------------------------------------------------------
            def self.create_signature(policy)
                url_safe(Base64.encode64(@@key.sign(OpenSSL::Digest::SHA1.new, (policy))))
            end

            #----------------------------------------------------------------------------
            def self.extract_key_pair_id(key_path)
                File.basename(key_path) =~ /^pk-(.*).pem$/ ? $1 : nil
            end

            #----------------------------------------------------------------------------
            def self.url_safe(s)
                s.gsub('+','-').gsub('=','_').gsub('/','~').gsub(/\n/,'').gsub(' ','')
            end

            #----------------------------------------------------------------------------
            def self.html_escape(s)
                s.gsub('?', '%3F').gsub('=', '%3D').gsub('&', '%26')
            end
        end
    end
end
