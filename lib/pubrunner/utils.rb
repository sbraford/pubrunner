module Pubrunner

  class Utils
    
    # Converts a block of text like:
    #     "She dugga dugga ..."
    # To:
    #     &ldquo;She dugga dugga ...&rdquo;
    #
    def self.quotes_to_entities(string)
      new_string = string
      num_quotes = string.scan("\"").count
      i = 0
      num_quotes.times do
        entity = (i.even?) ? '&ldquo;' : '&rdquo;'
        new_string.sub!(/"/, entity)
        i += 1
      end
      new_string
    end
    
    # Usage:
    # Utils.mdashify("So it was true--at last--he realized.") => "So it was true&mdash;at last&mdash;he realized."
    def self.mdashify(string)
      string.gsub("--", "&mdash;")
    end
    
    # Removes all files within a directory, and all files within any subdirectory, recursively.
    #   Note: this method does *not* delete subdirectories or the directory itself.
    def self.clean_folder(dir)
      Dir.foreach(dir) do |f|
        path = File.join(dir, f)
        next if ('.' == f) || ('..' == f) || ('.gitignore' == f)
        if File.directory?(path)
          clean_folder(path)
        else
          FileUtils.rm( path )
        end
      end      
    end
      
    # Used by CommandLine to execute plugins
    def self.class_send(class_name, method, *args)
      return nil unless Object.const_defined?(class_name)
      c = Object.const_get(class_name)
      c.respond_to?(method) ? c.send(method, *args) : nil
    end

  end
end
