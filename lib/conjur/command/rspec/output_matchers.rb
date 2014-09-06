require 'io/grab'

# Custom matcher to test text written to standard output and standard error
#
# @example
#   expect { $stderr.puts "Some random error" }.to write(/Some.* error/).to(:stderr)
#
# @example
#   expect { $stderr.puts "Some specific error" }.to write('Some specific error').to(:stderr)
#
# @note http://greyblake.com/blog/2012/12/14/custom-expectations-with-rspec/
RSpec::Matchers.define :write do |message|
  supports_block_expectations

  chain(:to) do |io|
    @io = io
  end

  match do |block|
    stream = case io
    when :stdout
      STDOUT
    when :stderr
      STDERR
    else
      io
    end

    output = stream.grab &block

    case message
    when Hash then output.include?(JSON.pretty_generate message)
    when String then output.include? message
    when Regexp then output.match message
    when nil then output
    else fail("Allowed types for write `message` are String or Regexp, got `#{message.class}`")
    end
  end

  description do
    %Q[write #{message.inspect} to #{@io}]
  end

  def failure_message(to = 'to')
    %Q[expected #{to} #{description} but got #{@buffer.inspect}]
  end

  failure_message_for_should do
    failure_message 'to'
  end

  failure_message_for_should_not do
    failure_message 'not to'
  end

  # default IO is standard output
  def io
    @io ||= :stdout
  end
end
