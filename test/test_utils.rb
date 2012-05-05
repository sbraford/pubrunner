require 'test/unit'
require 'pubrunner'

class PubrunnerUtilsTest < Test::Unit::TestCase
  include Pubrunner
  
  def test_quotes_to_entities
    assert_equal '&ldquo;Dugga dugga,&rdquo; she said.', Utils.quotes_to_entities('"Dugga dugga," she said.')

    assert_equal 'She whispered, &ldquo;I love bacon.&rdquo;', Utils.quotes_to_entities('She whispered, "I love bacon."')

    assert_equal '&ldquo;Dugga dugga,&rdquo; she said. &ldquo;I derp.&rdquo;', Utils.quotes_to_entities('"Dugga dugga," she said. "I derp."')

    assert_equal '&ldquo;A really long paragraph without a closing paren', Utils.quotes_to_entities('"A really long paragraph without a closing paren')

    assert_equal '&ldquo;This line has three parens,&rdquo; she said. &ldquo;Looong text', Utils.quotes_to_entities('"This line has three parens," she said. "Looong text')
    
  end
  
  def test_mdashify
    assert_equal "Blah&mdash;zzz.", Utils.mdashify("Blah--zzz.")
    assert_equal "Twosies&mdash;yeah buddy&mdash;who ha.", Utils.mdashify("Twosies--yeah buddy--who ha.")
  end

end
