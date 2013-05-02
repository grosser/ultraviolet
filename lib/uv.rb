#encoding: ascii-8bit
require 'fileutils'
require 'textpow'
require 'uv/render_processor.rb'
require "uv/version"


module Uv
  class << self
    attr_accessor :render_path, :theme_path, :syntax_path, :default_style, :syntaxes
  end

  self.syntax_path   = Textpow.syntax_path
  self.render_path   = File.join(File.dirname(__FILE__), '..', 'render')
  self.theme_path    = File.join(render_path, 'xhtml', 'files', 'css')
  self.default_style = 'mac_classic'
  self.syntaxes      = {}
  
  def self.path
    result = []
    result << File.join(File.dirname(__FILE__), ".." )
  end

  def self.syntax_node_for(syntax)
    if @syntaxes.key?(syntax)
      @syntaxes[syntax]
    else
      @syntaxes[syntax] = Textpow.syntax(syntax) || raise(ArgumentError, "No syntax found for #{syntax}")
    end
  end

  def self.copy_files(output, output_dir)
    Uv.path.each do |dir|
      dir_name = File.join( dir, "render", output, "files" )
      FileUtils.cp_r( Dir.glob(File.join( dir_name, "." )), output_dir ) if File.exists?( dir_name )
    end
  end

  def self.syntaxes
    Dir.glob( File.join(@syntax_path, '*.syntax') ).collect do |f| 
      File.basename(f, '.syntax')
    end
  end

  def self.themes
    Dir.glob( File.join(@theme_path, '*.css') ).collect do |f| 
      File.basename(f, '.css')
    end
  end

  def self.syntax_for_file(file_name)
    # get first non-empty line
    first_line = ""
    File.open( file_name, 'r' ) { |f|
      while (first_line = f.readline).strip.size == 0; end
    }


    # find syntax by file-extension
    result = []
    self.syntaxes.each do |key|
      syntax = self.syntax_node_for(key)
      assigned = false
      if syntax.fileTypes
        syntax.fileTypes.each do |t|
          if t == File.basename( file_name ) || t == File.extname( file_name )[1..-1]
            result << [key, syntax]
            assigned = true
            break
          end
        end
      end
      unless assigned
        if syntax.firstLineMatch && syntax.firstLineMatch =~ first_line
          result << [key, syntax]
        end
      end
    end
    result
  end

  def self.parse(text, output = "xhtml", syntax_name = nil, line_numbers = false, render_style = nil, headers = false)
    RenderProcessor.load(output, render_style, line_numbers, headers) do |processor|
      syntax_node_for(syntax_name).parse(text, processor)
    end.string
  end

  def self.debug(text, syntax_name)
    syntax_node_for(syntax_name).parse(text, Textpow::DebugProcessor.new)
  end
end
