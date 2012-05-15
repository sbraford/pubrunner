require 'test/unit'
require 'pubrunner'

class KindleTransformerTest < Test::Unit::TestCase
  include Pubrunner

  def test_transformer_kindle_kindlegen
    wellformatted_path = File.dirname(__FILE__) + '/fixtures/wellformatted.txt'
    p = Processor.new(wellformatted_path)
    b = p.process
    kt = Transformer::Kindle.new(b)
    kindle_book = kt.transform
    kindle_book.title = 'Pubrunner Example'
    kindle_book.author = 'Emmanuel Goldstein'
    
    path = File.dirname(__FILE__) + '/fixtures/sandwiched.html'
    template_path = File.dirname(__FILE__) + '/fixtures/kindle_template.html'
    Transformer::Kindle.save(kindle_book, path, template_path)
    assert File.exists?(path)
    Transformer::Kindle.kindlegen(path)
    kindlegen_output_path = File.dirname(__FILE__) + '/fixtures/sandwiched.mobi'
    assert File.exists?(kindlegen_output_path)
    File.delete(path)
    File.delete(kindlegen_output_path)
  end
  
  def test_transformer_kindle_save
    wellformatted_path = File.dirname(__FILE__) + '/fixtures/wellformatted.txt'
    p = Processor.new(wellformatted_path)
    b = p.process
    kt = Transformer::Kindle.new(b)
    kindle_book = kt.transform
    kindle_book.title = 'Pubrunner Example'
    kindle_book.author = 'Emmanuel Goldstein'
    
    path = File.dirname(__FILE__) + '/fixtures/sandwiched.html'
    template_path = File.dirname(__FILE__) + '/fixtures/kindle_template.html'
    Transformer::Kindle.save(kindle_book, path, template_path)
    assert File.exists?(path)
    kindle_html = IO.read(path)
    assert_equal 0, kindle_html.scan('#').count
    assert_equal 2, kindle_html.scan('Pubrunner Example').count
    assert_equal 3, kindle_html.scan('Emmanuel Goldstein').count
    assert_equal 4, kindle_html.scan('<mbp:pagebreak />').count

    assert_equal 1, kindle_html.scan('<a name="ch1">').count
    assert_equal 1, kindle_html.scan('<a name="ch2">').count
    assert_equal 1, kindle_html.scan('<a name="ch3">').count

    File.delete(path)
  end

  def test_transformer_kindle_generate_sandwich
    wellformatted_path = File.dirname(__FILE__) + '/fixtures/wellformatted.txt'
    p = Processor.new(wellformatted_path)
    b = p.process
    kt = Transformer::Kindle.new(b)
    kindle_book = kt.transform
    kindle_book.title = 'Pubrunner Example'
    kindle_book.author = 'Emmanuel Goldstein'
    
    template_path = File.dirname(__FILE__) + '/fixtures/kindle_template.html'
    sandwich = Transformer::Kindle.generate_sandwich(kindle_book, template_path)
    assert_equal 0, sandwich.scan('#').count
    assert_equal 2, sandwich.scan('Pubrunner Example').count
    assert_equal 3, sandwich.scan('Emmanuel Goldstein').count
    assert_equal 4, sandwich.scan('<mbp:pagebreak />').count
  end
  
  def test_transformer_kindle_save_meat
    wellformatted_path = File.dirname(__FILE__) + '/fixtures/wellformatted.txt'
    p = Processor.new(wellformatted_path)
    b = p.process
    b.title = 'Pubrunner Example'
    b.author = 'Emmanuel Goldstein'

    kt = Transformer::Kindle.new(b)
    kindle_book = kt.transform
    assert_equal 'Pubrunner Example', kindle_book.title
    assert_equal 'Emmanuel Goldstein', kindle_book.author
    
    kindle_book.chapters.each do |ch|
      assert !ch.content.include?('#')
    end
    path = File.dirname(__FILE__) + '/fixtures/wellformatted-meat.html'
    Transformer::Kindle.save_meat(kindle_book, path)
    assert File.exists?(path)
    kindle_html = IO.read(path)
    assert_equal 3, kindle_html.scan('<mbp:pagebreak />').count
    File.delete(path)
  end
  
  def test_transformer_kindle
    wellformatted_path = File.dirname(__FILE__) + '/fixtures/wellformatted.txt'
    p = Processor.new(wellformatted_path)
    b = p.process
    kt = Transformer::Kindle.new(b)
    kindle_book = kt.transform
    
    assert kindle_book.chapters.first.content.include?("<b>Bold text</b>")
    assert kindle_book.chapters.first.content.include?("<em>Italics text</em>")
    
    assert kindle_book.chapters[1].content.include?('Day &amp; Night')
    assert kindle_book.chapters[1].content.include?('&lt;special&gt; characters')

  end
    
end
