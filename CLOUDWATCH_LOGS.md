# Guía de CloudWatch Logs

Esta guía explica cómo se han implementado los logs de CloudWatch para el backend y el Lambda Generator.

## 📊 Componentes con Logging

### 1. Backend API (EC2)

#### Configuración
- **Log Group**: `/aws/ec2/<name_prefix>-backend`
- **Retención**: 7 días
- **Streams de logs**:
  - `{instance_id}/application` - Logs de la aplicación Node.js
  - `{instance_id}/syslog` - Logs del sistema

#### Características
- **CloudWatch Agent** instalado automáticamente en cada instancia EC2
- Logs de aplicación capturados desde `/var/log/backend-app.log`
- Logs del sistema capturados desde `/var/log/syslog`
- Métricas adicionales:
  - Utilización de memoria (`MemoryUtilization`)
  - Utilización de disco (`DiskUtilization`)

#### IAM Permissions
El rol IAM del backend incluye permisos para:
- `logs:CreateLogGroup`
- `logs:CreateLogStream`
- `logs:PutLogEvents`
- `logs:DescribeLogStreams`
- `cloudwatch:PutMetricData`

### 2. Lambda Generator

#### Configuración
- **Log Group**: `/aws/lambda/article-generator`
- **Retención**: 7 días
- **Nivel de logging**: INFO

#### Logs Capturados
El Lambda Generator registra información detallada sobre:

1. **Inicio de ejecución**
   ```
   Lambda function invoked - Starting article generation process
   Target S3 bucket: <bucket-name>
   Selected topic: '<topic>' by author: '<author>'
   ```

2. **Generación de contenido**
   ```
   Starting article generation for topic: <topic>
   Sending request to Gemini API...
   Gemini API response status: 200
   Successfully extracted article content from Gemini response
   ```

3. **Subida a S3**
   ```
   Uploading article to S3: <bucket>/<filename>
   Successfully uploaded article to S3
   ```

4. **Resultado final**
   ```
   Article generation completed successfully: <title> (<word_count> words)
   ```

5. **Errores (si ocurren)**
   ```
   Error generating article: <error-message>
   [Stack trace completo]
   ```

## 🔍 Cómo Ver los Logs

### Desde la Consola de AWS

1. **Para el Backend:**
   ```bash
   # Ve a CloudWatch > Log Groups
   # Busca: /aws/ec2/<name_prefix>-backend
   # Selecciona el stream de la instancia que quieres ver
   ```

2. **Para Lambda Generator:**
   ```bash
   # Ve a CloudWatch > Log Groups
   # Busca: /aws/lambda/article-generator
   # Selecciona el stream más reciente
   ```

### Usando AWS CLI

1. **Ver logs del Backend:**
   ```bash
   # Listar streams de log
   aws logs describe-log-streams \
     --log-group-name /aws/ec2/<name_prefix>-backend \
     --order-by LastEventTime \
     --descending

   # Ver logs de un stream específico
   aws logs get-log-events \
     --log-group-name /aws/ec2/<name_prefix>-backend \
     --log-stream-name <instance-id>/application
   ```

2. **Ver logs del Lambda Generator:**
   ```bash
   # Ver los últimos logs
   aws logs tail /aws/lambda/article-generator --follow

   # Ver logs de las últimas 2 horas
   aws logs tail /aws/lambda/article-generator --since 2h
   ```

### Usando Terraform Outputs

Después de aplicar la configuración, puedes obtener los nombres de los log groups:

```bash
terraform output backend_log_group_name
terraform output lambda_generator_log_group_name
```

## 📈 Métricas y Monitoreo

### Backend Metrics
El CloudWatch Agent recopila:
- **Memoria**: Porcentaje de uso de memoria
- **Disco**: Porcentaje de uso de disco
- **Namespace**: `BackendAPI`

### Lambda Metrics
AWS Lambda proporciona automáticamente:
- Invocaciones
- Duración
- Errores
- Throttles

## 🔔 Alertas Recomendadas

Puedes crear alarmas para:

1. **Backend:**
   - Uso de memoria > 80%
   - Uso de disco > 85%
   - Errores 5xx en logs

2. **Lambda Generator:**
   - Tasa de errores > 10%
   - Duración > 50 segundos (timeout en 60s)
   - Throttles > 0

### Ejemplo de Alarma en Terraform

```hcl
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "lambda-generator-high-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda generator tiene muchos errores"
  
  dimensions = {
    FunctionName = module.lambda_generator.lambda_name
  }
  
  alarm_actions = [aws_sns_topic.alertas.arn]
}
```

## 🛠️ Troubleshooting

### Los logs del Backend no aparecen

1. Verifica que el CloudWatch Agent esté corriendo:
   ```bash
   ssh -i <key.pem> ubuntu@<backend-ip>
   sudo systemctl status amazon-cloudwatch-agent
   ```

2. Verifica la configuración del agente:
   ```bash
   cat /opt/aws/amazon-cloudwatch-agent/etc/config.json
   ```

3. Revisa los logs del agente:
   ```bash
   sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
   ```

### Los logs del Lambda no aparecen

1. Verifica que el Lambda tiene permisos correctos:
   - El rol debe tener permisos de CloudWatch Logs

2. Verifica que el Lambda está siendo invocado:
   ```bash
   aws lambda get-function --function-name article-generator
   ```

3. Invoca manualmente el Lambda para ver si genera logs:
   ```bash
   aws lambda invoke \
     --function-name article-generator \
     --payload '{}' \
     response.json
   ```

## 📝 Ejemplos de Queries con CloudWatch Insights

### Buscar errores en el Backend

```
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 20
```

### Estadísticas de generación de artículos

```
fields @timestamp, @message
| filter @message like /Article generation completed successfully/
| parse @message "Article generation completed successfully: * (*) words)" as title, word_count
| stats count() as articles_generated, avg(word_count) as avg_words
```

### Tiempos de respuesta del Backend

```
fields @timestamp, @message
| filter @message like /GET|POST/
| stats count() as requests by bin(5m)
```

## 🔐 Costos

### Estimación de Costos de CloudWatch Logs

- **Ingesta de datos**: $0.50 por GB
- **Almacenamiento**: $0.03 por GB/mes
- **CloudWatch Insights**: $0.005 por GB escaneado

Con retención de 7 días y uso moderado, el costo estimado es < $5/mes.

### Optimización de Costos

1. Ajusta el período de retención según necesidades:
   ```hcl
   retention_in_days = 3  # Reduce a 3 días si no necesitas más
   ```

2. Filtra logs innecesarios en la configuración del CloudWatch Agent

3. Usa filtros de suscripción solo para logs críticos

## 📚 Referencias

- [CloudWatch Logs Documentation](https://docs.aws.amazon.com/cloudwatch/latest/logs/)
- [CloudWatch Agent Configuration](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html)
- [Lambda Logging Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/python-logging.html)
