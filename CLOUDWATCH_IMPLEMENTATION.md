# Resumen de Cambios: Implementación de CloudWatch Logs

## 🎯 Objetivo
Implementar logging completo usando CloudWatch para:
1. Backend API (Node.js en EC2)
2. Lambda Generator (Python)

---

## 📝 Cambios Realizados

### 1. Backend API (EC2)

#### Archivos Modificados:
- `terraform/modules/backend_api/main.tf`
- `terraform/modules/backend_api/user_data.sh`
- `terraform/modules/backend_api/outputs.tf`

#### Cambios en `main.tf`:
✅ Creado IAM Role para EC2 con permisos de CloudWatch
✅ Creada IAM Policy con permisos:
   - logs:CreateLogGroup
   - logs:CreateLogStream
   - logs:PutLogEvents
   - logs:DescribeLogStreams
   - cloudwatch:PutMetricData
✅ Creado Instance Profile
✅ Creado CloudWatch Log Group: `/aws/ec2/<name_prefix>-backend`
✅ Configurado retention: 7 días
✅ Agregado `iam_instance_profile` a la instancia EC2

#### Cambios en `user_data.sh`:
✅ Instalación de CloudWatch Agent
✅ Configuración del agente para capturar:
   - Logs de aplicación: `/var/log/backend-app.log`
   - Logs del sistema: `/var/log/syslog`
✅ Configuración de métricas:
   - Memoria utilizada (%)
   - Disco utilizado (%)
✅ Actualización del servicio systemd para escribir logs a archivo
✅ Inicio automático del CloudWatch Agent

#### Cambios en `outputs.tf`:
✅ Agregado output: `cloudwatch_log_group_name`
✅ Agregado output: `cloudwatch_log_group_arn`

---

### 2. Lambda Generator

#### Archivos Modificados:
- `terraform/modules/lambda_generator/main.tf`
- `terraform/modules/lambda_generator/lambda/generator.py`
- `terraform/modules/lambda_generator/outputs.tf`

#### Cambios en `main.tf`:
✅ Creado CloudWatch Log Group: `/aws/lambda/article-generator`
✅ Configurado retention: 7 días
✅ Agregado `depends_on` para asegurar creación del log group

#### Cambios en `generator.py`:
✅ Importado módulo `logging`
✅ Configurado logger con nivel INFO
✅ Agregado logging al inicio de la ejecución:
   - Bucket de destino
   - Topic seleccionado
   - Autor seleccionado
✅ Agregado logging durante generación de artículo:
   - Inicio de generación
   - Request a Gemini API
   - Status de respuesta
   - Extracción de contenido
✅ Agregado logging al subir a S3:
   - Archivo siendo subido
   - Confirmación de subida exitosa
✅ Agregado logging de resultados:
   - Título del artículo
   - Cantidad de palabras
✅ Mejorado manejo de errores con stack traces completos

#### Cambios en `outputs.tf`:
✅ Agregado output: `cloudwatch_log_group_name`
✅ Agregado output: `cloudwatch_log_group_arn`

---

### 3. Terraform Principal

#### Archivos Modificados:
- `terraform/outputs.tf`

#### Cambios:
✅ Agregado output: `backend_log_group_name` (lista de todos los backends)
✅ Agregado output: `lambda_generator_log_group_name`
✅ Agregado output: `lambda_rebuild_log_group_name`

---

## 🔄 Próximos Pasos para Aplicar

### 1. Empaquetar Lambda (✅ Ya realizado)
```bash
cd terraform/modules/lambda_generator/lambda
zip -r ../lambda.zip .
```

### 2. Aplicar cambios de Terraform
```bash
cd terraform
terraform plan
terraform apply
```

### 3. Verificar Logs

**Backend:**
```bash
# Esperar 5-10 minutos después de apply para que el CloudWatch Agent inicie
aws logs tail /aws/ec2/<name_prefix>-backend --follow
```

**Lambda Generator:**
```bash
# El Lambda se ejecutará según el schedule configurado
aws logs tail /aws/lambda/article-generator --follow
```

---

## 📊 Información de los Logs

### Backend Log Streams:
- `{instance_id}/application` - Logs de Node.js
- `{instance_id}/syslog` - Logs del sistema

### Lambda Log Streams:
- Se crean automáticamente por fecha/hora de ejecución

### Retención:
- **Ambos**: 7 días

### Métricas Adicionales (Backend):
- MemoryUtilization (%)
- DiskUtilization (%)
- Namespace: `BackendAPI`

---

## 🎯 Ejemplo de Logs Esperados

### Backend (Node.js):
```
Server is running on port 3000
Database: postgresql
Available endpoints:
  GET  /comments - Get all comments
  POST /comments - Create a new comment
  GET  /health   - Health check
PostgreSQL database initialized successfully
```

### Lambda Generator:
```
[INFO] Lambda function invoked - Starting article generation process
[INFO] Target S3 bucket: source-md-bucket-12345678
[INFO] Selected topic: 'The fascinating communication methods of dolphins' by author: 'Dr. Jane Wildlife'
[INFO] Starting article generation for topic: The fascinating communication methods of dolphins
[INFO] Sending request to Gemini API...
[INFO] Gemini API response status: 200
[INFO] Successfully extracted article content from Gemini response
[INFO] Uploading article to S3: source-md-bucket-12345678/20251112_123456-the-fascinating-communication-methods-of-dolph.md
[INFO] Successfully uploaded article to S3
[INFO] Article generation completed successfully: The Fascinating Communication Methods of Dolphins (425 words)
```

---

## 💰 Costos Estimados

### CloudWatch Logs:
- **Ingesta**: ~0.5 GB/mes × $0.50/GB = $0.25/mes
- **Almacenamiento (7 días)**: ~1 GB × $0.03/GB = $0.03/mes
- **Total**: < $1/mes

### CloudWatch Metrics (Backend):
- Métricas personalizadas: 2 métricas × $0.30/métrica = $0.60/mes

**Total Estimado: ~$1-2/mes**

---

## 📚 Documentación

Se ha creado la guía completa en: `CLOUDWATCH_LOGS.md`

Incluye:
- ✅ Configuración detallada
- ✅ Cómo ver los logs (Console, CLI, Insights)
- ✅ Ejemplos de queries
- ✅ Troubleshooting
- ✅ Recomendaciones de alertas
- ✅ Optimización de costos

---

## ✅ Checklist de Verificación

Después de aplicar los cambios:

- [ ] Verificar que el CloudWatch Agent está corriendo en EC2
- [ ] Verificar que los logs del backend aparecen en CloudWatch
- [ ] Verificar que los logs del Lambda aparecen después de una ejecución
- [ ] Revisar los outputs de Terraform para obtener nombres de log groups
- [ ] (Opcional) Configurar alertas basadas en logs
- [ ] (Opcional) Crear dashboards de CloudWatch

---

## 🐛 Troubleshooting Rápido

**Si los logs del backend no aparecen:**
```bash
# SSH a la instancia
ssh -i your-key.pem ubuntu@<backend-ip>

# Verificar servicio
sudo systemctl status amazon-cloudwatch-agent

# Ver logs del agente
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
```

**Si los logs del Lambda no aparecen:**
```bash
# Verificar permisos del rol
aws iam get-role-policy --role-name article-generator-lambda-role --policy-name article-generator-lambda-policy

# Invocar manualmente
aws lambda invoke --function-name article-generator response.json
```
