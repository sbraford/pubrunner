module Pubrunner

  class TocGenerator
    
    def initialize(book)
      @book = book
    end
    
    def generate(template_path, output_path)
      html = IO.read(template_path)
      html.sub!('##CONTENT##', generate_toc_html)
      f = File.new(output_path, 'w')
      f.write(html)
      f.close
    end
    
    private
      def generate_toc_html
        html = ''
        @book.chapters.each do |chapter|
          html << "<p class\"noind\"><a href=\"#ch#{chapter.index}\">#{chapter.title}</a></p>\n"
        end
        html
      end
  end

end
