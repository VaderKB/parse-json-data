locals {

  policy = jsondecode(file("${path.module}/policy.json"))

  step_function_role_policy_base = jsondecode(file("${path.module}/policy.json")).step_function_role_policy

  step_function_role_policy_with_values_resolved = jsondecode(templatefile("${path.module}/policy.json", {
    lambda_id = aws_lambda_function.generate_data.id
    step_function_arn = ""
  })).step_function_role_policy

  event_bridge_role_policy_with_replacements = jsondecode(templatefile("${path.module}/policy.json", {
    step_function_arn = aws_sfn_state_machine.generate_data_sm.arn
    lambda_id = ""
  })).eventbridge_role_policy

}
