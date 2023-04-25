# Read-only key/value secrets at qa
path "qa/data/*"
{
  capabilities = ["read", "list"]
}