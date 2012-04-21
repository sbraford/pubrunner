module Pubrunner
  module Transformer

    class Pdf
      
      def initialize(book)
        @book = book
      end
      
      # Returns a Book object whose contents have been transformed
      #  to PDF-friendly html
      def transform(chapter_template = nil)
        chapter_template ||= Pdf.default_chapter_template
        pdf_book = Book.new(@book.title, @book.author)
        pdf_book.chapter_template = chapter_template
        @book.chapters.each do |chapter|
          pdf_ch = Chapter.new(chapter.title)
          pdf_book.add_chapter(pdf_ch)
          marked_up_content = PubdownProcessor.transform_pubdown(chapter.content)
          marked_up_content.lines.each do |line|

            line.rstrip!
            if '' == line
              pdf_ch.content << "\n"
              next
            end

            if line[0] == "\t"
              # Line begins with tab
              line.lstrip!
              line_new = '<p>' + line + '</p>'
            else
              line_new = '<br/><p class="noind">' + line + '</p>'
            end
            
            pdf_ch.content << (line_new + "\n")
          end
        end
        
        pdf_book
      end
      
      # Generates a PDF using Prince XML
      def self.generate_pdf(html_file_path)
        dir = File.dirname(html_file_path)
        ext = File.extname(html_file_path) # .html or .htm
        basename = File.basename(html_file_path, ext)
        output_path = File.join(dir, "#{basename}.pdf")
        out = `prince "#{html_file_path}" -o "#{output_path}"`
        puts out
      end
      
      # Generates the meat of the book (no template)
      def self.generate_meat(pdf_book)
        html = ''
        pdf_book.chapters.each do |chapter|
          chapter_html = pdf_book.chapter_template.sub('##CHAPTER_TITLE##', chapter.title)
          html << chapter_html
          html << chapter.content
          html << "\n"
        end
        html
      end
      
      def self.generate_sandwich(pdf_book, template_path)
        meat = Pdf.generate_meat(pdf_book)
        raise FileNotFoundError, "Specified Kindle template path does not exist: #{template_path}" unless File.exist?(template_path)
        bread = IO.read(template_path)
        # String replacements
        # Books can have nil titles & authors
        title = pdf_book.title || ''
        author = pdf_book.author || ''
        bread.gsub!('##TITLE##', title)
        bread.gsub!('##AUTHOR##', author)
        bread.gsub!('##CONTENT##', meat)
        bread
      end
      
      def self.save(pdf_book, filepath, template_path)
        sandwich = Pdf.generate_sandwich(pdf_book, template_path)
        f = File.new(filepath, 'w')
        f.write(sandwich)
        f.close
      end
      
      # Expects an already-transformed pdf_book
      def self.save_meat(pdf_book, filepath)
        html = Pdf.generate_meat(pdf_book)
        f = File.new(filepath, 'w')
        f.write(html)
        f.close
      end
      
      def self.default_chapter_template
        "\n<h2 class=\"chapter\">##CHAPTER_TITLE##</h2>\n"
      end
      
    end

  end
end