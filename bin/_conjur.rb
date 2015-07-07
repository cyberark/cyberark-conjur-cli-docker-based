#!/usr/bin/env ruby

class ConjurCompletion
  def initialize()
    @line=ENV["COMP_LINE"]
    @words=@line.split(" ")
    @point=ENV["COMP_POINT"].to_i
    @current_word=@line.slice(0,@point).split(" ").length-1

    case "#{@words[1]} #{@words[2]}"
    when "group list"
      group_list @words[@current_word]
    else
      # this is not my mission and I want to return to shell
      exit 1
    end
  end

  def _flags(short='', long=[], assoc=[])
    short.split('').map do |flag|
      "-#{flag} "
    end +
    long.map do |flag|
      "--#{flag} "
    end +
    assoc.map do |flag|
      "--#{flag}="
    end
  end
  
  def group_list(word)
    _flags(short='ilors',
           long=['ids','no-ids','raw-annotations','no-raw-annotations'],
           assoc=['limit','offset','role','search']).select do |flag|
      flag.start_with? word
    end.each do |comp|
      printf "#{comp}\n"
    end
  end
end

if __FILE__ == $0
  ConjurCompletion.new
end
