require 'test_helper'

class RemoteCardFlexTest < Test::Unit::TestCase
  def setup
    @gateway = CardFlexGateway.new(fixtures(:card_flex))

    @amount = 100
    @credit_card = check(:routing_number => '4000100011112224')
    @declined_card = check(:routing_number => '4000300011112220')

    @options = {
      order_id: '1',
      billing_address: address,
      description: 'Store Purchase'
    }
  end

  def test_dump_transcript
    #skip("Transcript scrubbing for this gateway has been tested.")

    # This test will run a purchase transaction on your gateway
    # and dump a transcript of the HTTP conversation so that
    # you can use that transcript as a reference while
    # implementing your scrubbing logic
    dump_transcript_and_fail(@gateway, @amount, @credit_card, @options)
  end

  def test_transcript_scrubbing
    transcript = capture_transcript(@gateway) do
      @gateway.purchase(@amount, @credit_card, @options)
    end
    transcript = @gateway.scrub(transcript)

    assert_scrubbed(@credit_card.number, transcript)
    assert_scrubbed(@credit_card.verification_value, transcript)
    assert_scrubbed(@gateway.options[:password], transcript)
  end

  def test_successful_purchase
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_match %r{<AchWebSaleResponse xmlns="https://webservices.cfinc.com/ach/data/"
    xmlns:i="http://www.w3.org/2001/XMLSchema‐instance">
      <MerchantId>0</MerchantId>
      <TransactionId>0</TransactionId>
      <ReferenceId>#{@options[:order_id]}</ReferenceId>
      <BatchNumber>0</BatchNumber>
      <TransactionAmount>#{@amount}</TransactionAmount>
      <Status>status</Status>
      <ReasonCode>reasoncode</ReasonCode>
      <Message>message</Message>
      <TransactionDateTime>2009‐11‐17T17:02:14.2277463‐08:00</TransactionDateTime>
    </AchWebSaleResponse>}, response.message
  end

  def test_failed_purchase
    response = @gateway.purchase(@amount, @declined_card, @options)
    assert_failure response
    assert_match %r{
      REPLACE WITH FAILED PURCHASE MESSAGE
    }, response.message
  end

  def test_successful_refund
    purchase = @gateway.purchase(@amount, @credit_card, @options)
    assert_success purchase

    assert refund = @gateway.refund(nil, purchase.authorization)
    assert_success refund
  end

  def test_partial_refund
    purchase = @gateway.purchase(@amount, @credit_card, @options)
    assert_success purchase

    assert refund = @gateway.refund(@amount-1, purchase.authorization)
    assert_success refund
  end

  def test_failed_refund
    response = @gateway.refund(nil, '')
    assert_failure response
  end

  #def test_successful_void
  #  #auth = @gateway.authorize(@amount, @credit_card, @options)
  #  assert_success auth

  #  assert void = @gateway.void(auth.authorization)
  #  assert_success void
  #end

  def test_failed_void
    response = @gateway.void('')
    assert_failure response
  end

  def test_invalid_login
    gateway = CardFlexGateway.new(
      merchant_id: 'NOT_AN_ID',
      service_key: 'BUNK_SERVICE_KEY'
    )
    response = gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
  end
end
