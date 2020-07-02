path "pki/issue/nginx/{{identity.entity.metadata.vm_name}}" {
  capabilities = ["update"]
}

path "pki/issue/nginx"
{
  capabilities = ["update"]
}