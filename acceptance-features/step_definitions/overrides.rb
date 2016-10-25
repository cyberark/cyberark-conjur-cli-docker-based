# Use a json_spec style memorized value as an environment variable
When /I set the environment variable "(.*)" to memorized value "(.*)"/ do |key, value|
  JsonSpec.memory.each do |k,v|
    # JSON parser doesn't function properly on a JSON encoded string
    v = v[1...-1] if v[0] == '"'
    value.gsub! "%{#{k}}", v
  end
  set_environment_variable key, value
end
