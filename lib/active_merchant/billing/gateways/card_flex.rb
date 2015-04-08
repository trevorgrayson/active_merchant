require 'nokogiri'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class CardFlexGateway < Gateway
      self.test_url = 'https://wswest.cfinc.com/ach/ACHOnlineServices.svc/'
      self.live_url = 'https://wswest.cfinc.com/ach/ACHOnlineServices.svc/'

      self.supported_countries = ['US']
      self.default_currency = 'USD'
      #self.supported_cardtypes = [:visa, :master, :american_express, :discover]

      self.homepage_url = 'https://www.cardflexprepaid.com/'
      self.display_name = 'CardFlex'

      STANDARD_ERROR_CODE_MAPPING = {}

      def initialize(options={})
        requires!(options, :merchant_id, :service_key)
        super
      end

      def purchase(money, payment, options={})
        post = {}
        add_invoice(post, money, options)
        add_payment(post, payment)
        add_address(post, payment, options)

        commit('AchSale', post)
      end

      def refund(money, authorization, options={})
        commit('AchRefund', options)
      end

      def void(authorization, options={})
        commit('AchVoid', options)
      end

      def supports_scrubbing?
        true
      end

      def scrub(transcript)
        transcript
      end

      private

      def add_address(post, payment, options)
        address = options[:billing_address] || options[:address] || {}
        post = post.update({
          :CustomerAddress => truncate(address[:address1], 30),
          :CustomerCity =>    truncate(address[:city], 20),
          :CustomerState =>   truncate(address[:state], 2),
          :CustomerZipCode => truncate(address[:zip], 5),
          :CustomerPhone =>   truncate(address[:phone], 10)
          #:CustomerIdNumber => "",
          #:CustomerIdState => ""
        })
      end

      def add_invoice(post, money, options)
        post[:TransactionAmount] = amount(money)
        #post[:currency] = (options[:currency] || currency(money))
      end

      def add_payment(post, payment)
        post = post.update({
          :CustomerName => "#{payment.first_name} #{payment.last_name}",
          :CustomerBankAccountType =>   payment.account_type,
          :CustomerBankAccountNumber => payment.routing_number,
          :CustomerBankRoutingNumber => payment.account_number,
          :CustomerBankCheckNumber =>   payment.number
        })
      end

      def parse(body)
        {}
      end

      def commit(action, parameters)
        puts parameters

        url = (test? ? test_url : live_url) + action
        response = parse(ssl_post(url, post_data(parameters)))

        Response.new(
          success_from(response),
          message_from(response),
          response,
          authorization: authorization_from(response),
          test: test?
        )
      end

      def success_from(response)
      end

      def message_from(response)
      end

      def authorization_from(response)
      end

      def truncate(value, max_size)
        return nil unless value
        value.to_s[0, max_size]
      end

      def post_data(params = {})
        amount = params.delete(:amount)
        params = params.update({
          :MerchantId => @options[:merchant_id],
          :ServiceKey => @options[:service_key]
          #:ReferenceId =>
          #:TransactionAmount => amount
        })
        Nokogiri::XML::Builder.new do |xml|
          xml.AchWebSaleRequest('xmlns' => 'https://webservices.cfinc.com/ach/data/') do
            params.each do |k,v|
              xml.send(k,v)
            end
            #xml.MerchantId(@options[:merchant_id])
            #xml.ServiceKey(@options[:service_key])
            #xml.ReferenceId
            #xml.TransactionAmount
            #xml.CustomerName
            #xml.CustomerBankAccountType
            #xml.CustomerBankAccountNumber
            #xml.CustomerBankRoutingNumber
            #xml.CustomerBankCheckNumber
            #xml.CustomerAddress
            #xml.CustomerCity
            #xml.CustomerState
            #xml.CustomerZipCode
            #xml.CustomerPhone
            #xml.CustomerIdNumber
            #xml.CustomerIdState
            #xml.MerchantSecCode
            #xml.MerchantDescriptor
            #xml.MerchantPhone
            #xml.PaymentRelatedInfo
          end
        end.to_xml(indent: 0)
      end
    end
  end
end
