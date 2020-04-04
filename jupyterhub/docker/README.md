# JupyterHub Docker Deployment

Steps to deploy:

1. Configure the deployment through `.env` and `jupyterhub_config.py` file. Make sure to pull the docker spawn image set for the variable `DOCKER_NOTEBOOK_IMAGE`.
2. Start docker containers by running:
```bash
$ docker-compose -p jupyterhub up -d
```
Here `jupyterhub` is the project name under which the containers will be deployed. There will be teo containers, one for PostgreSQL database while the other for JupyterHub.
3. Open a terminal in the `jupyterhub` and create a user:
```bash
# Open terminal in container
$ docker exec -it jupyterhub sh
# Create a user
$  useradd --create-home admin
# Create password for user
$ passwd admin
```
4. Restart container
```bash
$ docker restart jupterhub
```

You can now open the URL `http://localhost:8080` in browser and use the above created credentials to login.
