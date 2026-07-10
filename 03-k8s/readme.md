# Kubernetes Deployment

After validating the application locally and containerizing it successfully, the next step is to deploy it on **Kubernetes**.

At this stage, the application is no longer just a local process or a Docker container — it becomes a **workload running inside a Kubernetes cluster**, managed through Kubernetes resources such as **Deployments**, **Services**, and **Ingress**.

This phase was important for two reasons:

1. It allowed the application to run in a production-like orchestration environment.
2. It exposed several practical networking and access-related issues that often appear when deploying applications to Kubernetes on cloud infrastructure.

In this project, the Kubernetes deployment was tested on **Amazon EKS**, and the application was exposed in two stages:

* first through a **NodePort Service**
* then through **Ingress + NGINX Ingress Controller + AWS Load Balancer**

---

# Goal of This Phase

The objective of this step was to take the Docker image created in the previous phase and deploy it inside a Kubernetes cluster using Kubernetes manifests.

To achieve that, we wrote manifests for:

* **Deployment** → to run the application pods
* **Service** → to expose the pods internally inside the cluster
* **Ingress** → to expose the application externally through a load balancer and host-based routing

---

# Kubernetes Manifests Used

For this project, three Kubernetes manifest files were written:

* [deployment.yaml](/03-k8s/manifests/deployment.yaml)
* [service.yaml](/03-k8s/manifests/service.yaml)
* [ingress.yaml](03-k8s/manifests/ingress.yaml)

---

## 1. `deployment.yaml`

The Deployment manifest is responsible for running the application as one or more pods inside the Kubernetes cluster.

Its responsibilities include:

* specifying the application container image
* defining labels and selectors
* exposing the container port (`8080`)
* managing pod lifecycle and replica management

In this project, the Go web application container listens on port `8080`, so that is the port exposed inside the Deployment.

---

## 2. `service.yaml`

The Service manifest provides a stable internal endpoint for the application pods.

Its job is to:

* expose the pods through a Kubernetes Service
* map a Service port to the application container port
* allow other Kubernetes resources to access the application without depending on changing pod IPs

In this project:

* **Service Port** = `80`
* **Target Port** = `8080`

This means Kubernetes clients can talk to the Service on port `80`, and the Service will forward the traffic to the Go application running on port `8080` inside the pod.

---

## 3. `ingress.yaml`

The Ingress manifest is responsible for exposing the application externally.

It allows us to define:

* hostname-based routing
* path-based routing
* integration with an Ingress Controller
* access to the application through a Load Balancer instead of directly through NodePorts

In this project, the ingress host was configured as:

```yaml
host: go-web-app.local
```

which later became important during the hostname resolution troubleshooting phase.

---

# Kubernetes Cluster for Testing

To test the application, we needed a Kubernetes cluster. Since the goal of the project was to make the deployment closer to a production-style setup, **Amazon EKS** was used as the Kubernetes platform. 

Refer the [EKS Documentation attached for this part](/EKS)

The cluster was created using `eksctl`.

```bash
eksctl create cluster --name <CLUSTER-NAME> --region <YOUR-REGION>
```

This created the EKS control plane and the worker nodes required to run the application.

---

## Cluster Creation

---

<img width="1498" height="752" alt="image" src="https://github.com/user-attachments/assets/bae119d6-c64f-4ce1-af2e-9415ebc2f97d" />

---

## Worker Nodes Ready

Once the cluster was created, the EC2 worker nodes were provisioned successfully.

---

<img width="1129" height="320" alt="image" src="https://github.com/user-attachments/assets/82abb538-a21d-49bc-8013-e8095d3ba07a" />

---

<img width="1553" height="809" alt="image" src="https://github.com/user-attachments/assets/b21f723b-1f69-4268-9202-b271c4eabd27" />

---

# Resolving Access / RBAC Issues

After the cluster was created, a few access-related issues had to be resolved before interacting properly with the cluster resources.

Necessary permissions were granted so that the user could access and manage the Kubernetes resources. This is a common step in EKS environments because access to the cluster often depends on IAM and RBAC configuration.

---

<img width="1538" height="611" alt="image" src="https://github.com/user-attachments/assets/1f69779d-f420-48f2-b148-3a9e171536d1" />

---

Once the permissions were configured correctly, the cluster resources became accessible.

---

<img width="1545" height="712" alt="image" src="https://github.com/user-attachments/assets/e5ca92f7-8295-4ed9-8731-ed7bed766c85" />

---

# Deploying the Application to Kubernetes

With the cluster ready, the next step was to deploy the application using the Deployment and Service manifests.

---

<img width="845" height="360" alt="image" src="https://github.com/user-attachments/assets/7fea2646-2683-46d1-8124-f4649510cedf" />

---

After applying the manifests, the Deployment and Service were successfully created in the cluster.

---

<img width="1631" height="733" alt="image" src="https://github.com/user-attachments/assets/e9fb67d0-30fc-424b-acd4-123977f483fc" />

---

At this point, the application was running inside Kubernetes, but it was still exposed only through a **ClusterIP Service**.

---

# Why the Application Was Still Not Reachable

Initially, the Service was configured as **ClusterIP**.

A ClusterIP Service is useful for internal communication inside the Kubernetes cluster, but it does **not** expose the application to the outside world.

So even though the application pods were running correctly and the Service existed, the application could not yet be reached from a browser outside the cluster.

That is why the next step was to test external exposure using **NodePort**.

---

# Testing the Application Using NodePort

To quickly test external access, the Service type was changed from **ClusterIP** to **NodePort**.

This is a common approach during initial debugging because a NodePort allows traffic to reach the application through:

```text
<Node External IP>:<NodePort>
```

---

## Updating the Service Type

The `service.yaml` file was updated from:

```yaml
type: ClusterIP
```

to:

```yaml
type: NodePort
```

The Service definition looked like this:

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: go-web-app
  name: go-web-app

spec:
  ports:
    - port: 80          # Port of the Service
      protocol: TCP
      targetPort: 8080  # Port of the application
  selector:
    app: go-web-app
  type: NodePort
```

This allowed Kubernetes to assign a port from the NodePort range and expose the Service through that port on every worker node.

---

## Re-apply the Service

```bash
kubectl apply -f service.yaml
```

After applying the updated Service, Kubernetes assigned a NodePort:

```text
80:32379/TCP
```

and the nodes had public IPs such as:

* `34.219.31.71`
* `35.164.247.96`

which meant the application should theoretically be reachable at:

```text
http://<NODE-EXTERNAL-IP>:32379
```

For example:

```text
http://35.164.247.96:32379
```

---

# NodePort Problem: Application Still Unreachable

Even after changing the Service to NodePort, the application was still not accessible from the browser.

---

<img width="750" height="571" alt="Screenshot 2026-06-23 000013" src="https://github.com/user-attachments/assets/36f6f5df-0a36-4ab6-99c3-f153798d9ca0" />

---

At first glance, this could look like a Kubernetes problem, but the real issue was outside Kubernetes.

---

# Troubleshooting the NodePort Issue

Further investigation showed an important point:

> A **NodePort only opens the port on the node** from the Kubernetes side. AWS must still allow internet traffic to reach that port on the EC2 worker nodes.

In other words, Kubernetes had done its part by exposing the Service on port `32379`, but AWS networking still had to permit external traffic to that port.

---

## First thing to check: Security Group

EKS worker nodes usually allow some standard inbound traffic such as:

* `22`
* `80`
* `443`

and certain internal communication ranges.

However, the NodePort assigned by Kubernetes — in this case `32379` — is **not automatically open to the internet**.

So the next step was to inspect the **EC2 worker node security group**.

It turned out that the relevant rules allowed access only from a specific security group and not from the internet on the NodePort being used.

---

<img width="1625" height="397" alt="image" src="https://github.com/user-attachments/assets/7092e11b-515f-460e-80b4-9c432909375b" />

---

## Fix

The NodePort assigned by Kubernetes was explicitly opened in the security group so that external traffic could reach the worker nodes on that port.

---

<img width="1642" height="356" alt="image" src="https://github.com/user-attachments/assets/8b060558-8618-4b24-8ece-23084b0beb70" />

---

## Result

After updating the security group, the application became reachable successfully through the NodePort.

---

<img width="1505" height="744" alt="image" src="https://github.com/user-attachments/assets/00132e4b-c54b-46aa-93df-08366fb37314" />

---

This was an important milestone because it proved that:

* the **Deployment** was working
* the **Pods** were healthy
* the **Service** was forwarding traffic correctly
* the application itself was functioning properly inside the cluster

At this point, the application was successfully accessible from outside the cluster, even though the access method was still a NodePort.

---

# Why NodePort Was Not the Final Solution

Although NodePort was useful for validating connectivity, it is not the preferred way to expose a web application in a production-style Kubernetes setup.

NodePort has a few limitations:

* the application must be accessed using a node IP and a high port
* security group rules must be opened manually for those ports
* it does not provide clean hostname-based routing
* it is not ideal when multiple applications need to be exposed

A more production-oriented approach is to expose the application through an **Ingress Controller** backed by a **Load Balancer**.

That is why the next step was to test the `ingress.yaml` file.

---

# Testing the Application Through Ingress

The ingress manifest was applied:

```bash
kubectl apply -f ingress.yaml
```

and the Ingress resource was created successfully.

However, when the Ingress was first checked, the `ADDRESS` field was blank:

```text
NAME         CLASS   HOSTS              ADDRESS   PORTS   AGE
go-web-app   nginx   go-web-app.local             80      30s
```

This was expected at that stage. The Ingress resource by itself does not create a load balancer. It needs an **Ingress Controller** that watches Ingress resources and provisions the required networking infrastructure.

---

# Installing the NGINX Ingress Controller

To make the Ingress functional, the **NGINX Ingress Controller** was installed using the provider-specific AWS deployment manifest.

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.15.1/deploy/static/provider/aws/deploy.yaml
```

After installation, the controller pod was running successfully in the `ingress-nginx` namespace.

---

## Why the Ingress Controller Matters

The Ingress Controller is the component that:

* watches for Kubernetes Ingress resources
* configures routing rules
* creates or integrates with a load balancer
* forwards external requests to the correct Service

Without the Ingress Controller, the Ingress manifest is only a declarative rule and does not actually expose the application.

---

# Ingress Address Populated with ELB DNS

Once the Ingress Controller was installed and had time to process the Ingress resource, the `ADDRESS` field was populated with the DNS name of the AWS load balancer:

```text
af1c475d2f805413b85b38159055f2bc-f193cd6541f83b02.elb.us-west-2.amazonaws.com
```

This meant the NGINX Ingress Controller had successfully provisioned the load balancer and attached it to the Ingress.

---

<img width="1605" height="693" alt="Screenshot 2026-06-23 005502" src="https://github.com/user-attachments/assets/ded515bb-8b11-4eab-9483-44365d0afb96" />

---

At this point, the infrastructure path looked like this:

```text
Browser / Client
        ↓
AWS Load Balancer
        ↓
NGINX Ingress Controller
        ↓
Kubernetes Service
        ↓
Go Application Pods
```

So in theory, the application should now have been reachable through the configured hostname.

---

# Ingress Hostname Problem: Still Not Reachable

Even though the Ingress was created successfully and the Load Balancer address was available, the application was still not accessible using the configured hostname.

For example:

```bash
curl go-web-app.local/courses
```

returned:

```text
curl: (6) Could not resolve host: go-web-app.local
```

---

# Why This Happened

The root cause was the `host` field inside the Ingress manifest:

```yaml
host: go-web-app.local
```

By explicitly defining this host, the Ingress was configured to expect requests for **exactly** `go-web-app.local`.

## That means it is not enough for the load balancer to exist. The hostname `go-web-app.local` must also resolve to the load balancer from the client side. In other words, the client machine must know where `go-web-app.local` points.

# Finding the Load Balancer IPs

To make the hostname work, the DNS name of the ELB was resolved using `nslookup`.

That returned multiple IP addresses for the load balancer.

Example:

* `100.23.52.116`
* `34.213.83.57`
* `52.42.84.42`

One of these IPs could then be mapped to the custom hostname for local testing.

---

# Mapping the Hostname in `/etc/hosts`

To test the Ingress host locally, an entry was added to `/etc/hosts`:

```text
52.42.84.42   go-web-app.local
```

This meant that whenever the local machine tried to access `go-web-app.local`, it would resolve that hostname to the selected ELB IP.

At this point, it looked like the problem should be solved.

---

# But the Browser Still Failed

Even after updating `/etc/hosts`, the application was still not accessible in the browser.

This was the most confusing part of the troubleshooting journey because:

* the Deployment was working
* the Service was working
* the Ingress existed
* the Load Balancer existed
* the hostname had been mapped

and yet the application still could not be reached.

---

<img width="720" height="637" alt="image" src="https://github.com/user-attachments/assets/06b70cc4-31d5-4446-94e0-e9440bd63db9" />

---

# Final Root Cause: WSL vs Windows Hostname Resolution

After deeper troubleshooting, the real problem turned out not to be Kubernetes at all.

The hostname mapping had been added inside the **WSL** environment, not in the Windows host system.

That means:

* `/etc/hosts` was updated in **WSL**
* but the browser was running on **Windows**
* Windows does **not** use the WSL `/etc/hosts` file

So from the browser’s point of view, `go-web-app.local` still did not exist.

This was a system-level hostname resolution issue, not a Kubernetes issue.

---

# How the Ingress Was Finally Verified

Since the hostname was correctly configured inside WSL, the application could be verified directly from the WSL terminal using:

```bash
curl go-web-app.local/courses
```

This returned the HTML response successfully, proving that the Ingress setup itself was working correctly and that the remaining problem was only the client-side host resolution in Windows.

---

# What This Kubernetes Phase Proved

By the end of this phase, several important things had been validated:

## Application Deployment

* the Go application was successfully deployed into Kubernetes
* the Deployment created healthy application pods
* the Service correctly forwarded traffic to the application

## NodePort Testing

* the application was reachable externally using a NodePort
* the issue was not with Kubernetes, but with AWS security group rules
* opening the NodePort in the worker node security group fixed the problem

## Ingress Testing

* the Ingress resource was created successfully
* the NGINX Ingress Controller created an AWS Load Balancer
* the application could be routed through the Ingress and load balancer
* the final accessibility issue was caused by hostname resolution outside Kubernetes

---

# Key Lessons from This Phase

This phase was one of the most important parts of the project because it highlighted that deployment issues are often not purely “Kubernetes problems”.

A few key takeaways:

### 1. A running Deployment does not automatically mean an externally reachable application

Pods can be healthy and Services can exist, while the application is still inaccessible due to networking or DNS issues.

### 2. NodePort exposure depends on cloud networking

Kubernetes can expose a port on the node, but the cloud provider’s security groups must also allow traffic to that port.

### 3. Ingress needs an Ingress Controller

Creating an Ingress resource alone is not enough. The controller is the component that actually turns those rules into real external routing.

### 4. Host-based routing introduces DNS/hostname dependencies

Once an Ingress host is explicitly defined, the client must resolve that hostname correctly. If the hostname is not mapped, the application will remain inaccessible even if the Kubernetes side is configured properly.

### 5. Troubleshooting Kubernetes often means troubleshooting the layers around Kubernetes

The real issues in this phase were not:

* the Go application
* the container image
* the Deployment spec

They were:

* AWS Security Group rules
* client-side hostname resolution
* WSL vs Windows environment differences

---

# Summary of the Kubernetes Journey

This phase started with a containerized Go application and ended with a fully functioning deployment on Amazon EKS, reachable both through:

* **NodePort**, after opening the required port in the worker node security group
* **Ingress + AWS Load Balancer**, after configuring the NGINX Ingress Controller and correctly resolving the custom hostname

This phase was where the project moved from “application packaged in Docker” to “application deployed in a production-style orchestration environment”.

---

# Next Step

Now that the application is successfully deployed and exposed on Kubernetes, the next step is to **package the Kubernetes manifests using Helm** so the deployment becomes more reusable, configurable, and CI/CD friendly.

➡️ Continue to: [**Helm Charting**](/helm/readme.md)
