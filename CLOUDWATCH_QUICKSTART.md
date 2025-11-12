# 📊 CloudWatch Logs - Guía Rápida

## ¿Qué se agregó?

Se implementó logging completo con CloudWatch para:

✅ **Backend API (Node.js)** - Logs de aplicación y sistema  
✅ **Lambda Generator** - Logs detallados de generación de artículos

## 🚀 Implementación Rápida

### 1. Aplicar cambios de Terraform

```bash
cd terraform
terraform plan
terraform apply -auto-approve
```

### 2. Verificar logs

**Opción A: Script automático (Recomendado)**
```bash
# Listar todos los log groups
./view-logs.sh list

# Ver logs del backend
./view-logs.sh backend

# Ver logs del Lambda Generator
./view-logs.sh lambda-generator
```

**Opción B: AWS CLI directo**
```bash
# Backend
aws logs tail /aws/ec2/<name_prefix>-backend --follow

# Lambda Generator
aws logs tail /aws/lambda/article-generator --follow
```

**Opción C: Consola de AWS**
1. Ve a CloudWatch → Log Groups
2. Busca los log groups creados
3. Selecciona un stream de log

## 📝 Log Groups Creados

| Componente | Log Group | Retención |
|-----------|-----------|-----------|
| Backend API | `/aws/ec2/<name_prefix>-backend` | 7 días |
| Lambda Generator | `/aws/lambda/article-generator` | 7 días |

## 🔍 Ejemplo de Logs

### Backend API
```
Server is running on port 3000
PostgreSQL database initialized successfully
```

### Lambda Generator
```
[INFO] Lambda function invoked - Starting article generation process
[INFO] Selected topic: 'The fascinating communication methods of dolphins'
[INFO] Sending request to Gemini API...
[INFO] Successfully uploaded article to S3
[INFO] Article generation completed successfully: (425 words)
```

## 📊 CloudWatch Insights Queries

### Ver errores del backend
```
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 20
```

### Ver artículos generados
```
fields @timestamp, @message
| filter @message like /Article generation completed/
| stats count() as articles_generated
```

## 💡 Comandos Útiles

```bash
# Ver logs de las últimas 2 horas
aws logs tail <log-group> --since 2h

# Buscar un patrón específico
aws logs tail <log-group> --filter-pattern "ERROR"

# Ver logs entre fechas
aws logs filter-log-events \
  --log-group-name <log-group> \
  --start-time 1605139200000 \
  --end-time 1605142800000
```

## 📚 Documentación Completa

- **CLOUDWATCH_LOGS.md** - Guía completa de configuración y uso
- **CLOUDWATCH_IMPLEMENTATION.md** - Detalles técnicos de implementación

## 💰 Costos

**Estimado: < $2/mes**
- Ingesta de logs: ~$0.25/mes
- Almacenamiento (7 días): ~$0.03/mes
- Métricas custom: ~$0.60/mes

## 🐛 Troubleshooting

**Los logs del backend no aparecen:**
```bash
# SSH a la instancia
ssh -i key.pem ubuntu@<backend-ip>

# Verificar CloudWatch Agent
sudo systemctl status amazon-cloudwatch-agent

# Ver logs del agente
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
```

**Los logs del Lambda no aparecen:**
```bash
# Verificar función
aws lambda get-function --function-name article-generator

# Invocar manualmente
aws lambda invoke --function-name article-generator output.json
```

## ✅ Checklist Post-Deploy

- [ ] Ejecutar `terraform apply`
- [ ] Esperar 5-10 minutos
- [ ] Verificar logs con `./view-logs.sh list`
- [ ] Revisar logs del backend
- [ ] Esperar ejecución del Lambda (según schedule)
- [ ] Revisar logs del Lambda Generator

## 🎯 Próximos Pasos (Opcional)

1. **Crear alertas:**
   - Errores en backend
   - Fallos en Lambda Generator
   - Uso excesivo de memoria

2. **Dashboard de CloudWatch:**
   - Métricas de backend
   - Tasa de generación de artículos
   - Errores vs éxitos

3. **Exportar logs a S3:**
   - Para análisis a largo plazo
   - Reducir costos de almacenamiento

---

**¿Preguntas?** Revisa `CLOUDWATCH_LOGS.md` para más detalles.
