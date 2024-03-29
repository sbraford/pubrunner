pubrunner_mask = File.join(File.dirname(__FILE__), 'pubrunner', '*.rb')
Dir[pubrunner_mask].each {|file| require file }

# require './pubrunner/command_line.rb'
# require 'pubrunner/command_line.rb'

module Pubrunner

  class Processor
    
    def initialize(path, auto_increment_chapter_names = false)
      @path = path
      @book = Book.new
      @auto_increment_chapter_names = auto_increment_chapter_names
    end
    
    # Processes a pubrunner-Markdown flavored file
    # - Returns a new Pubrunner::Book object
    def process
      doc = IO.read(@path)
      
      # Strip trailing whitespace and newlines
      lines = doc.lines.map { |line| line.rstrip }
      
      # Strip out all comments
      lines_new = []
      lines.each do |line|
        if (line.size >= 2) && (line[0,2] == '//')
          next
        end
        lines_new << line
      end
      lines = lines_new
      current_chapter_index = 0
      current_display_chapter_number = 0
      current_chapter = nil
      lines.each do |line|
        is_whitespace = ( '' == line )
        if (line.size > 0) && ('#' == line[0])
          # We have a new chapter
          current_chapter_index += 1
          force_chapter_title_name = false
          if (line.size > 1) && ('!' == line[1]) # If the line begins with "#!" -- force chapter title name
            force_chapter_title_name = true
          end

          if force_chapter_title_name
            chapter_name = line.slice(2, line.size).strip
          elsif @auto_increment_chapter_names
            current_display_chapter_number += 1
            chapter_name = "Chapter #{current_display_chapter_number}"
          else
            chapter_name = line.slice(1, line.size).strip
          end
          @book.add_chapter(current_chapter) if current_chapter
          current_chapter = Chapter.new(chapter_name, '', current_chapter_index)
          next
        end
        
        # We have a content line
        if current_chapter.nil? && !is_whitespace
          puts "warning: content appears before a chapter heading. content must go into a chapter bucket. content line text: #{line}"
          next
        end
        if current_chapter
          current_chapter.content << (line + "\n")
        end
      end
      
      # Add the last chapter
      @book.add_chapter(current_chapter) if current_chapter
      @book
    end
    
  end
  
  class Book
    attr_accessor :title, :author, :chapters, :chapter_template
    
    def initialize(title = nil, author = nil, chapters = nil)      
      @title = title
      @author = author
      chapters ||= []
      @chapters = chapters
    end
    
    def add_chapter(chapter)
      chapters << chapter
    end
    
    def check_markup(strict = nil)
      strict ||= false
      @chapters.each do |ch|
        mc = MarkupChecker.new(ch.content)
        if strict && (mc.warnings_count > 0)
          raise MarkupError, "#{mc.warnings_count} markup warnings. Strict mode enabled. Exiting..."
        end
      end
    end
    
  end
  
  class Chapter
    attr_accessor :title, :content, :index
    def initialize(title = nil, content = nil, index = nil)
      content ||= ''
      if !index.nil?
        raise RuntimeError, "Chapter index must be a non-negative number" unless index.integer? && (index >= 0)
      end
      @title, @content, @index = title, content, index
    end
    def ch_idx
      @index
    end
  end

  class MarkupError < RuntimeError
  end
  
  class FileNotFoundError < RuntimeError
  end

  class GlobalConfigError < RuntimeError
  end

end
