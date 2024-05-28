# Docker-compose for NGINX Instance Manager

1. Edit the `.env` file configuring the NGINX Management Suite docker image name and the base64-encoded license
2. Start NGINX Management Suite using

```
docker-compose -f docker-compose.yaml up -d
```

3. Stop NGINX Management Suite using

```
docker-compose -f docker-compose.yaml down
```
