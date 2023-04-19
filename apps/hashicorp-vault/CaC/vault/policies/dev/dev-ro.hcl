# Read-only key/value secrets at dev
path "dev/data/*"
{
  capabilities = ["read", "list"]
}