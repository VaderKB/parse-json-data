
# This is creatin of role with trust policy
resource "aws_iam_role" "lambda_role" {
  name = local.policy.lambda_trust_policy.Name
  assume_role_policy = jsonencode({
    Version   = "${local.policy.lambda_trust_policy.Version}"
    Statement = local.policy.lambda_trust_policy.Statement
  })
}

# Add inline policies to the created role
resource "aws_iam_role_policy" "lambda_role_policy" {
  role     = aws_iam_role.lambda_role.id
  for_each = { for idx, val in local.policy.lambda_role_policy : idx => val } #Convert from list to map type
  name     = each.value.Name
  policy = jsonencode({
    Version   = "${each.value.Version}"
    Statement = each.value.Statement
  })

}

resource "aws_lambda_function" "generate_data" {
  function_name = "generate-data"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "483151609062.dkr.ecr.us-east-1.amazonaws.com/my-lambda-repo:latest"

  image_config {
    entry_point = ["/lambda-entrypoint.sh"]
    command     = ["generate_data.lambda_handler"]
  }

  memory_size = 512
  timeout     = 30

  architectures = ["x86_64"]
}

resource "aws_iam_role" "step_function_role" {
  name = local.policy.trust_policy_step_function.Name
  assume_role_policy = jsonencode({
    Version   = "${local.policy.trust_policy_step_function.Version}"
    Statement = local.policy.trust_policy_step_function.Statement
  })
  depends_on = [aws_lambda_function.generate_data]
}


resource "aws_iam_role_policy" "step_function_role_policy" {
  ## Here we cannot pass dynamic value to for_each. Therefor we could not directly 
  ## pass local step_function_role_policy_with_values_resolved as it would complain
  ## that lambda_id would only be known at run time and we don't know if at plan time.
  ## So I create two, one with static value step_function_role_policy_base. This is so
  ## that I get static value and can loop over. In this step_function_role_policy_base, 
  ## we will get a list. We convert this list to map type. In this case, each key will 
  ## number like 0 and 1 and value will be dictionary inside the list step_function_role_policy.

  ## Now that we have for_each with key as 0 and 1 and value as dict, but the value still 
  ## had ${lambda_id} instead of actual valu. This is where I use step_function_role_policy_with_values_resolved
  ## in which I had replaced the value of ${lambda_id} with actual value using template file. 
  ## And i simply replace step_function_role_policy_base[0].Statement with 
  ## step_function_role_policy_with_values_resolved[0].Statement as it had resolveed value. And same for [1]
  ## and so on.


  role     = aws_iam_role.step_function_role.id
  for_each = { for idx, val in local.step_function_role_policy_base : idx => val } #Convert from list to map type
  name     = each.value.Name
  policy = jsonencode({
    Version   = "${each.value.Version}"
    Statement = local.step_function_role_policy_with_values_resolved[each.key].Statement
    }
  )
  depends_on = [aws_iam_role.step_function_role]
}


resource "aws_sfn_state_machine" "generate_data_sm" {

  name     = "generate-data-sm"
  role_arn = aws_iam_role.step_function_role.arn

  definition = templatefile("${path.module}/step_function.json", {
    lambda_arn = aws_lambda_function.generate_data.arn
  })

}


resource "aws_iam_role" "scheduler_role" {
  name = local.policy.trust_policy_eventbridge.Name
  assume_role_policy = jsonencode({
    Version = local.policy.trust_policy_eventbridge.Version
    Statement = local.policy.trust_policy_eventbridge.Statement
  })
}

resource "aws_iam_role_policy" "scheduler_role_policy"{
  role = aws_iam_role.scheduler_role.id
  for_each = {for idx, val in local.policy.eventbridge_role_policy: idx => val}
  name = each.value.Name
  policy = jsonencode(({
    Version = each.value.Version
    Statement = local.event_bridge_role_policy_with_replacements[each.key].Statement
  }))
}

resource "aws_scheduler_schedule" "scheduler" {
  name = "schedule-generate-data"
  flexible_time_window {
      mode = "OFF"
  }

  schedule_expression = "cron(11 * * * ? *)"
  target {
    arn = aws_sfn_state_machine.generate_data_sm.arn
    role_arn = aws_iam_role.scheduler_role.arn
  }
}