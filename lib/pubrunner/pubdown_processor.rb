module Pubrunner
  class PubdownProcessor

    def self.transform_pubdown(content)
      PubdownProcessor.emphasize(PubdownProcessor.strongify(PubdownProcessor.strip_right_whitespace_and_add_linebreaks(content)))
    end

    def self.strip_right_whitespace_and_add_linebreaks(content)
      stripped = ''
      content.each_line do |line|
        stripped += line.rstrip + "\n"
      end
      stripped
    end

    # Swap ** for <b> pairs
    def self.strongify(content)
      content_new = ''
      content.each_line do |line|
        matches = line.scan(/\*\*/)
        match_count = matches.size
        num_pairs = matches.size / 2
        num_pairs.times do
          line.sub!(/\*\*/, '<b>')
          line.sub!(/\*\*/, '</b>')
        end
        content_new += line
      end
      content_new
    end

    # Swap * for <em>'s and </em>'s
    # - we don't have to worry about **'s anymore, so just replace any * pairs with <em>'s
    def self.emphasize(content)
      content_new = ''
      content.each_line do |line|
        matches = line.scan(/\*/)
        match_count = matches.size
        num_pairs = matches.size / 2
        num_pairs.times do
          line.sub!(/\*/, '<em>')
          line.sub!(/\*/, '</em>')
        end
        content_new += line
      end
      content_new
    end

  end
end
