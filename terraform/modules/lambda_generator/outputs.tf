output "lambda_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.generator.function_name
}

output "lambda_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.generator.arn
}

output "event_rule_name" {
  description = "CloudWatch Event rule triggering the Lambda"
  value       = aws_cloudwatch_event_rule.schedule.name
}