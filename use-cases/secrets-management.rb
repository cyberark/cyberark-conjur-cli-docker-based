namespace "nfz7m0" do
  group "admin" do
    managers = layer "managers"
    
    users = layer "users"

    environment "secrets" do
      add_member "manage_variable", managers.roleid
      add_member "use_variable",    users.roleid
    end
  end
end