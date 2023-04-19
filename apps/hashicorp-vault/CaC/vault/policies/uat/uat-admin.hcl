# List, create, update, and delete key/value secrets at uat
path "uat/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}