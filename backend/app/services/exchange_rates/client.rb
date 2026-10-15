
require "net/http"
require "json"
require "bigdecimal"

module ExchangeRates
  class Client
    BASE_URL = "https://api.frankfurter.dev/v2".freeze

    class Error < StandardError; end

    def rate(from:, to:)
      from = from.to_s.upcase
      to = to.to_s.upcase

      return BigDecimal("1") if from == to

      uri = URI(
        "#{BASE_URL}/rate/#{from.downcase}/#{to.downcase}"
      )

      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: true,
        open_timeout: 3,
        read_timeout: 5
      ) do |http|
        http.get(uri.request_uri)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "Exchange-rate API returned HTTP #{response.code}"
      end

      data = JSON.parse(response.body)
      BigDecimal(data.fetch("rate").to_s)
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError,
           Errno::ECONNREFUSED, JSON::ParserError, KeyError => e
      raise Error, "Could not retrieve exchange rate: #{e.message}"
    end
  end
end
