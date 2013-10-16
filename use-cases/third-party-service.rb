# An AWS IAM identity is created for S3 access. It is encrypted
# with the key-pair by the admin and placed in a Conjur Variable. 
# An aws/clients group can read the (encrypted) s3-identity.
# The Gatekeeper can decrypt this credential, as well as any other that
# has been encrypted with the key pair.
# The Gatekeeper passes the decrypted credential to the Service Gateway,
# which calls AWS or uses the AWS identity in some other way:
# * Provides a pre-signed URL
# * Acts as a "token vending machine" to provide a temporary credential
namespace "cybd80" do
  group "admin" do
    owns do
      alice = user "#{namespace}-alice"

      gatekeeper = layer "gatekeeper"
      
      key_pair "key-pair" do
        add_member "decrypt", gatekeeper.roleid
      end
      
      scope "aws" do
        clients = group "clients" do
          add_member alice.roleid  
        end
        
        variable "s3-identity", kind: "aws-identity", mime_type: "application/json" do
          permit "execute", clients.roleid
        end
      end
    end
  end
end