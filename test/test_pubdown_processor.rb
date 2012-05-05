require 'test/unit'
require 'pubrunner'

class PubdownProcessorTest < Test::Unit::TestCase
  include Pubrunner
  
  def test_encode_special_entities
    assert_equal '&lt;less than', PubdownProcessor.encode_special_entities('<less than')
    assert_equal '&gt;greater than', PubdownProcessor.encode_special_entities('>greater than')
    assert_equal 'black &amp; white', PubdownProcessor.encode_special_entities('black & white')
    assert_equal '&lt;day &amp; night&gt;', PubdownProcessor.encode_special_entities('<day & night>')
  end


end
