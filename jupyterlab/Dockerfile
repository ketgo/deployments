FROM jupyter/scipy-notebook

USER root

# Install Qiskit
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt
RUN rm requirements.txt

# Install Jupyter Lab Extensions
COPY extensions.txt .
RUN pip3 install --no-cache-dir -r extensions.txt
RUN rm extensions.txt

RUN fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}" && \
    rm -rf /root/.cache

USER $NB_UID

# Remove work dir
RUN rm -r ~/work