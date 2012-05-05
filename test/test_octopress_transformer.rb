require 'test/unit'
require 'pubrunner'

class OctopressTransformerTest < Test::Unit::TestCase
  include Pubrunner
  
  def test_octopress_transform_and_save
    wellformatted_path = File.dirname(__FILE__) + '/fixtures/wellformatted.txt'
    p = Processor.new(wellformatted_path)
    b = p.process
    ot = Transformer::Octopress.new(b)
    
    target_dir = File.dirname(__FILE__) + '/fixtures/octopress'
    ot.transform_and_save(target_dir)
    octo_posts_path = File.join(target_dir, '*.html')
    Dir[octo_posts_path].entries.each do |f|
      if f.include?('chapter-title')
        chapt_one = IO.read(f)
        assert chapt_one.include?('<strong>Bold text</strong>')
        assert chapt_one.include?('<em>Italics text</em>')
      elsif f.include?('chapter-2')
        chapt_two = IO.read(f)
        assert chapt_two.include?('Day &amp; Night')
        assert chapt_two.include?('&lt;special&gt; characters')
      end
    end
    assert_equal 3, Dir[octo_posts_path].entries.size
    Utils.clean_folder(target_dir)
  end
  
  def  test_octopressify_filename
    wellformatted_path = File.dirname(__FILE__) + '/fixtures/wellformatted.txt'
    p = Processor.new(wellformatted_path)
    b = p.process
    t = Time.now
    ot = Transformer::Octopress.new(b)

    fname = ot.octopressify_filename(b.chapters[0].title, t)
    date = t.strftime("%Y-%m-%d")
    assert_equal "#{date}-this-is-a-chapter-title.html", fname
  end
end