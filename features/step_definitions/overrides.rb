# Use a json_spec style memorized value as an environment variable
When /I use it to (.*)/ do |statement|
  JsonSpec.memory.each do |k,v|
    statement = statement.gsub("%{#{k}}", v)
  end
  step "I #{statement}"
end
