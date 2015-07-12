#!/usr/bin/env ruby

require 'json'

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

    candidates = case @words[1]
                 when 'audit'
                   audit
                 when 'authn'
                   authn
                 when 'group'
                   group
                 else
                   if @current_word == 1 then
                     compgen ['audit', 'authn', 'bootstrap', 'env',
                              'group', 'help', 'host', 'id',
                              'init', 'layer', 'plugin', 'policy',
                              'pubkeys', 'resource', 'role', 'script',
                              'user', 'variable'] +
                             (_flags short='', long=['help','version'])
                   else
                     # this is not my mission and I wish to return to shell
                     exit 1
                   end
                 end
    if candidates != nil then
      puts candidates.join "\n"
    end
  end

  def conjur_cmd
    ENV['CONJUR_CMD'] or 'conjur'
  end
  
  def tokenize_cmd line
    line.split(/ |(?<==)/)
  end

  def compgen(completions)
    word = @words[@current_word]
    completions.select do |candidate|
      candidate.start_with? word and
        candidate != word
    end.map do |candidate|
      if candidate.end_with? '='
      then candidate
      else candidate + ' '
      end
    end
  end

  def _flags (short='', long=[], assoc=[])
    short.split('').map do |flag|
      "-#{flag}"
    end +
      long.map do |flag|
      "--#{flag}"
    end +
      assoc.map do |flag|
      "--#{flag}="
    end
  end

  def _role
    roles = (JSON.load `#{conjur_cmd} role memberships`).map do |role|
      role.split(':').drop(1).join(':')
    end
    compgen roles
  end
  
  def _group
    groups = (JSON.load `#{conjur_cmd} group list`).map do |group|
      group['id'].split(':').drop(2)
    end
    compgen groups.flatten
  end

  def audit
    compgen ['all','resource','role']
  end

  def authn
    compgen ['authenticate', 'login', 'logout', 'whoami']
  end
  
  def group
    case @words[2]
    when 'create'
      group_create
    when 'list'
      group_list
    when 'members'
      group_members
    else
      if @current_word == 2 then
        compgen ['create', 'gidsearch', 'list', 'members',
                 'retire', 'show', 'update']
      else
        # this is not my mission and I wish to return to shell
        exit 1
      end
    end
  end
  
  def group_create
    case @words[@current_word-1]
    when '--as-role='
      _role
    when '--as-group='
      _group
    else
      if @words[@current_word].start_with? '-' then
        compgen _flags short='i',
                       long=['interactive','no-interactive'],
                       assoc=['as-group','as-role','gidnumber']
      end
    end
  end
  
  def group_list
    if @words[@current_word-1] == '--as-role=' then
      _role
    elsif @words[@current_word].start_with? '-' then
      compgen _flags short='ilors',
                     long=['ids','no-ids','raw-annotations','no-raw-annotations'],
                     assoc=['limit','offset','role','search']
    end
  end

  def group_members
    compgen ['add', 'list', 'remove'] +
            (_flags short='V',
                   long=['verbose','no-verbose'])
  end
  
end

if __FILE__ == $0
  ConjurCompletion.new ENV['COMP_LINE'], ENV['COMP_POINT'].to_i
end
