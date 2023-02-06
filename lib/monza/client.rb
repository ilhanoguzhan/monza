require 'json'
require 'net/https'
require 'uri'

module Monza
  class Client
    attr_accessor :verification_url, :shared_secret

    def initialize(verification_url, shared_secret)
      @verification_url = verification_url
      @shared_secret = shared_secret
    end

    def verify(data, options = {})
      # Post to apple and receive json_response
      json_response = post_receipt_verification(data, options)
      # Get status code of response
      status = json_response['status'].to_i

      case status
      when 0
        begin
          return VerificationResponse.new(json_response)
        rescue
          nil
        end
      else
        raise VerificationResponse::VerificationError.new(status)
      end

    end

    private

    def post_receipt_verification(data, options = {})
      parameters = {
        'receipt-data' => data
      }

      parameters['password'] = self.shared_secret
      parameters['exclude-old-transactions'] = options[:exclude_old_transactions] if options[:exclude_old_transactions]

      uri = URI(@verification_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      request = Net::HTTP::Post.new(uri.request_uri)
      request['Accept'] = "application/json"
      request['Content-Type'] = "application/json"
      request.body = parameters.to_json

      response = http.request(request)

      JSON.parse(response.body)
    end
  end
end
