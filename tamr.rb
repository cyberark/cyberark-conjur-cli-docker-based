policy "tamr-1.0.0" do
  group "admin" do
    owns do
      ops, developers, build = [
        group("ops"),
        group("developers"),
        group("build")
      ]

      layer "sandbox" do
        add_member "admin_host", developers
      end
    end
  end
end
