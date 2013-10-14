# http://developer-www.s3-website-us-east-1.amazonaws.com/use-cases/service-access-control.html
model do
  group "admin" do
    owns do
      resource "service", "bacon" do |bacon|
        owns do
          user "#{model}-alice"
          user "#{model}-bob" do
            can "fry", bacon
          end
        end
      end
    end
  end
end

# http://developer-www.s3-website-us-east-1.amazonaws.com/use-cases/encrypted-data-flow.html
model do
  group "admin" do
    owns do
      warehouse = resource "service", "warehouse"
      secrets = resource "service", "secrets"
  
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
    
      # Will check "fetch" and "store" permission
      layer "warehouse"
    
      # Will check "fetch" and "store" permission
      environment "secrets" do
        permit "manage", warehouse
        permit "use",    decr
      end
    end
  end
end

# http://developer-www.s3-website-us-east-1.amazonaws.com/use-cases/third-party-service.html
model do
  group "admin" do
    owns do
      s3_client = user "client"

      gatekeeper = layer "gatekeeper"

      key_pair "the-key-pair" do
        # A member of the admin group uses the public key to encrypt the 
        # raw secrets and place them into variables listed below
        
        # The decryptor can decrypt using the private key
        permit "decrypt", gatekeeper
      end
      
      # Service-specific variables
      namespace "services/aws" do
        # Contains an S3 identity encrypted using the-key-pair.
        # In practice this would not be blanket S3 permissions, only
        # specific permissions required by the client.
        variable "s3-identity-crypted" do
          options do
            kind "aws-identity"
            mime_type "application/octet-stream"
          end
          
          # The client can access this value, but cannot decrypt it.
          # Decryption is performed by the gatekeeper.
          permit "execute", client
        end
      end
    end
  end
end

# http://developer-www.s3-website-us-east-1.amazonaws.com/use-cases/pam-ldap-login.html
model do
  group "admin" do
    owns do
      developers = group "developers" do
        owns do
          scope "dev" do
            layer "web"
            layer "app"
            layer "cache"
          end
        end
      end
      
      group "ops" do
        owns do
          scope "stage" do
            layer "web"
            layer "app"
            layer "cache"
            
            permit "execute", developers
          end
          
          scope "production" do
            layer "web"
            layer "app"
            layer "cache"
          end
        end
      end
    end
  end
end

model do
  group "admin" do
    owns do
      
      developers = group "developers" do
        owns do
          scope "dev" do
            layers << layer("web")
            layers << layer("app")
            layers << layer("cache")
          end
        end
      end
      
      ops = group "ops" do
        owns do
          scope "dev" do
            layers << layer("web")
            layers << layer("app")
            layers << layer("cache")
          end
        end
      end

      archive_fetchers = role "role", "archive-fetchers"
      archive_fetchers.grant_to "developers"
      archive_fetchers.grant_to "ops"
      layers.each do |layer|
        archive_fetchers.grant_to layer
      end
 
      build = group "build-managers" do
        owns do
          scope "build" do
            scope "jenkins" do
              master = layer "master"
              layer "slave"
              
              archive_fetchers.grant_to master
              
              variable "api-credentials", kind: credentials, mime_type: "application/json" do
                permit "execute", archive_fetchers
              end
            end
          end
  
          scope "archive" do
            variable "api-credentials", kind: credentials, mime_type: "application/json" do
              permit "execute", archive_fetchers
            end
          end
        end
      end
    end
  end
end