require "config/environment"

MODEL_DIR   = File.join(RAILS_ROOT, "app/models")
FIXTURE_DIR = File.join(RAILS_ROOT, "test/fixtures")
RSPEC_DIR   = File.join(RAILS_ROOT, "spec/models")
RSPEC_FIXTURES = File.join(RAILS_ROOT, "spec/fixtures")

module AnnotateModels

  PREFIX = "# = Schema Information"
  POSTFIX = "########\n"
  
  # Simple quoting for the default column value
  def self.quote(value)
    case value
      when NilClass                 then "NULL"
      when TrueClass                then "TRUE"
      when FalseClass               then "FALSE"
      when Float, Fixnum, Bignum    then value.to_s
      # BigDecimals need to be output in a non-normalized form and quoted.
      when BigDecimal               then value.to_s('F')
      else
        value.inspect
    end
  end

  # Use the column information in an ActiveRecord class
  # to create a comment block containing a line for
  # each column. The line contains the column name,
  # the type (and length), and any optional attributes
  def self.get_schema_info(klass, header)
    info = ""
    info << "#{header}\n#\n"
    info << "# Table name: *#{klass.table_name}*\n#\n"
    
    max_size = klass.column_names.collect{|name| name.size}.max + 1
    klass.columns.each do |col|
      attrs = []
      attrs << "default(#{quote(col.default)})" if col.default
      attrs << "not null" unless col.null
      attrs << "primary key" if col.name == klass.primary_key

      col_type = col.type.to_s
      if col_type == "decimal"
        col_type << "(#{col.precision}, #{col.scale})"
      else
        col_type << "(#{col.limit})" if col.limit
      end 
      info << sprintf("#  %-#{max_size}.#{max_size}s:%-15.15s %s", col.name, col_type, attrs.join(", ")).rstrip
      info << "\n"
    end
    info << POSTFIX
  end

  # Add a schema block to a file. If the file already contains
  # a schema info block (a comment starting
  # with "Schema as of ..."), remove it first.

  def self.annotate_one_file(file_name, info_block)
    if File.exist?(file_name)
      content = File.read(file_name)

      # Remove old schema info
      if content.index(PREFIX) && content.index(POSTFIX)
        content.sub!(/^#{PREFIX}.*?\n(#.*\n)*#{POSTFIX}/, info_block)
      else
        content = info_block + content
      end

      # Write it back
      File.open(file_name, "w") { |f| f.puts content }
    end
  end
  
  # Given the name of an ActiveRecord class, create a schema
  # info block (basically a comment containing information
  # on the columns and their types) and put it at the front
  # of the model and fixture source files.

  def self.annotate(path, klass, header)
    info = get_schema_info(klass, header)
    
    annotate_one_file(path, info)
    
    if File.join(RAILS_ROOT, "spec")
      rspec_file_name = File.join(RSPEC_DIR, klass.name.underscore + "_spec.rb")
      annotate_one_file(rspec_file_name, info)
      
      rspec_fixture = File.join(RSPEC_FIXTURES, klass.table_name + ".yml")
      annotate_one_file(rspec_fixture, info)
    end

    Dir.glob(File.join(FIXTURE_DIR, "**", klass.table_name + ".yml")) do | fixture_file_name |
      annotate_one_file(fixture_file_name, info)
    end
  end

  # Return a list of the model files to annotate. If we have 
  # command line arguments, they're assumed to be either
  # the underscore or CamelCase versions of model names.
  # Otherwise we take all the model files in the 
  # app/models directory.
  def self.get_model_names
    models = ARGV.dup
    models.shift
    
    if models.empty?
      Dir.chdir(MODEL_DIR) do 
        models = Dir["**/*.rb"]
      end
    end
    models
  end

  # We're passed a name of things that might be 
  # ActiveRecord models. If we can find the class, and
  # if its a subclass of ActiveRecord::Base,
  # then pas it to the associated block
  def self.do_annotations
    header = PREFIX.dup
    version = ActiveRecord::Migrator.current_version rescue 0
    
    self.get_model_names.each do |path|
      begin
        path = MODEL_DIR+"/"+ path
        class_name = File.basename(path).sub(/\.rb$/,'').camelize
        
        klass = Object.const_get(class_name)
        if klass < ActiveRecord::Base && !klass.abstract_class?
          puts "Annotating #{class_name}"
          self.annotate(path, klass, header)
        else
          puts "Skipping #{class_name}"
        end
      rescue Exception => e
        puts "Unable to annotate #{class_name}: #{e.message}"
      end
      
    end
  end
end
