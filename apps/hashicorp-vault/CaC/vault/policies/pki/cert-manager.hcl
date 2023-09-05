# Read Access to PKI root
path "pki_intermediate_ca/*"
{ 
    capabilities = ["read", "list"] 
}
# PKI Sign
path "pki_intermediate_ca/sign/*"
{ 
    capabilities = ["create", "update"] 
}
# PKI Issue
path "pki_intermediate_ca/issue/*"
{ 
    capabilities = ["create"] 
}

