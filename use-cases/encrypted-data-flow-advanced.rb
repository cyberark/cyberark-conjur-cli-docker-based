namespace "7rpeg0" do
  group "admin" do
    owns do
      warehouse = layer "warehouse"

      writer = layer "writer" do
        can "store", warehouse
      end
      
      reader = layer "reader" do
        can "fetch", warehouse
      end

      key_pair "the-key-pair" do
        add_member "encrypt", warehouse.roleid
        add_member "decrypt", reader.roleid
      end

      environment "keys" do
        add_member "manage_variable", writer.roleid
        add_member "use_variable", reader.roleid
      end
    end
  end
end
