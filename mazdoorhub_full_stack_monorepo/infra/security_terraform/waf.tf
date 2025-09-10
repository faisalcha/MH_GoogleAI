resource "aws_wafv2_web_acl" "api_waf" { name="mazdoorhub-api-waf"; description="API WAF"; scope="REGIONAL"; default_action{allow{}} visibility_config{cloudwatch_metrics_enabled=true; metric_name="apiWaf"; sampled_requests_enabled=true}
  rule { name="AWSManagedRulesCommonRuleSet"; priority=1; statement{ managed_rule_group_statement{ name="AWSManagedRulesCommonRuleSet" vendor_name="AWS"} } visibility_config{cloudwatch_metrics_enabled=true; metric_name="common"; sampled_requests_enabled=true} override_action{none{}} }
  rule { name="RateLimit"; priority=10; statement{ rate_based_statement{ limit=2000 aggregate_key_type="IP" } } visibility_config{cloudwatch_metrics_enabled=true; metric_name="ratelimit"; sampled_requests_enabled=true} action{ block{} } }
}
resource "aws_wafv2_web_acl_association" "api_assoc" { resource_arn = var.api_gw_arn web_acl_arn = aws_wafv2_web_acl.api_waf.arn }
