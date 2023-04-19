# List, create, update, and delete key/value secrets at dev
path "dev/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}