require 'yaml'
require 'fileutils'

module Pubrunner

  class CommandLine
    
    def initialize(working_directory, argv)
      @working_directory = working_directory
      @argv = argv
      @global_config_path = File.join(ENV['HOME'], '.pubrunner')
      @global_config = load_global_config
      load_plugins
      start
    end
    
    def start
      if @argv.empty?
        command = 'go'
      else
        command = @argv[0]
      end
      case command
      when 'new', 'create'
        path_or_name = @argv[1]
        if path_or_name.nil?
          puts "Please specify a project name, for example:\n"
          puts "   pubrunner new my_new_book\n"
          exit
        end
        project_dir = File.join(@working_directory, path_or_name)
        if File.directory?(project_dir)
          puts "Directory already exists: #{project_dir}"
          puts "Exiting"
          exit
        end
        parts = File.split(path_or_name)
        if 1 == parts.size
          project_name = parts[0]
        else
          project_name = parts.last
        end
        Dir.mkdir(project_dir)
        templates_dir = File.join(project_dir, 'templates')
        output_dir = File.join(project_dir, 'output')
        project_config_yml = File.join(project_dir, 'config.yml')
        document_filename = "#{project_name}.txt"
        document_path = File.join(project_dir, document_filename)
        Dir.mkdir(templates_dir)
        Dir.mkdir(output_dir)
        pubrunner_dir = File.join(ENV['HOME'], 'pubrunner') # just temporary
        fixtures_dir = File.join(pubrunner_dir, 'test', 'fixtures')
        kindle_template = File.join(fixtures_dir, 'kindle_template.html')
        pdf_template = File.join(fixtures_dir, 'pdf_template.html')
        config_yml = File.join(fixtures_dir, 'config.yml')
        example_txt = File.join(fixtures_dir, 'example.txt')
        # Copy template files
        FileUtils.copy(kindle_template, templates_dir)
        FileUtils.copy(pdf_template, templates_dir)
        FileUtils.copy(example_txt, project_dir)
        # Inject a custom config.yml setting "document"
        File.open(project_config_yml, 'w') { |f| f.write("document: #{document_filename}\n") }
        config_default = IO.read(config_yml)
        # Append the default config.yml
        File.open(project_config_yml, 'a') {|f| f.write(config_default) }
        # Touch the document
        FileUtils.touch(document_path)
        puts "\nCreated project: #{project_name}"
        puts "\nThe following files were generated:"
        puts "-- #{project_name}"
        puts "   |- config.yml - contains project settings (author, title, etc)"
        puts "   |- #{document_filename} - your document"
        puts "   |- example.txt - example document (see how pubrunner formatting works)"
        puts "   \\- output - folder where pubrunner will place generated files (PDFs, Kindle HTML, .mobi files, etc)"
        puts "   \\- templates"
        puts "      |- kindle_template.html - Kindle template document (plain, editable HTML)"
        puts "      |- pdf_template.html - PDF template document (plain, editable HTML)"
        puts "\n"
        
      when 'go', 'run', 'process', 'execute'
        path_or_name = @argv[2]
        if path_or_name.nil?
          # Execute Pubrunner on current working directory
          project_dir = @working_directory
        else
          # TODO: make work for full paths
          project_dir = File.join(@working_directory, path_or_name)
        end
        if !File.directory?(project_dir)
          puts "Specified path or project name does not exist: #{project_dir}"
          exit
        end
        config_yml = File.join(project_dir, 'config.yml')
        if !File.exist?(config_yml)
          puts "A 'config.yml' file was not found in directory: #{@working_directory}"
          puts "The specified target does not appear to be a valid pubrunner project"
          exit
        end
        config = YAML.load_file(config_yml)
        if config['document'].nil?
          puts "config.yml file is missing a required key: document"
          exit
        end
        document_filename = config['document']
        # project name: "Foo" if filename is "Foo.txt" or "Foo Bar" if "Foo Bar.txt"
        project_name = File.basename(document_filename, File.extname(document_filename))
        document_path = File.join(project_dir, document_filename)
        if !File.exist?(document_path)
          puts "Document does not exist: #{document_path}"
          puts "The document filename is specified as the 'document' key in config.yml."
          exit
        end

        output_path = File.join(project_dir, 'output')
        if !File.directory?(output_path)
          puts "Creating output folder: #{output_path}"
          File.mkdir(output_path)
        end
        auto_increment = config['auto_increment_chapter_names'] ? config['auto_increment_chapter_names'] : false
        if config['strict']
          puts "Strict mode is enabled. Checking markup ..."
          document_text = IO.read(document_path)
          mc = Pubrunner::MarkupChecker.new(document_text)
          if mc.warnings_count > 0
            puts "Markup warnings count: #{mc.warnings_count}"
            puts "Fix markup warnings before proceeding. (Or set 'strict' to false in config.yml)"
            exit
          end
        elsif config['strict'] && (false == config['strict'])
          puts "Strict mode is disabled. Results may be wonky ..."
        end
        processor = Processor.new(document_path, auto_increment)
        book = processor.process
        # Build an environment variable that looks something like:
        #   {'working_directory' => '/some/dir',
        #    'argv' => ['the', 'arguments'],
        #    'global_config' => (~/.pubrunner file parsed from YAML into a Hash),
        #    'config' =>  (config file parsed from YAML into a Hash),
        #    'project_name' => 'Some Project',
        #    'project_directory' => '/path/to/project/directory',
        #    'document_path' => '/full/path/to/document.txt',
        #    'book' => ( a pre-processed book object, using the autoincrement chapter settings, etc )
        #   }
        @environment = {
          'working_directory' => @working_directory,
          'argv' => @argv,
          'global_config' => @global_config,
          'config' =>  config,
          'project_name' => project_name,
          'project_directory' => project_dir,
          'document_path' => document_path,
          'book' => book
          }
        if config['generate_toc']
          toc_path = File.join(project_dir, 'output', 'toc.html')
          toc_template_path = File.join(project_dir, 'templates', 'toc_template.html')
          FileUtils.rm(toc_path) if File.exist?(toc_path)
          toc_gen = TocGenerator.new(book)
          toc_gen.generate(toc_template_path, toc_path)
          if File.exist?(toc_path)
            puts "Generated HTML Table of Contents file: #{toc_path}"
          else
            puts "There was a problem generating the HTML Table of Contents file."
          end
        end
        kindle_output_path = File.join(project_dir, 'output', "#{project_name}_kindle.html")
        if config['kindle']
          puts "Starting kindle HTML output generation ..."
          kindle_transformer = Transformer::Kindle.new(book)
          kindle_book = kindle_transformer.transform
          kindle_book.title = config['title']
          kindle_book.author = config['author']
          
          template_path = File.join(project_dir, 'templates', 'kindle_template.html')
          # Save the generated Kindle HTML file
          Transformer::Kindle.save(kindle_book, kindle_output_path, template_path)
          puts "Generated Kindle-ready HTML file: #{output_path}"
        end
        if config['kindlegen_mobi']
          mobi_path = File.join(project_dir, 'output', "#{project_name}_kindle.mobi")
          unless File.exist?(kindle_output_path)
            raise RuntimeError, "Kindle HTML file does not exist. Expected path: #{kindle_output_path}"
          end
          FileUtils.rm(mobi_path) if File.exist?(mobi_path)
          Transformer::Kindle.kindlegen(kindle_output_path)
          if File.exist?(mobi_path)
            # We rename the .mobi path so it doesn't have the _kindle in the filename
            new_mobi_path = File.join(project_dir, 'output', "#{project_name}.mobi")
            FileUtils.mv(mobi_path, new_mobi_path)
            puts "Generated Kindle-compatible .mobi file via kindlegen: #{new_mobi_path}"           
          else
            puts "Mobi file was not generated. Perhaps 'kindlegen' is not in your path?"
          end
        end
        if config['pdf']
          puts "Starting HTML generation for creation of PDF ..."
          pdf_transformer = Transformer::Pdf.new(book)
          pdf_book = pdf_transformer.transform
          pdf_book.title = config['title']
          pdf_book.author = config['author']

          pdf_html_path = File.join(project_dir, 'output', "#{project_name}_pdf.html")
          pdf_path = File.join(project_dir, 'output', "#{project_name}_pdf.pdf")
          template_path = File.join(project_dir, 'templates', 'pdf_template.html')
          # Save the generated Kindle HTML file
          Transformer::Pdf.save(pdf_book, pdf_html_path, template_path)
          if File.exist?(pdf_html_path)
            puts "Generating PDF via Prince ..."
            Transformer::Pdf.generate_pdf(pdf_html_path)
            if File.exist?(pdf_path)
              new_pdf_path = File.join(project_dir, 'output', "#{project_name}.pdf")
              FileUtils.mv(pdf_path, new_pdf_path)
              puts "Generated PDF: #{new_pdf_path}"
            else
              puts "Failed to generate PDF. The Prince XML binary must be in your path for PDF generation to work."
            end
          end
        end
        if config['octopress']
          octo_dir = File.join(project_dir, 'output', 'octopress')
          FileUtils.mkdir(octo_dir) unless File.directory?(octo_dir)
          Pubrunner::Utils.clean_folder(octo_dir)
          puts "Starting Octopress post generation ..."

          octopress_transformer = Transformer::Octopress.new(book)          
          octopress_transformer.transform_and_save(octo_dir)
          posts_path = File.join(octo_dir, '*.html')
          puts "Pubrunner generated the following Octopress posts:"
          Dir[posts_path].each do |f|
            puts f
          end
        end
        if config['custom']
          # Possible formats for config['custom']
          #  A) Single class name, e.g.
          #       FooTransformer
          #   or
          #       ModuleName::MyCustomClass
          #  B) Comma-separated list of classes, e.g.
          #       FirstTransformer, AnotherTransformer
          #   or
          #       Foo::Bar::TransformerOne, YetAnotherTransformer
          #   etc
          
          custom_list = config['custom']
          klasses = custom_list.split(',')
          klasses.map! { |class_name| class_name.strip } # Remove trailing/leading spaces
          
          klasses.each do |class_name|
            # Call the "execute" method on each class. This is by convention, to simplify the plugin
            #   development process. The "execute" method takes a single param: the @environment variable.
            Utils.class_send(class_name, 'execute', @environment)
          end
        end
      when 'clean'
        config_yml = File.join(@working_directory, 'config.yml')
        if !File.exist?(config_yml)
          puts "this does not appear to be a valid pubrunner project directory"
          exit
        end
        output_dir = File.join(@working_directory, 'output')
        Pubrunner::Utils.clean_folder(output_dir)
      when 'wordcount', 'wc'
        config_yml = File.join(@working_directory, 'config.yml')
        if !File.exist?(config_yml)
          puts "A 'config.yml' file was not found in directory: #{@working_directory}"
          puts "The working directory does not appear to be a pubrunner project."
          exit
        end
        config = YAML.load_file(config_yml)
        if config['document'].nil?
          puts "config.yml file is missing a required key: document"
          exit
        end
        document_filename = config['document']
        document_path = File.join(@working_directory, document_filename)
        doc = IO.read(document_path)
        words = doc.split
        puts "Word count: #{words.size}"
      when 'zip'
        config_yml = File.join(@working_directory, 'config.yml')
        if !File.exist?(config_yml)
          puts "A 'config.yml' file was not found in directory: #{@working_directory}"
          puts "The working directory does not appear to be a pubrunner project."
          exit
        end
        config = YAML.load_file(config_yml)
        if config['document'].nil?
          puts "config.yml file is missing a required key: document"
          exit
        end
        document_filename = config['document']
        project_name = File.basename(document_filename, File.extname(document_filename))
        parent_dir = File.expand_path("..", @working_directory)
        zipfile_path = File.join(parent_dir, "#{project_name}.zip")
        FileUtils.rm( zipfile_path ) if File.exist?(zipfile_path)
        zip_cmd = "zip -r \"#{zipfile_path}\" \"#{@working_directory}\""
        puts "Zipping folder contents with command: #{zip_cmd}"
        out = `#{zip_cmd}`
        puts out
        if File.exist?(zipfile_path)
          puts "Pubrunner project contents zipped: #{zipfile_path}"
        else
          puts "There seems to have been a problem zipping project contents. Is there a 'zip' binary in your path?"
        end
      else
        puts "invalid command"
      end
    end
    
    def load_global_config
      return {} unless File.exist?(@global_config_path)
      config = {}
      config = YAML.load_file(@global_config_path)
      if !config.is_a?(Hash)
        raise GlobalConfigError, "Your global configuration file appears malformed:\n#{@global_config_path}\nIt should be a YAML-encoded Hash object."
      end
      config ||= {}  # config should not be nil
      config
    end
    
    def load_plugins
      plugin_dir = (@global_config['plugin_directory'] || '').strip
      return unless !plugin_dir.empty?
      if !File.directory?(plugin_dir)
        puts "The plugin directory defined in your global ~/.pubrunner config file does not appear to be a valid directory."
        puts "Skipping plugin loading ..."
        return
      end
      plugin_mask = File.join(plugin_dir, '*.rb')
      plugins = []
      Dir.glob(plugin_mask).each do |f|
        # Add the plugin path to the plugins array if it's not a directory
        plugins.push(f) if !File.directory?(f)
      end
      plugins.each do |f|
        require f
        puts "Loaded plugin: #{f}"
      end

    end
    
  end
  
end
