# -*- encoding : utf-8 -*-
module Webvtt
  class File

    attr_accessor :file, :cues

    def initialize(input_file,filemode=true)
      if filemode
        if input_file.is_a?(String)
          input_file = input_file.encode('UTF-8')
          if ::File.exist?(input_file)
            @file = ::File.read(input_file)
          else
            @file = input_file
          end
        elsif input_file.is_a?(::File)
          @file = input_file.read
        else
          raise
        end
        @cues = []
        parse
      else
        # load string directly
        @file=input_file
        @cues = []
        parse
      end
    end

    def parse
      remove_bom
      if !webvtt_line?(file.lines.first)
        raise Webvtt::MalformedError
      end
      collected_lines = []
      file_lines = file.dup.lines.to_a

      file_lines.each_with_index do |line,index|
        line.chomp!

        next if webvtt_line?(line)
        if line.empty?
          if !collected_lines.empty? and !notes?(collected_lines)
            add_a_cue(collected_lines)
          end
          collected_lines = []
        elsif !line.empty? and file_lines.length == (index + 1)
          collected_lines << line
          add_a_cue(collected_lines)
        else
          collected_lines << line
        end
      end
    end

    def webvtt_line?(line)
      line[0,6] == 'WEBVTT'
    end

    def remove_bom
      file.gsub!("\uFEFF", '')
    end
    
    
    def to_srt
      out = []
      @cues.each_with_index do |l, i|
        out << "#{i + 1}"
        out << '%s --> %s' % [l.start, l.end]
        out << (l.text ? l.text.gsub('|', endl) : ' ') + endl
      end
      out.join(endl)
    end
    
    def endl
      "\n"      
    end

private

    def add_a_cue(collected_lines)
      cue_opts = {}
      if collected_lines.first.include?('-->')
        cue_opts[:identifier] = nil
        cue_opts[:cue_line] = collected_lines.first
      elsif collected_lines[1].include?('-->')
        cue_opts[:identifier] = collected_lines.first
        cue_opts[:cue_line] = collected_lines[1]
      end
      cue_opts[:text] = collected_lines[2..-1].join("\n")
      begin
        cues << Cue.new(cue_opts)
      rescue
        puts "Error with new cue #{cue_opts.inspect}"        
      end
    end

    def notes?(collected_lines)
      if collected_lines.first.match(/^NOTE/)
        true
      else
        false
      end
    end

  end
end
