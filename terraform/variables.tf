# variables.tf

variable "gcp_project_id" {
  type        = string
  description = "O ID do seu projeto no Google Cloud."
}

variable "region" {
  type        = string
  description = "A região onde os recursos do GCP serão criados."
  default     = "US"
}

variable "dbt_dataset_id" {
  type        = string
  description = "O nome do dataset que o dbt usará no BigQuery."
  default     = "ga4_dbt_project"
}

variable "dbt_service_account_id" {
  type        = string
  description = "O nome curto (ID) para a conta de serviço do dbt."
  default     = "dbt-runner-terraform"
}