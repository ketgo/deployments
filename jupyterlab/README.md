# JupyterLab

The folder contains docker compose file for deploying standalone JupyterLab server.

## Deployment

Follow the below steps to deploy the server:

1. Edit the `extensions.txt` and `requirements.txt` file to add jupyterlab extensions and python packages to be installed as part of the server deployment.
2. Edit the `.env` file to set paths for volume mounts (to persist work) and path to custom python package/modules.
3. Run the following command to start the server
  ```bash
  $ docker-compose up -d
  ```
4. When the deployment is done, the URL for the server can be obtained from the logs. To do so run: 
  ```bash
  $ docker-compose logs
  ```
  The URL would be of the form `http://localhost:8888/lab?token=<token>`.

## Tear Down

To bring down the server run the following command:
```bash
  $ docker-compose down
```
