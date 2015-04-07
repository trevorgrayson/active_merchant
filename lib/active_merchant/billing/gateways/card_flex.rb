module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class CardFlexGateway < Gateway
      self.test_url = 'https://example.com/test'
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
        add_customer_data(post, options)

        commit('AchSale', post)
      end

      #def authorize(money, payment, options={})
      #  post = {}
      #  add_invoice(post, money, options)
      #  add_payment(post, payment)
      #  add_address(post, payment, options)
      #  add_customer_data(post, options)

      #  commit('authonly', post)
      #end

      #def capture(money, authorization, options={})
      #  commit('capture', post)
      #end

      def refund(money, authorization, options={})
        commit('AchRefund', post)
      end

      def void(authorization, options={})
        commit('AchVoid', post)
      end

      #def verify(credit_card, options={})
      #  MultiResponse.run(:use_first_response) do |r|
      #    r.process { authorize(100, credit_card, options) }
      #    r.process(:ignore_result) { void(r.authorization, options) }
      #  end
      #end

      def supports_scrubbing?
        true
      end

      def scrub(transcript)
        transcript
      end

      private

      def add_customer_data(post, options)
      end

      def add_address(post, creditcard, options)
      end

      def add_invoice(post, money, options)
        post[:amount] = amount(money)
        post[:currency] = (options[:currency] || currency(money))
      end

      def add_payment(post, payment)
      end

      def parse(body)
        {}
      end

      def commit(action, parameters)
        url = (test? ? test_url : live_url)
        response = parse(ssl_post(url, post_data(action, parameters)))

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

      def post_data(action, parameters = {})
        Nokogiri::XML::Builder.new do |xml|
          xml.AchWebSaleRequest('xmlns' => 'https://webservices.cfinc.com/ach/data/') do
            xml.MerchantId(@options[:merchant_id])
            xml.ServiceKey(@options[:service_key])
            #xml.ReferenceId
            #xml.CustomerName
            #xml.TransactionAmount
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
