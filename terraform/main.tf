# Bloco de configuração do Terraform e dos provedores necessários.
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.1.0"
    }
  }
}

# Configura o provedor do Google Cloud para usar o projeto e região definidos nas variáveis.
provider "google" {
  project = var.gcp_project_id
  region  = var.region
}

# --- RECURSOS A SEREM CRIADOS ---

# 1. Cria o Dataset no BigQuery
resource "google_bigquery_dataset" "dbt_dataset" {
  dataset_id = var.dbt_dataset_id
  location   = var.region
  description = "Dataset para saídas do dbt, gerenciado via Terraform."
}

# 2. Cria a Conta de Serviço do dbt.
resource "google_service_account" "dbt_runner" {
  account_id   = var.dbt_service_account_id
  display_name = "Service Account para dbt"
}

# 3. Dá as permissões necessárias para a Conta de Serviço.
# Permissão para EXECUTAR consultas e jobs no BigQuery.
resource "google_project_iam_member" "dbt_bigquery_job_user" {
  project = var.gcp_project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dbt_runner.email}"
}

# Permissão para CRIAR/EDITAR/APAGAR tabelas e dados.
resource "google_project_iam_member" "dbt_bigquery_data_editor" {
  project = var.gcp_project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.dbt_runner.email}"
}

# 4. Gera a chave de acesso para a Conta de Serviço.
resource "google_service_account_key" "dbt_runner_key" {
  service_account_id = google_service_account.dbt_runner.name
}

# 5. Salva a chave em um arquivo .json.
resource "local_file" "sa_key_file" {
  content  = base64decode(google_service_account_key.dbt_runner_key.private_key)
  filename = "${path.module}/.secret/dbt_key.json"
}