require 'test/unit'
require 'pubrunner'

class OctopressTransformerTest < Test::Unit::TestCase
  include Pubrunner
  
  def test_octopress_transform_and_save
    wellformatted_path = File.dirname(__FILE__) + '/fixtures/wellformatted.txt'
    p = Processor.new(wellformatted_path)
    b = p.process
    t = Time.now
    ot = Transformer::Octopress.new(b)
    
    target_dir = File.dirname(__FILE__) + '/fixtures/octopress'
    ot.transform_and_save(target_dir)
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