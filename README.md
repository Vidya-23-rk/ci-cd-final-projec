# CI/CD Tools and Practices Final Project Template

## Project Name: `ci-cd-final-project`

This repository contains the final project implementation for the Coursera course **Continuous Integration and Continuous Delivery (CI/CD)** by IBM Skills Network.

## Project Purpose

The purpose of this project is to implement complete Continuous Integration (CI) and Continuous Delivery (CD) pipelines for a cloud-native Python Flask Hit Counter microservice. The project demonstrates:
- Automated continuous integration using **GitHub Actions** for syntax checking, linting, and unit testing with code coverage.
- Cloud-native continuous delivery using **Tekton Pipelines** on **Red Hat OpenShift** for automated cleanup, code checkout, linting, testing, container image building with **Buildah**, and containerized deployment with **OpenShift Client**.

---

## Usage

This repository is to be used as a template to create your own repository in your own GitHub account. No need to Fork it as it has been set up as a Template. This will avoid confusion when making Pull Requests in the future.

From the GitHub **Code** page, press the green **Use this template** button to create your own repository from this template.

Name your repo: `ci-cd-final-project`.

## Setup

After entering the lab environment you will need to run the `setup.sh` script in the `./bin` folder to install the prerequisite software.

```bash
bash bin/setup.sh
```

Then you must exit the shell and start a new one for the Python virtual environment to be activated.

```bash
exit
```

---

## Architecture & CI/CD Pipeline Overview

### 1. GitHub Actions CI Workflow
- **Workflow configuration**: [`.github/workflows/workflow.yml`](.github/workflows/workflow.yml)
- **Workflow Name**: `CI workflow`
- **Triggers**: Executed automatically on every `push` to `main` and `pull_request` targeting `main`.
- **Environment**: Runs inside container `python:3.9-slim` on an `ubuntu-latest` runner.
- **Workflow Stages**:
  1. **Checkout**: Checks out source code using `actions/checkout@v3`.
  2. **Install dependencies**: Upgrades `pip` and installs required packages from `requirements.txt`.
  3. **Lint with flake8**: Enforces code style and catches syntax errors (`E9,F63,F7,F82`) and complexity constraints (`--max-complexity=10 --max-line-length=127`).
  4. **Run unit tests with nose**: Runs unit tests with test specifications and code coverage analysis (`nosetests -v --with-spec --spec-color --with-coverage --cover-package=app`).

### 2. Tekton Tasks
- **Tasks configuration**: [`.tekton/tasks.yml`](.tekton/tasks.yml)
- **Task A (`cleanup`)**:
  - Uses `alpine:3` container with root privileges (`runAsUser: 0`, `runAsNonRoot: false`).
  - Safely clears the contents of `$(workspaces.source.path)` including hidden files without deleting the mounted volume mount point.
- **Task B (`nose`)**:
  - Uses `python:3.9-slim` container.
  - Installs requirements and executes test suite using `nosetests $(params.args)` with customizable test arguments (default `"-v"`).

### 3. OpenShift Tekton CD Pipeline
- **Pipeline definition**: [`.tekton/pipeline.yml`](.tekton/pipeline.yml)
- **Workspace**: Backed by a PersistentVolumeClaim (`oc-lab-pvc`, 1Gi, StorageClass: `skills-network-learner`).
- **Sequential Pipeline Steps**:
  1. **`cleanup`**: Runs custom Tekton task to clear workspace directory.
  2. **`git-clone`**: Clones the public Git repository into the shared PVC workspace.
  3. **`flake8`**: Performs static linting on the `service` package using `python:3.9-slim`.
  4. **`nose`**: Executes Python unit tests with verbose test reporting.
  5. **`buildah`**: Builds the container image from the project's `Dockerfile` without root daemon requirements and pushes it to the OpenShift Internal Registry (`image-registry.openshift-image-registry.svc:5000/<namespace>/hit-counter:latest`).
  6. **`deploy`**: Deploys the containerized service into the OpenShift cluster using `oc create deployment ... --dry-run=client -o yaml | oc apply -f -`.

---

## How to Run the Tests Locally

1. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Run Flake8 linting**:
   ```bash
   flake8 service --count --select=E9,F63,F7,F82 --show-source --statistics
   flake8 service --count --max-complexity=10 --max-line-length=127 --statistics
   ```

3. **Run unit tests with Nose**:
   ```bash
   nosetests -v --with-spec --spec-color --with-coverage --cover-package=service
   ```

---

## How the Application is Deployed

1. **Apply Tekton Tasks**:
   ```bash
   kubectl apply -f .tekton/tasks.yml
   ```

2. **Create PersistentVolumeClaim**:
   ```bash
   kubectl apply -f .tekton/pvc.yml
   ```

3. **Apply the Pipeline**:
   ```bash
   kubectl apply -f .tekton/pipeline.yml
   ```

4. **Trigger the Pipeline**:
   ```bash
   kubectl apply -f .tekton/pipelinerun.yml
   # Or using tkn CLI:
   tkn pipeline start cd-pipeline \
     -w name=output,claimName=oc-lab-pvc \
     -p repo-url="https://github.com/salonitiwari24/ci-cd-final-project.git" \
     -p branch="main" \
     --showlog
   ```

5. **Verify Deployment & Running Application Logs**:
   ```bash
   oc get pods
   oc logs deployment/hit-counter
   ```
   The application log outputs the banner confirming service status:
   ```
   **********************************************************************
   ********************  S E R V I C E   R U N N I N G  *****************
   **********************************************************************
   ```

---

## Relevant Repository Files

- `.github/workflows/workflow.yml`: GitHub Actions automated CI workflow definition.
- `.tekton/tasks.yml`: Tekton custom tasks for workspace `cleanup` and `nose` unit testing.
- `.tekton/pipeline.yml`: Tekton CD pipeline orchestrating the end-to-end 6-stage delivery workflow.
- `.tekton/pvc.yml`: PersistentVolumeClaim definition for shared pipeline workspace storage.
- `.tekton/pipelinerun.yml`: PipelineRun trigger manifest for execution on OpenShift.
- `Dockerfile`: Container image build configuration for the Hit Counter Flask microservice.
- `requirements.txt`: Python package dependencies (Flask, Gunicorn, Flake8, Nose, etc.).
- `setup.cfg`: Configuration presets for Nose test runner and Flake8 linter.
- `service/`: Source code package containing Flask route handlers and loggers.
- `tests/`: Automated unit test suite verifying microservice REST endpoints.

---

## License

Licensed under the Apache License. See [LICENSE](/LICENSE)

## Author

Skills Network

## <h3 align="center"> © IBM Corporation 2023. All rights reserved. <h3/>
