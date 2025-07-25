#!/bin/bash

set -euo pipefail

apt-get update
apt-get install libsasl2-dev

python3 -m venv venv
. venv/bin/activate
pip install --upgrade pip setuptools
pip install -r integration_tests/requirements.txt
mkdir -p ~/.dbt
cp integration_tests/ci/sample.profiles.yml ~/.dbt/profiles.yml

db=$1
echo `pwd`
cd integration_tests
dbt deps

if [ "$db" = "databricks-sql" ]; then
dbt seed --vars '{shopify_schema: shopify_integrations_tests_sqlw}' --target "$db" --full-refresh
dbt run --vars '{shopify_schema: shopify_integrations_tests_sqlw}' --target "$db" --full-refresh
dbt test --vars '{shopify_schema: shopify_integrations_tests_sqlw}' --target "$db"
dbt run --vars '{shopify_schema: shopify_integrations_tests_sqlw, shopify_timezone: "America/New_York", shopify_using_fulfillment_event: true, shopify_using_all_metafields: true, shopify__calendar_start_date: '2020-01-01', shopify_using_abandoned_checkout: false, shopify_using_metafield: false, shopify_using_discount_code_app: true, shopify_using_product_variant_media: true}' --target "$db" --full-refresh
dbt test --vars '{shopify_schema: shopify_integrations_tests_sqlw}' --target "$db"
dbt run-operation fivetran_utils.drop_schemas_automation --target "$db"

else
dbt seed --target "$db" --full-refresh
dbt run --target "$db" --full-refresh
dbt test --target "$db"
dbt run --vars '{shopify_timezone: "America/New_York", shopify_using_fulfillment_event: true, shopify_using_all_metafields: true, shopify__calendar_start_date: '2020-01-01', shopify_using_abandoned_checkout: false, shopify_using_metafield: false, shopify_using_discount_code_app: true, shopify_using_product_variant_media: true}' --target "$db" --full-refresh
dbt test --target "$db"
dbt run-operation fivetran_utils.drop_schemas_automation --target "$db"
fi