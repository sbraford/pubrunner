require 'test/unit'
require 'pubrunner'

class PdfTransformerTest < Test::Unit::TestCase
  include Pubrunner

  def test_transformer_pdf_generate
    wellformatted_path = File.dirname(__FILE__) + '/fixtures/wellformatted.txt'
    p = Processor.new(wellformatted_path)
    b = p.process
    pdf_xformer = Transformer::Pdf.new(b)
    pdf_book = pdf_xformer.transform
    pdf_book.title = 'Pdf Example'
    pdf_book.author = 'An Author'
    
    path = File.dirname(__FILE__) + '/fixtures/pdf_sandwich.html'
    template_path = File.dirname(__FILE__) + '/fixtures/pdf_template.html'
    pdf_path = File.dirname(__FILE__) + '/fixtures/pdf_sandwich.pdf'
    Transformer::Pdf.save(pdf_book, path, template_path)
    assert File.exists?(path)
    Transformer::Pdf.generate_pdf(path)
    assert File.exists?(pdf_path)
    
    File.delete(path)
    File.delete(pdf_path)
  end

  def test_transformer_pdf_save
    wellformatted_path = File.dirname(__FILE__) + '/fixtures/wellformatted.txt'
    p = Processor.new(wellformatted_path)
    b = p.process
    pdf_xformer = Transformer::Pdf.new(b)
    pdf_book = pdf_xformer.transform
    pdf_book.title = 'Pubrunner Example'
    pdf_book.author = 'Emmanuel Goldstein'
    
    path = File.dirname(__FILE__) + '/fixtures/pdf_sandwich.html'
    template_path = File.dirname(__FILE__) + '/fixtures/pdf_template.html'
    Transformer::Pdf.save(pdf_book, path, template_path)
    assert File.exists?(path)
    pdf_html = IO.read(path)
    assert_equal 0, pdf_html.scan('#').count
    assert_equal 0, pdf_html.scan('<mbp:pagebreak />').count
    assert_equal 2, pdf_html.scan('Pubrunner Example').count
    assert_equal 3, pdf_html.scan('Emmanuel Goldstein').count
    assert_equal 4, pdf_html.scan('<h2 class="chapter"').count
    File.delete(path)
  end

  def test_transformer_pdf_generate_sandwich
    wellformatted_path = File.dirname(__FILE__) + '/fixtures/wellformatted.txt'
    p = Processor.new(wellformatted_path)
    b = p.process
    pdf_xformer = Transformer::Pdf.new(b)
    pdf_book = pdf_xformer.transform
    pdf_book.title = 'PDF Transformer'
    pdf_book.author = 'Adobius Acrobatus'
    
    template_path = File.dirname(__FILE__) + '/fixtures/pdf_template.html'
    sandwich = Transformer::Pdf.generate_sandwich(pdf_book, template_path)
    assert_equal 0, sandwich.scan('#').count
    assert_equal 0, sandwich.scan('<mbp:pagebreak />').count
    assert_equal 2, sandwich.scan('PDF Transformer').count
    assert_equal 3, sandwich.scan('Adobius Acrobatus').count
    assert_equal 4, sandwich.scan('<h2 class="chapter"').count
  end

  def test_transformer_pdf
    wellformatted_path = File.dirname(__FILE__) + '/fixtures/wellformatted.txt'
    p = Processor.new(wellformatted_path)
    b = p.process
    pdf_xformer = Transformer::Pdf.new(b)
    pdf_book = pdf_xformer.transform
    
    assert pdf_book.chapters.first.content.include?("<b>Bold text</b>")
    assert pdf_book.chapters.first.content.include?("<em>Italics text</em>")
  end
  
end
