require 'test_helper'

class RemoteCardFlexTest < Test::Unit::TestCase
  def setup
    @gateway = CardFlexGateway.new(fixtures(:card_flex))

    @amount = 100
    @check =   check(:routing_number => '121202211', :account_number => '440023000000')
    @declined_check = check(:routing_number => '000000000', :account_number => '000000000000')

    @options = {
      order_id: '1',
      billing_address: address,
      description: 'Store Purchase'
    }
  end

  def test_dump_transcript
    # This test will run a purchase transaction on your gateway
    # and dump a transcript of the HTTP conversation so that
    # you can use that transcript as a reference while
    # implementing your scrubbing logic
    #dump_transcript_and_fail(@gateway, @amount, @check, @options)
  end

  #def test_transcript_scrubbing
  #  transcript = capture_transcript(@gateway) do
  #    @gateway.purchase(@amount, @check, @options)
  #  end
  #  transcript = @gateway.scrub(transcript)

  #  assert_scrubbed(@check.number, transcript)
  #  assert_scrubbed(@check.verification_value, transcript)
  #  assert_scrubbed(@gateway.options[:password], transcript)
  #end

  def test_successful_purchase
    response = @gateway.purchase(@amount, @check, @options)
    assert_success response
    assert_match %r{Successfully processed; no error}, response.message
  end

  def test_failed_purchase
    response = @gateway.purchase(1, @declined_check, @options)
    assert_failure response
    assert_match %r{Invalid ACH Routing Number}, response.message
  end

  def test_successful_refund
    purchase = @gateway.purchase(@amount, @check, @options)
    assert_success purchase

    assert refund = @gateway.refund(purchase.authorization)
    #transactions don't settle in testing
    #assert_success refund
  end

  #def test_partial_refund
  #  purchase = @gateway.purchase(@amount, @check, @options)
  #  assert_success purchase

  #  assert refund = @gateway.refund(purchase.authorization, @amount-1)
  #  assert_success refund
  #end

  def test_failed_refund
    response = @gateway.refund('123456789')
    assert_failure response
  end

  def test_successful_void
    auth = @gateway.purchase(@amount, @check, @options)
    assert_success auth

    assert void = @gateway.void(auth.authorization)
    assert_success void
  end

  def test_failed_void
    response = @gateway.void('123456789')
    assert_failure response
  end

  def test_invalid_login
    gateway = CardFlexGateway.new(
      merchant_id: '00001',
      service_key: 'BUNK_SERVICE_KEY'
    )
    response = gateway.purchase(@amount, @check, @options)
    assert_failure response
  end
end
