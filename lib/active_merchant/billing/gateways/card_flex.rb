require 'nokogiri'

#NOTE:  XML ELEMENT ORDER IS IMPERATIVE!!! 

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

      STANDARD_ERROR_CODE_MAPPING = {
        "A00" => "OK",
        "C01" => STANDARD_ERROR_CODE[:incorrect_number],
        "C02" => STANDARD_ERROR_CODE[:incorrect_number],
        "C03" => STANDARD_ERROR_CODE[:incorrect_number],
        "C01" => STANDARD_ERROR_CODE[:incorrect_number],
        "R13" => STANDARD_ERROR_CODE[:incorrect_number],
        "R16" => STANDARD_ERROR_CODE[:expired_card],
        :default => STANDARD_ERROR_CODE[:processing_error]
      }

      def initialize(options={})
        requires!(options, :merchant_id, :service_key)
        super
      end

      def purchase(money, payment, options={})
        post = {}
        add_reference_id(post)
        add_name(post, payment)
        add_invoice(post, money, options)
        add_payment(post, payment)
        #add_address(post, payment, options)

        commit('Sale', post)
      end

      def refund(authorization, money=0,  options={})
        transaction_id, reference_id = split_authorization(authorization)
        post = {
          :TransactionId => transaction_id,
          :ReferenceId   => reference_id
        }
        #add_reference_id(post, options)
        add_invoice(post, money || 0, options)

        commit('Refund', post)
      end

      def void(authorization, options={})
        transaction_id, reference_id = split_authorization(authorization)
        post = {
          :TransactionId => transaction_id,
          :ReferenceId   => reference_id
        }
        #add_reference_id(post)
        add_invoice(post, 0, options)

        commit('Void', post)
      end

      def supports_scrubbing?
        true
      end

      def scrub(transcript)
        scrub_fields.each do |key|
          transcript = transcript.
            gsub(%r((<#{key}>)[^<]+), '\1[FILTERED]\2')
        end

        transcript
      end

      def scrub_fields
        [
          :MerchantId,
          :ServiceKey,
          :ReferenceId,
          :TransactionAmount,
          :TransactionId,
          :CustomerName,
          :CustomerBankAccountType,
          :CustomerBankAccountNumber,
          :CustomerBankRoutingNumber,
          :CustomerBankCheckNumber,
          :CustomerAddress,
          :CustomerCity,
          :CustomerState,
          :CustomerZipCode,
          :CustomerPhone,
          :CustomerIdNumber,
          :CustomerIdState,
          :PaymentRelatedInfo
        ]
      end

      private

      def add_address(post, payment, options)
        address = options[:billing_address] || options[:address] || {}
        
        post[ :CustomerAddress ] = truncate(address[:address1], 30)
        post[ :CustomerCity    ] = truncate(address[:city], 20)
        post[ :CustomerState   ] = truncate(address[:state], 2)
        post[ :CustomerZipCode ] = truncate(address[:zip], 5)
        post[ :CustomerPhone   ] = truncate(address[:phone].gsub(/[^0-9]/,''), 10)
          #:CustomerIdNumber => "",
          #:CustomerIdState => ""
      end

      def add_reference_id(post, options={})
        options[:ReferenceId] ||= SecureRandom.uuid.to_s.gsub("-","")[0..19]
        post[ :ReferenceId ] = options[:ReferenceId]
      end

      def add_invoice(post, money, options)
        post[ :TransactionAmount ] = amount(money)
        #post[:currency] = (options[:currency] || currency(money))
      end

      def add_name(post, payment)
        post[ :CustomerName ] = "#{payment.first_name} #{payment.last_name}"
      end
      
      def add_payment(post, payment)
        post[ :CustomerBankAccountType   ] = payment.account_type.capitalize
        post[ :CustomerBankAccountNumber ] = payment.account_number
        post[ :CustomerBankRoutingNumber ] = payment.routing_number
        #:CustomerBankCheckNumber =>   payment.number
      end

      def parse(body)
        params = Nokogiri::XML(body).children[0].children.inject({}) do |hsh, child|
          hsh[child.name.to_s] = child.children.first.to_s
          hsh
        end
        params
      end

      def commit(action, parameters)
        url = "#{(test? ? test_url : live_url)}Ach#{action}"
        response = parse(ssl_post(url, post_data(action, parameters), headers))

        Response.new(
          success_from(response),
          message_from(response),
          {},
          authorization: authorization_from(response),
          status_code: status_code(response),
          error_code: error_code(response),
          test: test?
        )
      end

      def headers
        { "Content-Type" => "application/xml" }
      end

      def success_from(response)
        response["ReasonCode"] == "A00"
      end

      def message_from(response)
        response["Message"]
      end

      def status_code(response)
        response["ReasonCode"]
      end

      def error_code(response)
        code = response["ReasonCode"] 

        STANDARD_ERROR_CODE_MAPPING.has_key?(code) ?
          STANDARD_ERROR_CODE_MAPPING[ code ] : STANDARD_ERROR_CODE_MAPPING[:default]
      end

      def authorization_from(response)
        [response["TransactionId"], response["ReferenceId"]].join('#')
      end

      def split_authorization(authorization)
        transaction_id, authcode = authorization.split("#")
        [transaction_id, authcode]
      end

      def truncate(value, max_size)
        return nil unless value
        value.to_s[0, max_size]
      end

      def post_data(action, params = {})
        params.delete(:amount)
        Nokogiri::XML::Builder.new do |xml|
          xml.send("AchWeb#{action}Request",'xmlns' => 'https://webservices.cfinc.com/ach/data/') do
            xml.MerchantId( @options[:merchant_id] ) 
            xml.ServiceKey( @options[:service_key] ) 

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
