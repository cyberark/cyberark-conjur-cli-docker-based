#!/usr/bin/env ruby

require 'json'
require 'conjur/cli'

class ConjurCompletion
  def initialize (line, point)
    @line=line
    @words=tokenize_cmd @line
    @point=point
    @current_word=(tokenize_cmd @line.slice(0,@point)).length-1
    # fix arrays for empty "current word"
    # ie "conjur group list "
    if @line.match /[ =]$/ then
      @words << ''
      @current_word += 1
    end

    index = 1
    cmd = Conjur::CLI
    loop do
      word = @words[index]
      sub = subcommands cmd
      if sub.has_key? word.to_sym
        cmd = cmd.commands[word.to_sym]
        index += 1
      else
        break
      end
    end

    candidates = compgen ((_subcommands cmd) + (_flags cmd))    
    puts candidates.join "\n"
  end

  def subcommands cmd
    cmd.commands.select do |_, c|
      c.nodoc.nil?
    end
  end

  def conjur_cmd
    ENV['CONJUR_CMD'] or 'conjur'
  end
  
  def tokenize_cmd line
    line.split(/ |(?<==)/)
  end

  public
  def compgen completions
    completions.flatten!
    word = @words[@current_word]
    if word == '' and completions.all? { |c| c.start_with? '-' }
      []
    else
      completions.select do |candidate|
        candidate.start_with? word and
          candidate != word
      end.map do |candidate|
        "#{candidate}#{' ' if not candidate.end_with? '='}"
      end
    end
  end

  def _subcommands cmd
    (subcommands cmd).keys.map(&:to_s)
  end

  def _flags cmd
    cmd.flags.values.map do |flag|
      candidates = [flag.name]
      if flag.aliases
        candidates += flag.aliases
      end
      candidates.map do |c|
        "-#{'-' if c.length > 1}#{c}#{'=' if c.length > 1}"
      end
    end + cmd.switches.values.map do |switch|
      candidates = [switch.name]
      if switch.aliases
        candidates += switch.aliases
      end
      candidates.map do |c|    
        "-#{'-' if c.length > 1}#{c}"
      end
    end
  end

  def _role
    roles = (JSON.load `#{conjur_cmd} role memberships`).map do |role|
      role.split(':').drop(1).join(':')
    end
  end
  
  def _group
    groups = (JSON.load `#{conjur_cmd} group list`).map do |group|
      group['id'].split(':').drop(2)
    end
  end  
end

# execute using environment if called as a script
if Pathname.new(__FILE__).basename == Pathname.new($0).basename
  ConjurCompletion.new ENV['COMP_LINE'], ENV['COMP_POINT'].to_i
end
