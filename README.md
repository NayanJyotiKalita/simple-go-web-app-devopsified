# 🚀 Simple Go Web App — DevOpsified

A production-style DevOps implementation of a **Go web application**, taking it from **local development → Docker containerization → Kubernetes deployment on Amazon EKS → Helm templating → CI with GitHub Actions → CD with ArgoCD**.

This project was built as a complete hands-on exercise to understand not just deployment, but the **entire software delivery lifecycle** of an application — including the **real troubleshooting journey** around Kubernetes Services, NodePort, Ingress, ELB hostname mapping, and WSL/Windows DNS resolution.

---

# 📌 Table of Contents

* [Project Overview](#-project-overview)
* [Key Features](#-key-features)
* [Tech Stack](#-tech-stack)
* [Architecture](#-architecture)
* [Project Structure](#-project-structure)
* [Prerequisites](#-prerequisites)
* [Application Workflow](#-application-workflow)
* [1. Local Application Testing](#1-local-application-testing)
* [2. Containerization with Docker](#2-containerization-with-docker)
* [3. Kubernetes Deployment on EKS](#3-kubernetes-deployment-on-eks)
* [4. Exposing the Application](#4-exposing-the-application)

  * [Using NodePort for Initial Testing](#using-nodeport-for-initial-testing)
  * [Using Ingress + AWS Load Balancer](#using-ingress--aws-load-balancer)
* [5. Helm Charting](#5-helm-charting)
* [6. CI with GitHub Actions](#6-ci-with-github-actions)
* [7. CD with ArgoCD](#7-cd-with-argocd)
* [8. End-to-End CI/CD Flow](#8-end-to-end-cicd-flow)
* [How to Run This Project](#-how-to-run-this-project)
* [Troubleshooting Summary](#-troubleshooting-summary)
* [Key Learnings from This Project](#-key-learnings-from-this-project)
* [Future Improvements](#-future-improvements)

---

# 📖 Project Overview

This repository demonstrates how to take a simple Go web application and progressively transform it into a **production-style, automated deployment pipeline**.

The project includes:

* Running and validating the application locally
* Writing a **multi-stage Dockerfile**
* Building and pushing the image to **Docker Hub**
* Creating Kubernetes manifests for:

  * **Deployment**
  * **Service**
  * **Ingress**
* Deploying the application on **Amazon EKS**
* Exposing the application using **NodePort** and then **Ingress**
* Installing and using **NGINX Ingress Controller**
* Converting raw Kubernetes manifests into a **Helm chart**
* Creating a **CI pipeline with GitHub Actions**
* Using **ArgoCD for continuous delivery**
* Automatically updating Helm image tags through CI
* Troubleshooting real-world issues such as:

  * NodePort inaccessibility
  * Security Group misconfiguration
  * Ingress hostname resolution issues
  * WSL vs Windows `/etc/hosts` confusion

---

# ✨ Key Features

* **Go Web Application** served on port `8080`
* **Multi-stage Docker build** using a **distroless runtime image**
* **Kubernetes Deployment** on **Amazon EKS**
* **Service exposure** via ClusterIP, NodePort, and Ingress
* **NGINX Ingress Controller** backed by AWS Load Balancer
* **Helm templating** for reusable and environment-friendly deployments
* **CI pipeline with GitHub Actions** for:

  * Build
  * Test
  * Docker image push
  * Helm chart image tag update
* **CD pipeline with ArgoCD** for automated deployment sync
* End-to-end **GitOps-style flow**
* Detailed documentation of **troubleshooting and debugging steps**

---

# 🛠 Tech Stack

## Application

* **Go**
* HTML/CSS static frontend

## Containerization

* **Docker**
* **Distroless base image**

## Orchestration / Deployment

* **Kubernetes**
* **Amazon EKS**
* **NGINX Ingress Controller**

## Packaging / Templating

* **Helm**

## CI/CD

* **GitHub Actions**
* **Docker Hub**
* **ArgoCD**

## Cloud / Platform

* **AWS EC2 / EKS / ELB**

---

# 🏗 Architecture

## High-level flow

```text
Developer Commit
      │
      ▼
GitHub Repository
      │
      ▼
GitHub Actions (CI)
 ├── Build Go App
 ├── Run Tests
 ├── Build Docker Image
 ├── Push Docker Image to Docker Hub
 └── Update Helm values.yaml with latest image tag
      │
      ▼
GitHub Repository (updated Helm values)
      │
      ▼
ArgoCD (CD)
 └── Detects Helm chart changes and syncs to cluster
      │
      ▼
Amazon EKS
 ├── Deployment
 ├── Service
 └── Ingress
      │
      ▼
NGINX Ingress Controller
      │
      ▼
AWS Load Balancer
      │
      ▼
Application accessible via hostname
```

---

# 📂 Project Structure

```bash
simple-go-web-app-devopsified/
├── .github/
│   └── workflows/
│       └── ci.yaml                  # CI workflow
│ 
├── 01-local-testing
│   └── readme.md
│ 
├── 02-containerization
│   └── readme.md
│ 
├── 03-k8s
│   ├── manifests
│   │   ├── deployment.yaml
│   │   ├── ingress.yaml
│   │   └── service.yaml
│   └── readme.md
│ 
├── 04-helm
│   ├── go-web-app-chart
│   │   ├── Chart.yaml
│   │   ├── templates
│   │   │   ├── deployment.yaml
│   │   │   ├── ingress.yaml
│   │   │   └── service.yaml
│   │   └── values.yaml
│   └── readme.md
│ 
├── 05-gitops
│   ├── argocd
│   │   └── argo-setup.md
│   └── readme.md
│ 
├── 06-troubleshooting
│   └── readme.md
│ 
├── Dockerfile
│ 
├── EKS
│   ├── 1-prerequisites.md
│   └── 2-installing&deleting-eks.md
│ 
├── README.md
├── go.mod
├── main.go
├── main_test.go
└── static/           # Static frontend assets
```

---

# 📋 Prerequisites

Before running this project, make sure you have the following tools installed.

## Local Development

* **Go** `1.26+`
* **Docker**
* **Git**

## Kubernetes / Cloud

* **kubectl**
* **eksctl**
* **AWS CLI**
* **An AWS account** with permissions to create:

  * EKS clusters
  * EC2 worker nodes
  * Load Balancers
  * Security Group rules

## Packaging / CD

* **Helm**
* **ArgoCD**

## Optional / Recommended

* Docker Hub account
* GitHub Personal Access Token for workflow automation
* WSL / Linux terminal if working on Windows

---

# 🔄 Application Workflow

The application exposes a Go web service that serves a web page at:

```bash
http://localhost:8080/courses
```

This route is important because it becomes the basis for all later validation:

* local testing
* Docker testing
* Kubernetes testing
* Ingress testing
* CI/CD deployment verification

---

# 1. Local Application Testing

Before touching Docker or Kubernetes, the application should first be tested locally.

## Why this matters

Validating the app locally helps catch:

* incorrect routes
* broken application logic
* missing dependencies
* incorrect assumptions about the startup command

## Run locally

```bash
go run main.go
```

## Verify

```bash
curl http://localhost:8080/courses
```

If the application is healthy, it should return the HTML response for the page.

---

<img width="1272" height="927" alt="image" src="https://github.com/user-attachments/assets/b628191f-044f-43bd-9a16-f12fec7ea775" />

---

---

# 2. Containerization with Docker

The application is containerized using a **multi-stage Docker build**.

## Dockerfile

```dockerfile
FROM golang:1.26 AS base

WORKDIR /app

COPY go.mod .
RUN go mod download

COPY . .
RUN go build -o main .

FROM gcr.io/distroless/base

COPY --from=base /app/main .
COPY --from=base /app/static ./static

EXPOSE 8080

CMD ["./main"]
```

---

## Why this Dockerfile?

### Multi-stage build

The Go binary is built in the builder image, while the final runtime image remains lightweight.

### Distroless image

The final image contains only what is needed to run the app, reducing:

* image size
* attack surface
* unnecessary runtime dependencies

### Static assets included

The application depends on HTML/CSS files from the `static/` directory, so they must also be copied into the final image.

---

## Build the Docker image

```bash
docker build -t <dockerhub-username>/go-web-app:v1 .
```

## Run the container locally

```bash
docker run -p 8080:8080 <dockerhub-username>/go-web-app:v1
```

## Test

```bash
curl http://localhost:8080/courses
```
---

<img width="1538" height="773" alt="Screenshot 2026-06-17 180709" src="https://github.com/user-attachments/assets/6e2676b0-95bf-4ec9-b99c-9d638fbe7c25" />

---
---

## Push image to Docker Hub

```bash
docker login
docker push <dockerhub-username>/go-web-app:v1
```

---

# 3. Kubernetes Deployment on EKS

Kubernetes manifests were written for:

* **Deployment**
* **Service**
* **Ingress**

## Manifest responsibilities

### `deployment.yaml`

Responsible for:

* creating the application pods
* defining labels/selectors
* specifying the Docker image
* exposing container port `8080`

### `service.yaml`

Responsible for:

* giving the application a stable internal endpoint
* forwarding traffic from Service port `80` to application port `8080`

### `ingress.yaml`

Responsible for:

* exposing the application externally
* routing requests to the Service based on hostname/path rules

---

## Create EKS cluster

```bash
eksctl create cluster --name <CLUSTER-NAME> --region <AWS-REGION>
```

Verify:

```bash
kubectl get nodes
```

---

## Deploy manifests

```bash
kubectl apply -f k8s/manifests/deployment.yaml
kubectl apply -f k8s/manifests/service.yaml
kubectl apply -f k8s/manifests/ingress.yaml
```
---

<img width="845" height="360" alt="image" src="https://github.com/user-attachments/assets/7fea2646-2683-46d1-8124-f4649510cedf" />

---
---

# 4. Exposing the Application

The application was exposed in two phases:

1. **NodePort** for direct connectivity testing
2. **Ingress + AWS Load Balancer** for a more production-like access pattern

---

# Using NodePort for Initial Testing

Initially, the Service was changed from `ClusterIP` to `NodePort`.

## Example Service

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: go-web-app
  name: go-web-app

spec:
  ports:
    - port: 80
      protocol: TCP
      targetPort: 8080
  selector:
    app: go-web-app
  type: NodePort
```

## Verify the NodePort

```bash
kubectl get svc
```

Example output:

```bash
NAME         TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)
go-web-app   NodePort   10.100.x.x      <none>        80:32379/TCP
```

## Access the app

```bash
http://<NODE-EXTERNAL-IP>:<NODEPORT>
```

Example:

```bash
http://35.164.247.96:32379
```

---

## NodePort issue encountered

The application still could not be reached from the browser even though the NodePort service existed.

---

<img width="750" height="571" alt="Screenshot 2026-06-23 000013" src="https://github.com/user-attachments/assets/36f6f5df-0a36-4ab6-99c3-f153798d9ca0" />

---

### Root cause

A Kubernetes NodePort only opens a port on the node. AWS must still allow external traffic to reach that port.

The missing piece was the **EC2 worker node security group**.

---

<img width="1625" height="397" alt="image" src="https://github.com/user-attachments/assets/7092e11b-515f-460e-80b4-9c432909375b" />

---

### Fix

Open the NodePort in the security group.

For example, if the NodePort is `32379`, allow inbound traffic on:

```text
TCP 32379
```

---

<img width="1642" height="356" alt="image" src="https://github.com/user-attachments/assets/8b060558-8618-4b24-8ece-23084b0beb70" />

---

Once the security group was updated, the NodePort endpoint worked successfully.

---

<img width="1505" height="744" alt="image" src="https://github.com/user-attachments/assets/00132e4b-c54b-46aa-93df-08366fb37314" />

---
---

# Using Ingress + AWS Load Balancer

NodePort is useful for testing, but it is not ideal for application exposure in a production-style architecture.

The next step was to expose the application using an **Ingress resource** and **NGINX Ingress Controller**.

## Example Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: go-web-app

spec:
  ingressClassName: nginx
  rules:
    - host: go-web-app.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: go-web-app
                port:
                  number: 80
```

---

## Install NGINX Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.15.1/deploy/static/provider/aws/deploy.yaml
```

Verify:

```bash
kubectl get pods -n ingress-nginx
```

---

## Check Ingress

```bash
kubectl get ingress
```

Once the Ingress Controller provisions the Load Balancer, the `ADDRESS` field gets populated with an ELB DNS name.

Example:

```text
af1c475d2f805413b85b38159055f2bc-f193cd6541f83b02.elb.us-west-2.amazonaws.com
```

---

## Hostname-based routing

The ingress rule uses:

```yaml
host: go-web-app.local
```

This means requests are expected to come in using the hostname:

```bash
http://go-web-app.local/courses
```

---

## Hostname mapping issue encountered

Even after the Load Balancer was created, the application still could not be reached through `go-web-app.local`.

---

<img width="1046" height="159" alt="image" src="https://github.com/user-attachments/assets/18f56414-eb4b-4525-9328-fc57c57652ee" />

---

### Why?

The system does not know what `go-web-app.local` means unless it is explicitly mapped through DNS or a hosts file.

### Temporary testing approach

Map one of the ELB IPs to the hostname:
```sh
chucky@Dell:~/simple-go-web-app-devopsified/k8s/manifests$ nslookup af1c475d2f805413b85b38159055f2bc-f193cd6541f83b02.elb.us-west-2.amazonaws.com
Server:         10.255.255.254
Address:        10.255.255.254#53

Non-authoritative answer:
Name:   af1c475d2f805413b85b38159055f2bc-f193cd6541f83b02.elb.us-west-2.amazonaws.com
Address: 100.23.52.116
Name:   af1c475d2f805413b85b38159055f2bc-f193cd6541f83b02.elb.us-west-2.amazonaws.com
Address: 34.213.83.57
Name:   af1c475d2f805413b85b38159055f2bc-f193cd6541f83b02.elb.us-west-2.amazonaws.com
Address: 52.42.84.42
```

```text
52.42.84.42 go-web-app.local
```

---

## WSL vs Windows hostname issue

This turned out to be one of the most important troubleshooting moments in the project.

### What happened

The hostname mapping was added inside the **WSL** hosts file:

```bash
/etc/hosts
```
```vi
52.42.84.42   go-web-app.local
```

but the browser was running on **Windows**, which uses:

```text
C:\Windows\System32\drivers\etc\hosts
```

So:

* `curl` inside WSL worked
* the Windows browser still failed to resolve the hostname

### Resolution

Either:

1. add the hostname mapping to the **Windows hosts file**, or
2. test from the **WSL terminal** itself using `curl`

Once the mapping was tested in the correct environment, the application was successfully accessible.

---

# 5. Helm Charting

After validating the raw manifests, the deployment was converted into a **Helm chart**.

## Why Helm?

Helm helps package Kubernetes applications in a reusable and environment-friendly way.

Instead of hardcoding values directly into manifests, Helm allows you to parameterize things like:

* image tags
* replica counts
* ingress settings
* hostnames
* environment-specific overrides

---

## Create Helm chart

```bash
helm create go-web-app-chart
```

Then replace the default templates with the project’s own manifests:

* `deployment.yaml`
* `service.yaml`
* `ingress.yaml`

---

## Example templating

### `templates/deployment.yaml`

```yaml
containers:
  - image: nayanjk/go-web-app:{{ .Values.image.tag }}
    name: nginx
    ports:
      - containerPort: 8080
```

### `values.yaml`

```yaml
replicaCount: 1

image:
  repository: nayanjk/go-web-app
  pullPolicy: IfNotPresent
  tag: "v1"

ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: ImplementationSpecific
```

---

## Deploy using Helm

```bash
cd helm/go-web-app-chart
helm install go-web-app .
```
---

<img width="845" height="486" alt="image" src="https://github.com/user-attachments/assets/dc45ce9c-209f-4554-8846-882700176914" />

---

## Remove Helm release

```bash
helm uninstall go-web-app
```
```
chucky@Dell:~/simple-go-web-app-devopsified$ helm uninstall go-web-app
release "go-web-app" uninstalled
chucky@Dell:~/simple-go-web-app-devopsified$ k get all
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP   2d3h
```

---

# 6. CI with GitHub Actions

A CI pipeline was built using **GitHub Actions**.

## CI responsibilities

* build the Go application
* run tests
* build Docker image
* push image to Docker Hub
* update Helm `values.yaml` with the latest image tag

---

## Workflow logic

### Step 1 — Build / Test

Validate the codebase and ensure the application builds successfully.

### Step 2 — Build Docker image

Create a new Docker image for the application.

### Step 3 — Push image to Docker Hub

Push the image using a unique tag.

### Step 4 — Update Helm values

Update the Helm chart with the latest image tag so that ArgoCD can deploy it.

---

## Example snippet

```yaml
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

## Secrets used

The workflow relies on GitHub Secrets:

* `DOCKERHUB_USERNAME`
* `DOCKERHUB_TOKEN`
* `TOKEN_GITHUB`

---

## Why `github.run_id` is used as image tag

Each workflow run gets a unique `github.run_id`, which is used as the Docker image tag.

Example:

```yaml
tag: "28332165890"
```

This makes it easy to:

* uniquely identify images
* map an image to a CI run
* update Helm automatically
* trigger ArgoCD deployment when the values file changes

---

<img width="1304" height="873" alt="image" src="https://github.com/user-attachments/assets/1dac56c7-e569-42b5-8565-f21f318b3a7d" />

---
---

# 7. CD with ArgoCD

ArgoCD is used to continuously deploy the Helm chart into the Kubernetes cluster.

## CD flow

1. CI updates the Helm chart’s image tag
2. The updated chart is pushed to GitHub
3. ArgoCD detects the change
4. ArgoCD syncs the application to EKS
5. Kubernetes pulls the new image and rolls out the updated app

---

## Install ArgoCD

```bash
kubectl create namespace argocd

kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

---

## Expose ArgoCD UI

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

---

## Retrieve admin password

```bash
kubectl get secrets -n argocd
kubectl edit secret -n argocd argocd-initial-admin-secret
```

The initial password is base64 encoded, so decode it before logging in.

---

## Configure ArgoCD Application

Create an ArgoCD Application pointing to the Helm chart path in this repository.

ArgoCD will then monitor that path and automatically sync changes whenever the chart or its values are updated.

---

<img width="1871" height="626" alt="image" src="https://github.com/user-attachments/assets/51306706-954d-4692-967c-6c103d06d573" />

---
---

<img width="1202" height="360" alt="image" src="https://github.com/user-attachments/assets/b35039da-ec8d-4d7a-b778-11de4b3b391e" />

---
---

# 8. End-to-End CI/CD Flow

Here is the full deployment lifecycle of the project:

## 1. Developer makes a change

For example, update `static/courses.html`.

```html
<DocType html>

<html>
    <head>
        <title>Learn DevOps from Basics with Nayan</title>
        <style>
            body {
                margin: 0;
                padding: 0;
            }
```

## 2. Push to GitHub

The push triggers GitHub Actions.

## 3. GitHub Actions CI runs

The pipeline:

* builds the Go app
* creates a Docker image
* pushes it to Docker Hub
* updates the Helm image tag in `values.yaml`

---

<img width="1274" height="491" alt="image" src="https://github.com/user-attachments/assets/b3433bf5-cdda-457c-94d3-461f8c148c91" />

---
---

## 4. Git repository is updated

The Helm chart now references the latest image.

```yaml
image:
  repository: nayanjk/go-web-app
  pullPolicy: IfNotPresent
  tag: "28332165890"
```
---

<img width="442" height="170" alt="image" src="https://github.com/user-attachments/assets/c1afb1c5-64d6-4d6a-b65b-68345a138797" />

---
---

## 5. ArgoCD detects the Helm change

ArgoCD syncs the updated release to the cluster.

## 6. EKS deploys the new version

Kubernetes pulls the new image and updates the application.

---
---

<img width="690" height="248" alt="image" src="https://github.com/user-attachments/assets/978bf394-1af1-4f93-a876-e58b763f3741" />

---
<<<<<<< HEAD:rough-readme.md
=======
---

# 🚀 How to Run This Project

## 1. Clone the repository

```bash
git clone https://github.com/<your-username>/simple-go-web-app-devopsified.git
cd simple-go-web-app-devopsified
```

---

## 2. Run locally

```bash
go run main.go
```

Verify:

```bash
curl http://localhost:8080/courses
```

---

## 3. Build and run Docker image

```bash
docker build -t <dockerhub-username>/go-web-app:v1 .
docker run -p 8080:8080 <dockerhub-username>/go-web-app:v1
```

---

## 4. Create EKS cluster

```bash
eksctl create cluster --name <cluster-name> --region <region>
```

---

## 5. Deploy raw Kubernetes manifests

```bash
kubectl apply -f 03-k8s/manifests/deployment.yaml
kubectl apply -f 03-k8s/manifests/service.yaml
kubectl apply -f 03-k8s/manifests/ingress.yaml
```

---

## 6. Install Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.15.1/deploy/static/provider/aws/deploy.yaml
```

---

## 7. Deploy using Helm

```bash
cd 04-helm/go-web-app-chart
helm install go-web-app .
```

---

## 8. Configure GitHub Secrets for CI

Add the following secrets in your GitHub repository:

* `DOCKERHUB_USERNAME`
* `DOCKERHUB_TOKEN`
* `TOKEN_GITHUB`

---

## 9. Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Expose the UI:

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

Then create an ArgoCD Application pointing to the Helm chart.

---

# 🧰 Troubleshooting Summary

This project surfaced several real-world issues that are worth documenting.

---

## 1. Local route verification is essential

Before containerizing or deploying, verify the exact route exposed by the application.

For this app, the correct route was:

```bash
http://localhost:8080/courses
```

A wrong assumption here causes confusion later in Docker, Kubernetes, and Ingress testing.

---

## 2. NodePort does not automatically mean internet access

Even if a NodePort service exists, the app may still be unreachable if the **AWS Security Group** does not allow traffic to that NodePort.

---

## 3. HTTP status codes tell you where the problem is

When testing through Ingress:

* **404** → request reached the backend, but the route was not found
* **502 / 503 / 504** → backend connectivity or availability issue

This was extremely helpful during debugging.

---

## 4. `kubectl port-forward` is a powerful isolation tool

If the application works through:

```bash
kubectl port-forward svc/go-web-app 9090:80
```

then:

* pod is healthy
* service is healthy
* internal Kubernetes networking is healthy

At that point, the problem is likely:

* Ingress
* DNS / hostname resolution
* external networking
* load balancer routing

---

## 5. Local port conflicts can interfere with testing

Port-forwarding to `8080` initially failed because Jenkins was already listening on port `8080`.

Check with:

```bash
sudo lsof -i :8080
```

If the port is occupied:

* stop the conflicting service, or
* use another local port such as `9090`

---

## 6. WSL and Windows hosts files are not the same thing

This was the biggest hostname-related lesson from the project.

If you add a hostname mapping in WSL:

```bash
/etc/hosts
```

but open the application in a **Windows browser**, the browser will not use the WSL hosts file.

You must either:

* add the mapping to the **Windows hosts file**
* or test from within WSL using `curl`

---

# 🎯 Key Learnings from This Project

This project was valuable not only because it covered the deployment workflow, but because it exposed the **operational and troubleshooting side of DevOps**.

## What I learned

* How to move a simple application from local development to a production-style deployment pipeline
* Why local validation should always come before containerization
* How multi-stage Docker builds and distroless images improve image quality
* The difference between:

  * ClusterIP
  * NodePort
  * Ingress
* Why Kubernetes exposure problems are often not Kubernetes problems, but **networking / DNS / cloud security problems**
* How Helm helps avoid duplication and makes deployments environment-friendly
* How GitHub Actions can automate not just builds, but also image promotion and Helm updates
* How ArgoCD fits into a GitOps deployment model
* How to troubleshoot a deployment layer by layer:

  * app
  * container
  * service
  * ingress
  * DNS
  * cloud networking

---

# 🔮 Future Improvements

This project can be extended further in several directions:

* Replace manual `/etc/hosts` mapping with **Route53 + a real domain**
* Add **TLS / HTTPS** using cert-manager + Let’s Encrypt
* Replace Ingress with **Gateway API**
* Add **Prometheus + Grafana** monitoring
* Add **Horizontal Pod Autoscaling**
* Provision the EKS cluster and supporting infrastructure with **Terraform**
* Add **security scanning** to CI (Trivy / Grype / Snyk)
* Add **unit test coverage reporting**
* Add **ArgoCD Application manifests** to Git instead of creating apps manually through the UI
* Create separate Helm values files for:

  * `dev`
  * `stage`
  * `prod`

---

# 📌 Final Note

This project was a strong end-to-end DevOps exercise because it didn’t stop at “the app is deployed.”

It covered the **complete delivery lifecycle**:

* local validation
* containerization
* Kubernetes deployment
* NodePort and Ingress exposure
* Helm templating
* CI with GitHub Actions
* GitOps-based CD with ArgoCD

More importantly, it captured the practical debugging that comes with real deployments — especially around **NodePort access**, **Ingress routing**, **ELB hostname mapping**, and **WSL vs Windows DNS resolution**.

If you’re learning DevOps, Kubernetes, CI/CD, or GitOps, this project is a great hands-on reference for how all of these pieces fit together in one workflow.

---
>>>>>>> 96734fd (Proper README file added):README.md
