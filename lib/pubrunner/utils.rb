module Pubrunner
  class Utils
    class << self

      # Removes all files within a directory, and all files within any subdirectory, recursively.
      #   Note: this method does *not* delete subdirectories or the directory itself.
      def clean_folder(dir)
        Dir.foreach(dir) do |f|
          path = File.join(dir, f)
          if f == '.' or f == '..' or f == '.gitignore' then next
          elsif File.directory?(path) then clean_folder(path)
          else FileUtils.rm( path )
          end
        end      
      end

    end
  end
end