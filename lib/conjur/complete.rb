#
# Copyright (C) 2015 Conjur Inc.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
require 'conjur/cli'
require 'shellwords'

# Class for generating `conjur` bash completions
class Conjur::CLI::Complete
  attr_reader :line, :words, :current_word, :commands, :switch_words,
              :flag_words, :arg_words, :command_words
  def initialize line, point=nil
    @line = line
    @words = tokenize_cmd @line
    point ||= @line.length
    @current_word=(tokenize_cmd @line.slice(0,point)).length-1
    # fix arrays for empty "current word"
    # ie "conjur group list "
    if @line.match(/[ =]$/)
      @words << ''
      @current_word += 1
    end
    @commands,
    @switch_words,
    @flag_words,
    @arg_words = parse_command @words, @current_word
    @command_words = @commands
                     .drop(1)
                     .map(&:name)
                     .map(&:to_s)
                     .unshift('conjur')
  end

  # Generate array of subcommands for which documentation is not hidden
  #
  # @param cmd [Conjur::CLI::Command] the command to search
  # @return [Array] the subcommands
  def subcommands cmd
    cmd.commands.select do |_, c|
      c.nodoc.nil?
    end
  end

  # Generate array of symbols representing switches for +cmd+ and
  # their aliases
  #
  # @param cmd [Conjur::CLI::Command] the command to search
  # @return [Array] the symbols representing switches and their aliases
  def switches cmd
    cmd.switches.map { |_,switch|
      [switch.name] + (switch.aliases or [])
    }.flatten
  end

  # Split line according on spaces and after '='
  #
  # @param line [String] to split
  # @return [Array] the substrings
  def tokenize_cmd line
    line.split(/ |(?<==)/)
  end

  def flag_to_sym flag
    flag.match(/--?([^=]+)=?/)[1].to_sym
  end

  def parse_command words, current_word
    command = Conjur::CLI
    commands = [command]
    switches = []
    flags = []
    arguments = []
    index = 1
    loop do
      word = words[index]
      case classify_word word, command
      when :switch
        switches.push word
      when :flag
        flags.push [word, words[index+1]]
        index += 1
      when :subcommand
        command = command.commands[word.to_sym]
        commands.push command
      when :argument
        arguments.push word
      end
      index += 1
      break if index >= current_word
    end
    return commands, switches, flags, arguments
  end

  def classify_word word, command
    if word.start_with? '-'
      sym = flag_to_sym word
      if switches(command).member? sym
        :switch
      else
        :flag
      end
    else
      if subcommands(command).has_key? word.to_sym
        :subcommand
      else
        :argument
      end
    end
  end
  
  def complete kind
    kind = kind.to_s.downcase.gsub(/[^a-z]/, '')
    case kind
    when 'resource'
      complete_resource
    when 'role'
      complete_role
    when 'file'
      complete_file @words[@current_word]
    when 'hostname'
      complete_hostname
    else
      complete_resource kind if [
        'group',
        'user',
        'variable',
        'host',
        'layer',
      ].member? kind
    end or []
  end
  
  # generate completions for the switches and flags of a Conjur::CLI::Command
  #
  # @param cmd [Conjur::CLI::Command] command for which to search for flags
  #   and switches
  # @return [Array] completion words
  def complete_flags cmd
    cmd.flags.values.map do |flag|
      candidates = [flag.name]
      candidates += flag.aliases if flag.aliases
      candidates.map do |c|
        "-#{'-' if c.length > 1}#{c}#{'=' if c.length > 1}"
      end
    end + cmd.switches.values.map do |switch|
      candidates = [switch.name]
      candidates += switch.aliases if switch.aliases
      candidates.map do |c|
        "-#{'-' if c.length > 1}#{c}"
      end
    end
  end

  def complete_args cmd, prev, num_args
    kind=nil
    if prev.start_with? '-'
      flag_name=flag_to_sym prev
      flag = cmd.flags[flag_name]
      desc = flag.argument_name if defined? flag.argument_name
      kind = desc.to_s.downcase
    else
      desc = cmd.arguments_description if defined? cmd.arguments_description
      kind = desc.to_s.downcase.split[num_args-1]
    end
    complete kind
  end

  def complete_resource resource_kind=nil
    Conjur::Command.api.resources({kind: resource_kind})
      .map do |r|
      res = Resource.new r.attributes['id']
      if resource_kind
        res.name
      else
        res.shellescape
      end
    end
  end

  def complete_role
    Conjur::Command.api.current_role.all
      .map { |r| Resource.new(r.roleid) }
      .reject { |r| r.kind.start_with? '@' }
      .map(&:shellescape)
  end

  def complete_file word
    # use Bash's file completion for compatibility
    `bash -c "compgen -f #{word}"`.shellsplit
  end

  def complete_hostname
    `bash -c "compgen -A hostname"`.shellsplit
  end

  def to_ary
    word = @words[@current_word]
    prev = @words[@current_word-1]
    if word.start_with? '-'
      complete_flags @commands.last
    else
      (subcommands @commands.last).keys.map(&:to_s) +
        (complete_args @commands.last, prev, @arg_words.length)
    end.flatten
      .select do |candidate|
      candidate.start_with? word end
      .map do |candidate|
      "#{candidate}#{' ' if not candidate.end_with? '='}" end
  end
end

class Conjur::CLI::Complete::Resource
  attr_reader :account, :kind, :name
  attr_accessor :include_account
  def initialize resource_string, include_account=false
    @include_account = include_account
    fields = resource_string.split ':'
    raise ArgumentError.new "too many fields (#{resource_string})" if fields.length > 3
    fields.unshift nil while fields.length < 3
    @account, @kind, @name = fields
  end

  def to_ary
    [(@account if @include_account), @kind, @name].reject { |a| a.nil? }
  end

  def to_s
    to_ary.join ':'
  end

  def shellescape
    to_ary.join '\:'
  end
end
