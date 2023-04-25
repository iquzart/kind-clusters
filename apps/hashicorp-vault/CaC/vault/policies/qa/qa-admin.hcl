# List, create, update, and delete key/value secrets at uat
path "qa/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}