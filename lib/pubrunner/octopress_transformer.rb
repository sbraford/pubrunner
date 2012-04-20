module Pubrunner
  module Transformer
    
    class Octopress
      
      attr_accessor :post_layout, :post_date, :comments
      
      def initialize(book)
        @book = book
        @post_layout = 'post'
        @post_date = Time.now
        @comments = true
        # Octopress, by default, shows the most recent posts first. In Archive listings,
        #   it will also show the most recent posts first. To "trick" Octopress into
        #   displaying Chapters One => X, in the order of One, Two, etc ... by default
        #   we will set the *first* chapter as the most recently posted, and the
        #   *last* chapter as the oldest.
        #     Example:
        #   Chapter One - 2012-04-05 20:15
        #   Chapter Two - 2012-04-05 20:14
        #    ....
        @reverse_chronological = true
      end
      
      # Transforms a Pubrunner::Book into Octopress blog entry chapters
      #    Note: we need to transform the markup from Pubdown to HTML. Although Octopress
      #    supports Markdown, it does not handle tab-indentation well and Pubdown-formatted
      #    text ends up looking like bunk.
      def transform_and_save(target_directory)
        chapter_date = @post_date
        @book.chapters.each do |chapter|
          post = Octopress.front_matter
          post.sub!('##LAYOUT##', @post_layout)
          post.sub!('##POST_TITLE##', chapter.title)
          post.sub!('##DATE##', chapter_date.strftime("%Y-%m-%d %H:%M"))
          post.sub!('##COMMENTS##', @comments.to_s)
          
          post << PubdownProcessor.transform_pubdown(chapter.content)
          
          post_filename = octopressify_filename(chapter.title, chapter_date)
          
          post_path = File.join(target_directory, post_filename)
          f = File.new(post_path, 'w')
          f.write(post)
          f.close
        
          if @reverse_chronological
            chapter_date = chapter_date - 60  # Subtract 60 seconds (1 Minute) from the post date
          else
            chapter_date = chapter_date + 60  # Add 60 seconds (1 Minute) to each post date
          end
        end
        
      end
      
      def octopressify_filename(title, date)
        title = title.downcase
        title.gsub!(/[\s]/, '-')
        title.gsub!(/[^a-zA-Z0-9-]/, '')
        date_formatted = date.strftime("%Y-%m-%d")
        "#{date_formatted}-#{title}.html"
      end
      
      def self.front_matter
        <<-EOM
---
layout: ##LAYOUT##
title: ##POST_TITLE##
date: ##DATE##
comments: ##COMMENTS##
---
EOM
      end
    end

  end
end