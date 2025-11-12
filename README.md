# Guía de Deploy

## Prerequisitos

- Credenciales de AWS (`~/.aws/credentials`)
- Terraform instalado

## Deploy

### 1. Copiar variables de entorno

Copiar el archivo de variables de ejemplo y poner sus datos.

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Deployar infraestrctura

```bash
cd terraform
terraform init
terraform apply
```

### 3. Deploy Frontend

```bash
./deploy-to-s3.sh
```

## Access

- **Frontend**: `https://<cloudfront-domain>` (se ve luego del deployment)
