output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.docusaurus_rebuild.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.docusaurus_rebuild.arn
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.docusaurus_build.name
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project"
  value       = aws_codebuild_project.docusaurus_build.arn
}
