require 'test/unit'
require 'pubrunner'

class PubrunnerTest < Test::Unit::TestCase
  include Pubrunner
  
  def test_pubdown_processor
    bold = PubdownProcessor.embolden("Go **boldly** my friend")
    assert_equal "Go <b>boldly</b> my friend", bold

    strong = PubdownProcessor.strongify("Be **strong** like Hulk")
    assert_equal "Be <strong>strong</strong> like Hulk", strong

    emph = PubdownProcessor.emphasize("in *em* yup")
    assert_equal "in <em>em</em> yup", emph
    
    assert_equal "foo\n", PubdownProcessor.strip_right_whitespace_and_add_linebreaks("foo\t")
    assert_equal "foo\n", PubdownProcessor.strip_right_whitespace_and_add_linebreaks("foo\t     ")
    assert_equal "foo\n", PubdownProcessor.strip_right_whitespace_and_add_linebreaks("foo  ")

    boldly_emphasized = PubdownProcessor.transform_pubdown("this **bold** and *this emph* ok?")
    assert_equal "this <b>bold</b> and <em>this emph</em> ok?\n", boldly_emphasized
  end

  def test_book_check_markup_bad_formatting
    wellformatted_path = File.dirname(__FILE__) + '/fixtures/formatbad.txt'
    p = Processor.new(wellformatted_path)
    b = p.process
    assert_raises MarkupError do  # should raise in strict mode
      b.check_markup(true)
    end

    assert_nothing_raised do
      b.check_markup
    end
  end

  def test_book_check_markup
    wellformatted_path = File.dirname(__FILE__) + '/fixtures/wellformatted.txt'
    p = Processor.new(wellformatted_path)
    b = p.process
    assert_nothing_raised do
      b.check_markup
    end
  end

  def test_markup_checker
    mc = MarkupChecker.new("plain jane")
    assert_equal 0, mc.warnings_count
    
    mc = MarkupChecker.new("*missing closing")
    assert_equal 1, mc.warnings_count
    
    mc = MarkupChecker.new("**missing closing double")
    assert_equal 1, mc.warnings_count
    
    mc = MarkupChecker.new("missing opening* blah")
    assert_equal 1, mc.warnings_count

    mc = MarkupChecker.new("missing opening double**")
    assert_equal 1, mc.warnings_count

    mc = MarkupChecker.new("valid **strong** up in this")
    assert_equal 0, mc.warnings_count

    mc = MarkupChecker.new("valid *emph* up in this")
    assert_equal 0, mc.warnings_count
    
  end
  
  def test_processor
    wellformatted_path = File.dirname(__FILE__) + '/fixtures/wellformatted.txt'
    p = Processor.new(wellformatted_path)
    b = p.process
    assert_equal 'This is a Chapter Title', b.chapters.first.title
    assert_equal 'Chapter 2', b.chapters[1].title
    assert_equal 'A Third Chapter', b.chapters[2].title
    
    b.chapters.each do |chapt|
      assert_no_match /comment/, chapt.content
    end
    
    assert b.chapters.first.content.include?('Here is some text')
    assert b.chapters.first.content.include?('**Bold text**')
    assert b.chapters.first.content.include?('*Italics text*')
    
    assert b.chapters[1].content.include?("\t\"They haveth the same")
  end

  def test_processor_autoincrement_chapter_names
    wellformatted_path = File.dirname(__FILE__) + '/fixtures/wellformatted.txt'
    p = Processor.new(wellformatted_path, true)
    b = p.process
    assert_equal 'Chapter 1', b.chapters.first.title
    assert_equal 'Chapter 2', b.chapters[1].title
    assert_equal 'Chapter 3', b.chapters[2].title
    
    assert_equal 1, b.chapters[0].index
    assert_equal 2, b.chapters[1].index
    assert_equal 3, b.chapters[2].index
  end

  def test_processor_autoincrement_with_forced_chapter_names
    wellformatted_path = File.dirname(__FILE__) + '/fixtures/force_chapter_name.txt'
    p = Processor.new(wellformatted_path, true)
    b = p.process
    assert_equal 'Preface', b.chapters.first.title
    assert_equal 'Chapter 1', b.chapters[1].title
    assert_equal 'Chapter 2', b.chapters[2].title
    assert_equal 'Epilogue', b.chapters[3].title    
  end
  
  def test_book_new
    b = Book.new
    assert_nil b.title
    assert_empty b.chapters
    
    chapt1 = Chapter.new('Ch 1')
    chapt2 = Chapter.new('Ch 2')
    b = Book.new('Lulz', 'Author Name', [chapt1, chapt2])
    assert_equal 'Lulz', b.title
    assert_equal 'Author Name', b.author
    assert_equal chapt1, b.chapters.first
    assert_equal chapt2, b.chapters[1]
  end
  
  def test_book_add_chapter
    b = Book.new
    ch = Chapter.new('Chapter 1')
    b.add_chapter( ch  )
    assert_equal ch, b.chapters.first
    b.add_chapter( Chapter.new('Part Deux')  )
    assert_equal 'Part Deux', b.chapters[1].title
  end
  
  def test_chapter_new
    c = Chapter.new('The Title', 'the content')
    assert_equal 'The Title', c.title
    assert_equal 'the content', c.content
  end

end
