# CI/CD with GitHub Actions and ArgoCD

After the application was containerized, deployed on Kubernetes, and packaged as a Helm chart, the next step was to automate the full delivery workflow.

At this point, the project already had all the individual building blocks:

* a working Go application
* a Docker image
* Kubernetes manifests
* a reusable Helm chart
* an EKS cluster capable of running the application

What was still missing was automation.

Until this phase, changes to the application still required several manual steps:

* build the application image
* run tests
* push the image to Docker Hub
* update the image tag in the Helm chart
* deploy the updated chart to Kubernetes

The goal of this phase was to automate that entire flow using **GitHub Actions for Continuous Integration (CI)** and **ArgoCD for Continuous Delivery (CD)**.

This transformed the project from a manually deployed Kubernetes application into a **GitOps-driven delivery pipeline**.

---

# What This CI/CD Phase Does

The pipeline in this project is split into two major parts:

## CI — GitHub Actions

GitHub Actions is responsible for:

* building the application
* running unit tests
* performing static code analysis
* building the Docker image
* pushing the image to Docker Hub
* updating the Helm chart with the new image tag

## CD — ArgoCD

ArgoCD is responsible for:

* watching the Git repository for Helm chart changes
* detecting the updated image tag in `values.yaml`
* pulling the Helm chart from Git
* deploying the updated application to the Kubernetes cluster

So the overall flow becomes:

```text
Developer pushes code to GitHub
        ↓
GitHub Actions runs CI pipeline
        ↓
Application is tested and Docker image is built
        ↓
Image is pushed to Docker Hub
        ↓
Helm values.yaml is updated with the new image tag
        ↓
Change is pushed back to GitHub
        ↓
ArgoCD detects the Git change
        ↓
ArgoCD syncs the Helm chart
        ↓
Kubernetes deploys the new application version
```

This is the core GitOps flow of the project.

---

# CI — Continuous Integration Using GitHub Actions

The CI pipeline was implemented using **GitHub Actions**.

Its purpose is to automatically validate and package the application whenever code changes are pushed to the repository.

In this project, the CI workflow performs four main responsibilities:

1. **Build and Unit Test**
2. **Static Code Analysis**
3. **Create and Push Docker Image**
4. **Update the Helm Chart with the Latest Image Tag**

---

# CI Pipeline Responsibilities

## 1. Build and Unit Test

The first stage ensures that the Go application builds correctly and that unit tests pass before anything is packaged or deployed.

This acts as a quality gate so that broken application code does not move forward into the deployment pipeline.

## 2. Static Code Analysis

The pipeline also includes static code checks so that basic code quality issues can be detected early in the CI process.

## 3. Create and Push Docker Image

Once the application passes the earlier checks, GitHub Actions builds the Docker image and pushes it to Docker Hub.

## 4. Update Helm with the New Docker Image Tag

After pushing the image, the workflow updates the Helm chart’s `values.yaml` so that the deployment points to the newly built image tag.

This step is what connects CI to CD.

---

# CI Workflow File

The complete CI pipeline is defined in:

```text
.github/workflows/ci.yaml
```

This workflow is responsible for building, testing, packaging, and preparing the deployment metadata for ArgoCD.

---

# Why GitHub Secrets Were Used

The workflow needs access to sensitive information such as:

* Docker Hub username
* Docker Hub access token
* GitHub Personal Access Token for committing Helm updates back to the repository

Hardcoding those values directly into the workflow file would be insecure and would expose credentials inside the repository.

To avoid that, **GitHub Actions secrets** were used.

This allows the workflow to consume sensitive values securely at runtime without storing them in plain text in the codebase.

---

# Example: Docker Build and Push Stage

A key part of the workflow is the job that logs into Docker Hub, builds the image, and pushes it.

Example excerpt:

```yaml
push-docker:
  runs-on: ubuntu-latest
  needs: build

  steps:
    - name: Checkout Repository
      uses: actions/checkout@v6

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v4

    - name: Login to Docker Hub
      uses: docker/login-action@v4
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}

    - name: Build and Push action
      uses: docker/build-push-action@v7
      with:
        context: .
        file: ./Dockerfile
        push: true
        tags: ${{ secrets.DOCKERHUB_USERNAME }}/go-web-app:${{ github.run_id }}
```

---

# Understanding What This Job Does

This part of the pipeline performs several important actions:

## 1. Checks out the repository

The workflow first pulls the source code into the GitHub Actions runner.

## 2. Sets up Docker Buildx

This prepares the environment for modern Docker image builds.

## 3. Logs in to Docker Hub

The workflow authenticates securely using secrets rather than hardcoded credentials.

## 4. Builds and pushes the image

The Docker image is built from the project’s `Dockerfile` and pushed to Docker Hub.

The image is tagged as:

```text
<dockerhub-username>/go-web-app:${{ github.run_id }}
```

This is a very important design choice.

---

# Why `github.run_id` Was Used as the Image Tag

Instead of repeatedly using a static tag like `latest` or `v1`, the pipeline uses:

```yaml
${{ github.run_id }}
```

as the image tag.

This means every workflow run generates a unique Docker image tag.

For example:

```text
nayanjk/go-web-app:10016307834
```

This has several benefits:

* every CI run produces a unique deployable artifact
* image versions are traceable back to a specific pipeline run
* there is no ambiguity about which image is currently deployed
* rollbacks become easier because each build has a distinct tag

This also connects directly to Helm and ArgoCD, because the same generated tag is later written into `values.yaml`.

---

# Updating the Helm Chart from CI

After the Docker image is pushed successfully, the next job in the pipeline updates the Helm chart so that Kubernetes will know which image version to deploy.

Example excerpt:

```yaml
update-newtag-in-helm-chart:
  runs-on: ubuntu-latest

  needs: push-docker

  steps:
    - name: Checkout Repository
      uses: actions/checkout@v7
      with:
        token: ${{ secrets.TOKEN_GITHUB }}
```

This job uses a **GitHub Personal Access Token** so that the workflow can commit changes back to the repository.

The core idea here is simple:

1. CI builds and pushes a new image
2. CI edits `helm/go-web-app-chart/values.yaml`
3. It replaces the old image tag with the newly generated `${{ github.run_id }}`
4. It commits and pushes that change back to GitHub

That updated `values.yaml` then becomes the signal for ArgoCD to deploy the new version.

---

# GitHub Secrets Configured for the Workflow

To support this automation, the following repository secrets were configured:

* Docker Hub username
* Docker Hub token
* GitHub Personal Access Token

These secrets are used by the workflow to:

* authenticate to Docker Hub
* push the built image
* push the updated Helm values back to GitHub

---

<img width="921" height="229" alt="image" src="https://github.com/user-attachments/assets/32af666b-eddf-493e-be18-a8f442c51a70" />

---

# Testing the CI Pipeline

Once the workflow was written, the CI pipeline was tested by committing and pushing the changes to GitHub.

Example:

```bash
git add .
git commit -m "Adding and Testing CI"
git push origin main
```

This push triggered the GitHub Actions workflow automatically.

---

# Troubleshooting During CI Setup

While testing the CI pipeline, a few issues came up before the final workflow succeeded.

---

## 1. Workflow errors during initial testing

There were some initial failures while validating the workflow configuration.

---

<img width="1859" height="946" alt="image" src="https://github.com/user-attachments/assets/6028c8a4-7b71-40d9-bd73-955fd66873b4" />

---

These issues were corrected in the final version of the workflow.

---

## 2. Go test path / execution issues

During testing, some fixes were needed around Go test execution and path usage, especially around how relative paths behave.

This highlighted the importance of understanding path references such as:

```text
./...
```

in Go testing workflows.

That notation is important because it tells Go to run tests recursively across packages in the project rather than only in the current directory.

---

## 3. GitHub Action version corrections

A few action versions also had to be adjusted during testing to ensure compatibility and correct execution.

These are the kinds of small but realistic issues that often appear while wiring up CI pipelines for the first time.

---

# Final CI Pipeline Success

After fixing the workflow issues, the CI pipeline completed successfully.

---

<img width="1304" height="873" alt="image" src="https://github.com/user-attachments/assets/1dac56c7-e569-42b5-8565-f21f318b3a7d" />

---

This confirmed that the workflow was able to:

* build the application
* run tests
* build the Docker image
* push the image to Docker Hub
* update the Helm chart

---

# Verifying the Docker Image in Docker Hub

Once the workflow completed, the Docker Hub registry was checked to confirm that the image had been pushed successfully with the expected tag.

---

<img width="1585" height="805" alt="image" src="https://github.com/user-attachments/assets/58c4161f-6657-4ca7-ba5b-e92fd6d15ab0" />

---

This validated that the CI pipeline had successfully published a uniquely tagged image.

---

# Verifying the Helm Chart Update

The next check was to confirm that the same CI-generated tag had been written into the Helm chart’s `values.yaml`.

That was observed successfully:

---

<img width="1328" height="174" alt="image" src="https://github.com/user-attachments/assets/a0ce3707-7f9f-4085-ab26-fdd8b599e8f0" />

---

This is one of the most important points in the entire pipeline because this file update is what connects CI to ArgoCD.

Once `values.yaml` contains the new image tag, the Git repository now reflects the desired new deployment state.

---

# Why Updating `values.yaml` Is the GitOps Trigger

This project follows a GitOps-style model.

That means the source of truth for deployment is **Git**, not an imperative `kubectl set image` command run manually against the cluster.

So instead of directly telling Kubernetes:

> deploy image X

the pipeline updates the desired state in Git:

> the Helm chart should now use image tag `10016307834`

ArgoCD then sees that Git has changed and reconciles the cluster to match that new desired state.

That is the GitOps handoff point between CI and CD.

---

# CD — Continuous Delivery Using ArgoCD

Once CI was in place, the next step was to automate deployment using **ArgoCD**.

ArgoCD is a GitOps continuous delivery tool for Kubernetes. Instead of manually applying manifests or Helm charts after every change, ArgoCD continuously watches a Git repository and ensures that the cluster matches the desired state stored there.

In this project, ArgoCD was used to:

* watch the Helm chart stored in GitHub
* detect updates to `values.yaml`
* pull the latest chart version
* deploy the updated image to the EKS cluster

---

# Installing ArgoCD

ArgoCD was installed into the Kubernetes cluster using its official installation manifest.

```bash
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

This created the ArgoCD components inside the `argocd` namespace.

---

# Exposing the ArgoCD UI

By default, the ArgoCD server service is not externally accessible in a convenient way.
To access the ArgoCD web UI, the `argocd-server` service was patched to type **LoadBalancer**.

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

This allowed AWS to provision an external load balancer for the ArgoCD server.

---

<img width="1520" height="441" alt="image" src="https://github.com/user-attachments/assets/b239aa76-2022-4e75-835c-d2f794c9eb69" />

---

Once the LoadBalancer was created, the ArgoCD UI became reachable through the external address.

---

# Logging into ArgoCD for the First Time

When the ArgoCD UI was opened in the browser, it prompted for a username and password.

---

<img width="1918" height="792" alt="Screenshot 2026-06-28 193813" src="https://github.com/user-attachments/assets/43de8cc6-8ce2-4d43-921e-20e6f2832111" />

---

## Default Username

The default username is:

```text
admin
```

## Retrieving the Initial Password

ArgoCD stores the initial admin password in a Kubernetes secret.

To inspect the relevant secrets:

```bash
kubectl get secrets -n argocd
```

This shows a secret named:

```text
argocd-initial-admin-secret
```

The password inside that secret is base64 encoded, so it needs to be decoded before use.

For example:

```bash
echo <encoded-password> | base64 --decode
```

The decoded value is the actual login password for the ArgoCD admin user.

Once this password was retrieved, the ArgoCD UI became accessible successfully.

---

<img width="1871" height="597" alt="image" src="https://github.com/user-attachments/assets/34fd7e09-8ded-45ea-a0b4-40bb05077547" />

---

# Creating the ArgoCD Application

Once logged into ArgoCD, the next step was to create a new ArgoCD application.

This application tells ArgoCD:

* which Git repository to watch
* where the Helm chart is located
* which Kubernetes cluster / namespace to deploy into
* which revision / branch to track

The application was created through the ArgoCD UI using the **New App** option.

---

<img width="1871" height="597" alt="image" src="https://github.com/user-attachments/assets/34fd7e09-8ded-45ea-a0b4-40bb05077547" />

---

The application configuration pointed ArgoCD to the Helm chart stored in the repository.

---

<img width="354" height="508" alt="Screenshot 2026-06-28 230311" src="https://github.com/user-attachments/assets/1f4bccb8-18f8-42f8-aa3d-6ff3e9cff33e" />

---

<img width="788" height="857" alt="image" src="https://github.com/user-attachments/assets/3cf1ac96-350f-47a9-8177-ec21ef91eb82" />

---

# How ArgoCD Fits into This Pipeline

Once the ArgoCD application is configured, the deployment flow becomes:

1. CI pushes a new Docker image
2. CI updates `values.yaml` with the new image tag
3. CI commits the updated chart back to GitHub
4. ArgoCD detects that the Helm chart in Git has changed
5. ArgoCD pulls the updated chart
6. ArgoCD syncs the new desired state into Kubernetes
7. Kubernetes deploys the new application version

So ArgoCD is not building images and not editing YAML — it is simply ensuring that the cluster matches what Git says should exist.

---

# Important Note: Ingress Controller Must Be Running

Since the application is exposed through Ingress, it is important to ensure that the **NGINX Ingress Controller** is running properly in the cluster.

If the ingress controller is missing or unhealthy, the Ingress resource may not receive a load balancer address and the application will not be reachable externally even if ArgoCD deploys all resources successfully.

This is an important operational dependency in the overall setup.

---

# Final ArgoCD Deployment Result

Once ArgoCD was configured and the Helm chart was synced, the application resources were successfully deployed into the cluster.

---

<img width="1871" height="626" alt="image" src="https://github.com/user-attachments/assets/51306706-954d-4692-967c-6c103d06d573" />

---

ArgoCD displayed the application and its managed Kubernetes resources, confirming that the deployment was under GitOps control.

---

<img width="1202" height="360" alt="image" src="https://github.com/user-attachments/assets/b35039da-ec8d-4d7a-b778-11de4b3b391e" />

---

# Verifying the Application After ArgoCD Deployment

Finally, the application was tested again from the client side:

```bash
curl go-web-app.local/courses
```

This returned the expected HTML response, confirming that the application was being served correctly after ArgoCD deployment.

```html
<!DOCTYPE html>
<html>
    <head>
        <title>Learn DevOps from Basics</title>
```

This was the final confirmation that the full CI/CD pipeline was working end to end.

---

# Why `/etc/hosts` Mapping Was Still Required

Even after ArgoCD successfully deployed the application, the hostname:

```text
go-web-app.local
```

still needed to be mapped on the client side.

That is because `.local` is only a custom local hostname used for testing. The operating system does not automatically know where `go-web-app.local` should point unless that mapping is defined.

So local hostname mapping in `/etc/hosts` was still required for testing the ingress host.

---

# What Would Happen in Production

In a real production environment, this manual hostname mapping would not be used.

Instead, a real domain would be purchased or managed through a DNS provider, and that domain would point to the external load balancer created for the Ingress.

For example:

```text
go-web-app.com
        ↓
a4a31af79657346d08d198d7a8999102.elb.us-west-2.amazonaws.com
```

In that setup, users would access the application through the actual domain name, and DNS would resolve it properly without any manual `/etc/hosts` changes.

---

# End-to-End Flow of the Final Pipeline

By the end of this phase, the project supported the following automated workflow:

## Step 1 — Developer pushes code to GitHub

A code change is pushed to the repository.

## Step 2 — GitHub Actions runs the CI pipeline

The workflow builds, tests, analyzes, and packages the application.

## Step 3 — Docker image is pushed to Docker Hub

A uniquely tagged image is created using the GitHub Actions run ID.

## Step 4 — Helm `values.yaml` is updated

The CI workflow writes the new image tag into the Helm chart.

## Step 5 — GitHub receives the updated Helm chart

The new desired deployment state is now stored in Git.

## Step 6 — ArgoCD detects the Git change

ArgoCD sees that the Helm chart has changed and syncs the update.

## Step 7 — Kubernetes deploys the new image

The EKS cluster rolls out the updated application.

This is the complete CI/CD pipeline implemented in the project.

---

# What This Phase Achieved

By the end of this phase, the project had evolved from a manually operated Kubernetes deployment into a **fully automated GitOps delivery workflow**.

More specifically, this phase achieved the following:

## CI Achievements

* automated build and unit testing
* static code analysis
* automated Docker image creation
* automated Docker Hub push
* automated Helm values update with the latest image tag

## CD Achievements

* ArgoCD installation on Kubernetes
* ArgoCD UI exposure using a LoadBalancer
* GitOps application configuration pointing to the Helm chart
* automatic deployment of the updated Helm chart to the cluster

## End-to-End Outcome

* source code changes can now trigger a full build and deployment flow
* the cluster state is driven from Git
* Helm acts as the deployment package
* ArgoCD acts as the Git-to-cluster reconciler
* the application becomes continuously deliverable with minimal manual intervention

---

# Why This Is the Most Important Phase of the Project

This phase is where all the previous work comes together.

* Local testing validated the application.
* Docker made it portable.
* Kubernetes made it deployable.
* Helm made it reusable.
* CI/CD made it automated.

Without this phase, the project would still be a manually operated deployment exercise.

With this phase in place, it becomes a much more realistic DevOps project because it demonstrates the full lifecycle of a modern cloud-native application:

* code change
* automated build
* automated image publishing
* Git-based deployment update
* Kubernetes rollout through GitOps

That is what makes the project much stronger from a DevOps and platform engineering perspective.

---

# Key Takeaways from This Phase

### 1. CI and CD should be treated as separate concerns

GitHub Actions handles build, packaging, and update preparation. ArgoCD handles deployment synchronization.

### 2. Updating Helm values in Git is the GitOps handoff point

The CI pipeline does not deploy directly to Kubernetes. It updates the desired state in Git, and ArgoCD handles the actual deployment.

### 3. Unique image tags are better than reusing `latest`

Using `${{ github.run_id }}` makes builds traceable and deployment versions explicit.

### 4. Secrets should never be hardcoded in workflows

GitHub Secrets are the right way to inject sensitive credentials such as Docker Hub tokens and GitHub PATs.

### 5. ArgoCD continuously reconciles desired and actual state

This means the cluster stays aligned with the Git repository, which is the essence of GitOps.

---

# Summary of the CI/CD Journey

This phase implemented the complete delivery automation for the project.

The GitHub Actions pipeline was responsible for building the application, testing it, packaging it into a Docker image, pushing it to Docker Hub, and updating the Helm chart with the latest image tag.

ArgoCD was then configured to watch that Helm chart in Git and deploy the updated application automatically into the Kubernetes cluster.

By the end of this phase, the project had become a **fully automated GitOps-driven Go web application deployment on EKS**, backed by Docker, Helm, GitHub Actions, and ArgoCD.

---

# Next Step

At this point, your core implementation journey is complete.

The best final section after this would be a dedicated **Troubleshooting / Lessons Learned** section that captures the real-world problems you hit during the project, such as:

* local route confusion (`/courses`)
* NodePort not reachable because of security groups
* Ingress hostname resolution issue
* WSL vs Windows `/etc/hosts` behavior
* Helm templating mistakes
* GitHub Actions workflow errors
* ArgoCD / ingress dependencies

➡️ Continue to: **Troubleshooting and Key Learnings**
