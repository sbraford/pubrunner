module Pubrunner

  class MarkupChecker
    attr_reader :warnings_count
    
    def initialize(content)
      @content = content
      @warnings_count = 0
      check_strong
      check_emphasis
    end
    
    # Make sure we have pairs of **'s
    def check_strong
      i = 1
      @content.each_line do |line|
        matches = line.scan(/\*\*/)
        if !matches.empty?
          if matches.size.odd?
            warn "Line #{i}: uneven number of **'s"
            @warnings_count += 1
          end
        end
        i += 1
      end
    end
    
    # Make sure we have pairs of *'s
    def check_emphasis
      i = 1
      single_ast_count = 0
      @content.each_line do |line|
        size = line.size
        j = 0
        while j < size do
          char = line[j]
          # Ghetto regex. Don't count the * if it's part of a ** pair
          if char == '*'
            if !(line[j+1] == '*') && !('*' == line[j-1])
              single_ast_count += 1
            end
          end
          j += 1
        end

        if single_ast_count.odd?
          warn "Line #{i}: uneven number of *'s"
          @warnings_count += 1
        end
        i += 1
      end
    end

  end
end