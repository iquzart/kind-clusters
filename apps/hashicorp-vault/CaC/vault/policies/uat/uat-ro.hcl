# Read-only key/value secrets at uat
path "uat/data/*"
{
  capabilities = ["read", "list"]
}