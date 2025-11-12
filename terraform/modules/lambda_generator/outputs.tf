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

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name for Lambda logs"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN for Lambda logs"
  value       = aws_cloudwatch_log_group.lambda_logs.arn
}
