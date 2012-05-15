module Pubrunner
  module Transformer
    
    class Kindle
      
      def initialize(book)
        @book = book
      end
      
      # Returns a Book object whose contents have been transformed
      #  to Kindle-friendly html
      def transform(chapter_template = nil)
        chapter_template ||= Kindle.default_chapter_template
        kindle_book = Book.new(@book.title, @book.author)
        kindle_book.chapter_template = chapter_template
        @book.chapters.each do |chapter|
          kindle_ch = Chapter.new(chapter.title, nil, chapter.index)
          kindle_book.add_chapter(kindle_ch)
          marked_up_content = PubdownProcessor.transform_pubdown(chapter.content)
          marked_up_content.lines.each do |line|

            line.rstrip!
            if '' == line
              kindle_ch.content << "\n"
              next
            end

            if line[0] == "\t"
              # Line begins with tab
              line.lstrip!
              line_new = '<p>' + line + '</p>'
            else
              line_new = '<br/><p class="noind">' + line + '</p>'
            end
            
            kindle_ch.content << (line_new + "\n")
          end
        end
        
        kindle_book
      end
      
      # Generates the meat of the book (no template)
      def self.generate_meat(kindle_book)
        html = ''
        kindle_book.chapters.each do |chapter|
          chapter_html = kindle_book.chapter_template.dup
          chapter_html.sub!('##CHAPTER_TITLE##', chapter.title)
          chapter_html.sub!('##CHAPTER_INDEX##', chapter.index.to_s)
          
          html << chapter_html
          html << chapter.content
          html << "\n"
        end
        html
      end
      
      def self.generate_sandwich(kindle_book, template_path)
        meat = Kindle.generate_meat(kindle_book)
        raise "Specified Kindle template path does not exist: #{template_path}" unless File.exist?(template_path)
        bread = IO.read(template_path)
        # String replacements
        # Books can have nil titles & authors
        title = kindle_book.title || ''
        author = kindle_book.author || ''
        bread.gsub!('##TITLE##', title)
        bread.gsub!('##AUTHOR##', author)
        bread.gsub!('##CONTENT##', meat)
        bread
      end
      
      def self.save(kindle_book, filepath, template_path)
        sandwich = Kindle.generate_sandwich(kindle_book, template_path)
        f = File.new(filepath, 'w')
        f.write(sandwich)
        f.close
      end
      
      # Expects an already-transformed HTML kindle book
      def self.save_meat(kindle_book, filepath)
        html = Kindle.generate_meat(kindle_book)
        f = File.new(filepath, 'w')
        f.write(html)
        f.close
      end
      
      def self.kindlegen(target_path)
        unless File.exists?(target_path)
          raise FileNotFoundError, "kindlegen target file not found: #{target_path}"
        end
        out = `kindlegen "#{target_path}"`
        puts out
      end
            
      def self.default_chapter_template
        <<-EOM
<mbp:pagebreak />
<a name="ch##CHAPTER_INDEX##"></a>
<p height="3em">&nbsp;</p>
<h2>##CHAPTER_TITLE##</h2>
<p height="3em">&nbsp;</p>
EOM
      end

    end
  end
end