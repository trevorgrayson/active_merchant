require 'test_helper'

class CardFlexTest < Test::Unit::TestCase
  def setup
    @gateway = CardFlexGateway.new(
      merchant_id: 'TEST_MERCHANT_ID',
      service_key: 'TEST_SERVICE_KEY'
    )

    @check = check
    @amount = 100

    @options = {
      order_id: '1',
      billing_address: address,
      description: 'Store Purchase'
    }
  end

  def test_successful_purchase
    @gateway.expects(:ssl_post).returns(successful_purchase_response)

    response = @gateway.purchase(@amount, @check, @options)
    assert_success response

    assert_equal '5889030#d641c0cf7e024852a667', response.authorization
    assert response.test?
  end

  def test_failed_purchase
    @gateway.expects(:ssl_post).returns(failed_purchase_response)

    response = @gateway.purchase(@amount, @check, @options)
    assert_failure response
    assert_equal Gateway::STANDARD_ERROR_CODE[:incorrect_number], response.error_code
  end


  def test_successful_refund
  end

  def test_failed_refund
    @gateway.expects(:ssl_post).returns(failed_refund_response)

    response = @gateway.refund('123456789')
    assert_failure response
  end

  def test_successful_void
    @gateway.expects(:ssl_post).returns(successful_void_response)

    assert void = @gateway.void("123456789")
    assert_success void
  end

  def test_failed_void
    @gateway.expects(:ssl_post).returns(failed_void_response)

    assert void = @gateway.void("123456789")
    assert_failure void
  end

  def test_scrub
    assert @gateway.supports_scrubbing?
    assert_equal @gateway.scrub(pre_scrubbed), post_scrubbed
  end

  private

  def pre_scrubbed
    <<-PRE_SCRUBBED
opening connection to wswest.cfinc.com:443...
opened
starting SSL for wswest.cfinc.com:443...
SSL established
<- "POST /ach/ACHOnlineServices.svc/AchSale HTTP/1.1\r\nContent-Type: application/xml\r\nAccept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3\r\nAccept: */*\r\nUser-Agent: Ruby\r\nConnection: close\r\nHost: wswest.cfinc.com\r\nContent-Length: 524\r\n\r\n"
<- "<?xml version=\"1.0\"?>\n<AchWebSaleRequest xmlns=\"https://webservices.cfinc.com/ach/data/\">\n<MerchantId>10001</MerchantId>\n<ServiceKey>Tb53JdVf6x4X2GoOw19Mhs0N8FeIr73S</ServiceKey>\n<ReferenceId>4f9ec2a851334f57a4e7</ReferenceId>\n<CustomerName>Jim Smith</CustomerName>\n<TransactionAmount>1.00</TransactionAmount>\n<CustomerBankAccountType>Checking</CustomerBankAccountType>\n<CustomerBankAccountNumber>440023000000</CustomerBankAccountNumber>\n<CustomerBankRoutingNumber>121202211</CustomerBankRoutingNumber>\n</AchWebSaleRequest>\n"
-> "HTTP/1.1 200 OK\r\n"
-> "Content-Type: application/xml; charset=utf-8\r\n"
-> "Server: Microsoft-IIS/7.5\r\n"
-> "X-Powered-By: ASP.NET\r\n"
-> "Date: Thu, 30 Apr 2015 01:37:59 GMT\r\n"
-> "Connection: close\r\n"
-> "Content-Length: 493\r\n"
-> "\r\n"
reading 493 bytes...
-> "<AchWebSaleResponse xmlns=\"https://webservices.cfinc.com/ach/data/\" xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\"><MerchantId>10001</MerchantId><TransactionId>5882515</TransactionId><ReferenceId>4f9ec2a851334f57a4e7</ReferenceId><BatchNumber>5</BatchNumber><TransactionAmount>1.00</TransactionAmount><Status>APPROVED</Status><ReasonCode>A00</ReasonCode><Message>Successfully processed; no error</Message><TransactionDateTime>2015-04-29T18:36:59</TransactionDateTime></AchWebSaleResponse>"
read 493 bytes
Conn close
    PRE_SCRUBBED
  end

  def post_scrubbed
    #Put the scrubbed contents of transcript.log here after implementing your scrubbing function.
    #Things to scrub:
    #  - Routing Number
    #  - Account Number
    #  - Sensitive authentication details
    <<-POST_SCRUBBED
opening connection to wswest.cfinc.com:443...
opened
starting SSL for wswest.cfinc.com:443...
SSL established
<- "POST /ach/ACHOnlineServices.svc/AchSale HTTP/1.1\r\nContent-Type: application/xml\r\nAccept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3\r\nAccept: */*\r\nUser-Agent: Ruby\r\nConnection: close\r\nHost: wswest.cfinc.com\r\nContent-Length: 524\r\n\r\n"
<- "<?xml version=\"1.0\"?>\n<AchWebSaleRequest xmlns=\"https://webservices.cfinc.com/ach/data/\">\n<MerchantId>[FILTERED]</MerchantId>\n<ServiceKey>[FILTERED]</ServiceKey>\n<ReferenceId>[FILTERED]</ReferenceId>\n<CustomerName>[FILTERED]</CustomerName>\n<TransactionAmount>[FILTERED]</TransactionAmount>\n<CustomerBankAccountType>[FILTERED]</CustomerBankAccountType>\n<CustomerBankAccountNumber>[FILTERED]</CustomerBankAccountNumber>\n<CustomerBankRoutingNumber>[FILTERED]</CustomerBankRoutingNumber>\n</AchWebSaleRequest>\n"
-> "HTTP/1.1 200 OK\r\n"
-> "Content-Type: application/xml; charset=utf-8\r\n"
-> "Server: Microsoft-IIS/7.5\r\n"
-> "X-Powered-By: ASP.NET\r\n"
-> "Date: Thu, 30 Apr 2015 01:37:59 GMT\r\n"
-> "Connection: close\r\n"
-> "Content-Length: 493\r\n"
-> "\r\n"
reading 493 bytes...
-> "<AchWebSaleResponse xmlns=\"https://webservices.cfinc.com/ach/data/\" xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\"><MerchantId>[FILTERED]</MerchantId><TransactionId>[FILTERED]</TransactionId><ReferenceId>[FILTERED]</ReferenceId><BatchNumber>5</BatchNumber><TransactionAmount>[FILTERED]</TransactionAmount><Status>APPROVED</Status><ReasonCode>A00</ReasonCode><Message>Successfully processed; no error</Message><TransactionDateTime>2015-04-29T18:36:59</TransactionDateTime></AchWebSaleResponse>"
read 493 bytes
Conn close
    POST_SCRUBBED
  end

  def successful_purchase_response
    %(<AchWebSaleResponse xmlns=\"https://webservices.cfinc.com/ach/data/\" xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\"><MerchantId>10001</MerchantId><TransactionId>5889030</TransactionId><ReferenceId>d641c0cf7e024852a667</ReferenceId><BatchNumber>5</BatchNumber><TransactionAmount>1.00</TransactionAmount><Status>APPROVED</Status><ReasonCode>A00</ReasonCode><Message>Successfully processed; no error</Message><TransactionDateTime>2015-04-30T09:43:10</TransactionDateTime></AchWebSaleResponse>)
  end

  def failed_purchase_response
    %(<AchWebSaleResponse xmlns=\"https://webservices.cfinc.com/ach/data/\" xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\"><MerchantId>10001</MerchantId><TransactionId>0</TransactionId><ReferenceId>937e580e16d4480182be</ReferenceId><BatchNumber>0</BatchNumber><TransactionAmount>0.01</TransactionAmount><Status>REJECTED</Status><ReasonCode>R13</ReasonCode><Message>Invalid ACH Routing Number</Message><TransactionDateTime>2015-04-30T09:43:03.7871194-07:00</TransactionDateTime></AchWebSaleResponse>)
  end

  def successful_refund_response
    %()
  end

  def failed_refund_response
    %(<AchWebRefundResponse xmlns=\"https://webservices.cfinc.com/ach/data/\" xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\"><MerchantId>10001</MerchantId><TransactionId>0</TransactionId><ReferenceId>58f4f6a2f7584b029749</ReferenceId><BatchNumber>0</BatchNumber><TransactionAmount>0.00</TransactionAmount><Status>REJECTED</Status><ReasonCode>X17</ReasonCode><Message>Matching payment not found</Message><TransactionDateTime>2015-04-30T09:43:04.693149-07:00</TransactionDateTime></AchWebRefundResponse>)
  end

  def successful_void_response
    %(<AchWebVoidResponse xmlns=\"https://webservices.cfinc.com/ach/data/\" xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\"><MerchantId>10001</MerchantId><TransactionId>5889030</TransactionId><ReferenceId>ac1b6ed4dffc484e97c8</ReferenceId><BatchNumber>5</BatchNumber><TransactionAmount>1.00</TransactionAmount><Status>VOIDED</Status><ReasonCode>A00</ReasonCode><Message>Successfully processed; no error</Message><TransactionDateTime>2015-04-30T09:43:11</TransactionDateTime></AchWebVoidResponse>)
  end

  def failed_void_response
    %(<AchWebVoidResponse xmlns=\"https://webservices.cfinc.com/ach/data/\" xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\"><MerchantId>10001</MerchantId><TransactionId>0</TransactionId><ReferenceId>6521aebe18db4c2fb29b</ReferenceId><BatchNumber>0</BatchNumber><TransactionAmount>0.00</TransactionAmount><Status>REJECTED</Status><ReasonCode>X17</ReasonCode><Message>Matching payment not found</Message><TransactionDateTime>2015-04-30T09:43:05.2711334-07:00</TransactionDateTime></AchWebVoidResponse>)
  end
end
