# 8sc880
namespace do
  group "admin" do
    owns do
      warehouse = resource "service", "warehouse"
      secrets   = resource "service", "secrets"
  
      host "writer" do
        can "update", warehouse
        can "update", secrets
      end
      
      host "reader" do
        can "execute", warehouse
      end
      
      host "decryptor" do
        can "execute", secrets
      end
    end
  end
end
