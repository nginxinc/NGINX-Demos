# Grafana telemetry dashboard

To configure the bundled Grafana container follow these steps:

1. Browse to https://grafana.nim2.f5.ff.lan/ (the actual FQDN depends on your cluster/network settings, see YAML files under /manifests)
2. Login as user "admin", password "admin" and set a new password
3. Go to configuration / data sources
4. Add a new data source. In the search box type "clickhouse" and click "select". Configure the datasource as displayed here below. Set the password to "NGINXr0cks":

<img src="/contrib/grafana/clickhouse-datasource.png"/>

5. Click "Save and test": "Datasource is working" should be displayed
6. Go to Dashboards / browse and click "Import"
7. Click "Upload JSON file" and select the file `contrib/NGINX_NIM2_Telemetry_Grafana_Dashboard.json`
8. Click import
9. The NGINX Instance Manager 2 telemetry dashboard is up and running

<img src="/contrib/grafana/grafana-dashboard.png"/>
