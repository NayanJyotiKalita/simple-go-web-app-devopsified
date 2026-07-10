# Troubleshooting and Lessons Learned

Every real DevOps project has a phase where things do not work the first time.
This project was no different.

While implementing the complete workflow — from local testing to Docker, Kubernetes, Helm, GitHub Actions, and ArgoCD — I ran into several practical issues that required debugging step by step. In many cases, the root cause was not the application itself, but the way different layers interacted with each other: local routing, container runtime, Kubernetes networking, ingress resolution, Helm templating, and CI/CD automation.

This section captures the key issues faced during the project, how they were debugged, what the actual root cause was, and what I learned from each one.

---

## 1. Local Application Testing Did Not Work at the Expected Route

### Problem

Before containerizing the application, I first tried to run it locally to verify whether the application itself was working. Although the application started successfully, it was not accessible in the browser at the root route the way I initially expected.

At first glance, it looked like the application itself was broken.

### Root Cause

The issue was not with the Go application server, but with the expected route.

The application was designed to expose content under:

```bash
http://localhost:8080/courses
```

and not necessarily at the root `/`.

So trying to access the wrong route created the impression that the app was failing, while in reality the application was working correctly at the path it was coded to serve.

### Fix / Verification

The correct route was tested using:

```bash
curl http://localhost:8080/courses
```

and the browser was also pointed to:

```bash
http://localhost:8080/courses
```

After using the correct route, the application responded successfully.

### Lesson Learned

Always verify how the application is expected to behave before containerizing or deploying it.

Local testing is not just a formality — it is the first and most important debugging checkpoint. If the application does not work locally, moving it into Docker or Kubernetes only adds more layers of complexity on top of an unresolved problem.

---

## 2. Docker Image Build Issues Due to Base Image / Version Mismatch

### Problem

While containerizing the Go application, there was a possibility of the image build failing because of mismatches between the Go version used in the Dockerfile and the version declared in `go.mod`.

A related risk was using an incorrect image name in the Dockerfile, especially in the final distroless stage.

### Example of the Issue

A common version mismatch could look like this:

```dockerfile
FROM golang:1.25 AS base
```

while `go.mod` might contain:

```go
go 1.26
```

Another easy mistake is a typo in the final stage image:

```dockerfile
FROM grc.io/distroless/base
```

instead of:

```dockerfile
FROM gcr.io/distroless/base
```

### Root Cause

These failures are not application-level problems. They are environment and build configuration problems.

* Version mismatch can break dependency resolution or build behavior.
* Image name typos cause Docker build failures.
* Distroless images are minimal, so every file copied into the final image must be intentional and correct.

### Fix / Verification

The Dockerfile was aligned properly with the application’s Go version and corrected to use the right distroless image:

```dockerfile
FROM golang:1.26 AS base
...
FROM gcr.io/distroless/base
```

The image was then rebuilt and run locally to confirm it served the application correctly.

### Lesson Learned

Containerization is not only about “writing a Dockerfile.” It is also about making sure the build environment matches the application runtime expectations.

Small typos in image names or small version mismatches can consume a lot of debugging time.

---

## 3. Kubernetes Service Was Not Reachable Even After Switching to NodePort

### Problem

Initially, the Kubernetes Service was created as a `ClusterIP`, which is only accessible from inside the cluster. To test the application externally, the service type was changed to `NodePort`.

Even after changing the service to `NodePort`, the application still remained unreachable in the browser and kept timing out.

### What Made It Confusing

At first, everything looked correct:

* The service existed correctly
* The pods were running
* The nodes had public IPs
* The NodePort was visible

So it seemed like the application should already be externally accessible.

### Root Cause

The problem was not with the application pod or the service definition itself.
The actual issue was around how traffic reaches the node.

A `NodePort` service only works externally if:

* the node is reachable from outside
* the correct NodePort is open
* the relevant EC2 security group allows inbound traffic on that NodePort range or the specific port
* the request is sent to the node public IP + NodePort

In practice, `NodePort` is often inconvenient for production-style access because it exposes the application through a high port and requires the underlying node/network rules to allow that traffic.

### Lesson Learned

Changing a service to `NodePort` does not automatically guarantee browser access.

Kubernetes service exposure must always be thought of together with the underlying infrastructure layer:

* VPC networking
* EC2 security groups
* public/private subnet placement
* which port the service actually exposes

This was a strong reminder that Kubernetes networking does not operate in isolation from the cloud networking layer underneath it.

---

## 4. Ingress Was Created Successfully but Hostname Was Still Not Working

### Problem

After moving away from direct `NodePort` access, an NGINX Ingress Controller was installed and an Ingress resource was created for the application.

The Ingress successfully received an AWS load balancer DNS name, which suggested that the setup was mostly correct. However, the custom hostname:

```bash
go-web-app.local
```

still did not work in the browser.

### What Was Verified

The following were confirmed:

* ingress class was `nginx`
* service backend was correct
* load balancer DNS name had been assigned
* ingress controller pod was running

DNS resolution for the load balancer itself also worked.

### Root Cause

The main issue was hostname resolution on the local machine, not the Kubernetes ingress resource.

The hostname `go-web-app.local` is not a publicly resolvable domain. It is only a custom local hostname used for testing.

That means the local machine has no way to know that:

```bash
go-web-app.local
```

should point to the AWS load balancer unless that mapping is explicitly configured.

### Fix

The hostname had to be mapped manually in `/etc/hosts`:

```bash
52.42.84.42 go-web-app.local
```

or to one of the IPs behind the load balancer that was being used for testing.

This allowed the local machine to resolve `go-web-app.local` to the ingress load balancer.

### Lesson Learned

An Ingress resource can be perfectly correct and still be inaccessible if the client-side hostname cannot resolve.

Kubernetes Ingress solves routing inside the cluster, but DNS resolution is a separate problem.

For local testing with fake hostnames, `/etc/hosts` mapping is still required unless a proper DNS record exists.

---

## 5. The Ingress Host Was Resolving but the Application Still Returned 404

### Problem

Even after the ingress controller was installed and the load balancer was provisioned, testing the ingress endpoint with:

```bash
curl -H "Host: go-web-app.local" http://<elb-dns>/path
```

returned:

```text
404 page not found
```

This made it look like the ingress rule was broken.

### Root Cause

The important detail here was that the `404` was coming from the backend application, not necessarily from a missing ingress configuration.

The application itself serves content under a particular route structure such as:

```bash
/courses
```

So when the ingress was configured with a path that did not match the application’s actual route expectations, the request could successfully reach the service and still return a `404` from the application.

This is a very important distinction:

* **Ingress 404 / default backend issue** → request is not routed correctly
* **Application 404** → request reached the app, but the app does not have content at that path

### Lesson Learned

When debugging ingress, do not stop at “I got a 404.”

The next question should always be:

> **Who returned the 404?**

* the ingress controller?
* the default backend?
* or the application itself?

That distinction changes the entire debugging direction.

---

## 6. Service Type Confusion During Ingress Troubleshooting

### Problem

At one point, there was confusion because the service had earlier been changed to `NodePort`, but later the YAML output showed:

```yaml
type: ClusterIP
```

This created uncertainty around whether the service type was causing the ingress issue.

### Root Cause

For an Ingress-based setup, the backend application service does **not** need to be `NodePort`.

It can remain `ClusterIP`, because the ingress controller routes traffic internally to the service.

The ingress controller service is the one that typically needs to be exposed externally (for example through a `LoadBalancer`), not necessarily the application service itself.

So the application service being `ClusterIP` was not the problem.

### Lesson Learned

When using an Ingress:

* the application service can remain `ClusterIP`
* the ingress controller is the component that receives external traffic and forwards it internally

This clarified the networking model:

```text
Internet → LoadBalancer / Ingress Controller → ClusterIP Service → Pod
```

and helped separate the concerns of application exposure vs ingress exposure.

---

## 7. Port Forwarding Worked, but Hostname Access Still Failed

### Problem

When the service was port-forwarded locally, the application worked successfully. For example, forwarding the service to a local port like `9090` allowed the application to be accessed correctly.

However, the custom hostname through ingress was still not working at the same time.

### Root Cause

Port forwarding and ingress-based hostname access solve two completely different access paths.

**Port forwarding path**

```text
Local machine → kubectl port-forward → service/pod
```

**Ingress path**

```text
Browser → hostname resolution → AWS LoadBalancer → ingress controller → service → pod
```

So the fact that port forwarding worked only proved that:

* the application pod was healthy
* the service was correctly routing to the pod

It did **not** prove that the ingress path was correct.

### Lesson Learned

Port forwarding is a great diagnostic tool because it isolates the application and service from the ingress and cloud networking layers.

If port-forward works but ingress does not, the problem is usually not the app itself. It is more likely in one of these areas:

* ingress rule / host / path configuration
* hostname resolution
* load balancer access
* cloud security group rules
* client-side DNS mapping

---

## 8. Local Port 8080 Was Already Occupied

### Problem

While trying to port-forward the Kubernetes service to local port `8080`, the command failed with:

```text
unable to listen on port 8080
bind: address already in use
```

### Root Cause

Another process on the local machine was already using port `8080`. That process turned out to be Jenkins:

```bash
java ... LISTEN *:8080
```

So the issue was not with Kubernetes or port-forwarding itself. It was a local machine port conflict.

### Fix

The conflicting process was identified using:

```bash
sudo lsof -i :8080
```

and then Jenkins was stopped:

```bash
sudo systemctl stop jenkins
```

After that, port `8080` became available for port-forwarding.

### Lesson Learned

Not every port-related issue is a Kubernetes issue. Sometimes the problem is simply that the local machine is already using the same port.

Whenever `kubectl port-forward` fails to bind to a port, one of the first checks should be:

```bash
sudo lsof -i :<port>
```

---

## 9. Understanding Why `go-web-app.local` Still Needed `/etc/hosts`

### Problem

Even after the application was fully deployed via ArgoCD and accessible through ingress, the hostname:

```bash
go-web-app.local
```

still required manual mapping in `/etc/hosts`.

At first this felt strange because the application had already been “properly deployed” into Kubernetes.

### Root Cause

Kubernetes deployment and DNS resolution are two separate concerns.

ArgoCD deploying the application correctly does not automatically teach the local operating system how to resolve a custom hostname like `go-web-app.local`.

Since `.local` was just a test hostname, the machine still needed a manual mapping such as:

```bash
<load-balancer-ip> go-web-app.local
```

### Lesson Learned

A successful Kubernetes deployment does not eliminate the need for DNS.

In local testing:

* **Ingress** handles routing inside the cluster
* **`/etc/hosts`** handles local name resolution on the client side

In production, this would be replaced with a real domain and proper DNS records.

---

## 10. Helm Helped Remove Repetition, but Templating Needs Discipline

### Problem

After moving from raw Kubernetes manifests to Helm, the deployment became easier to manage across environments, but Helm also introduced the possibility of template mistakes.

A wrong value reference, indentation issue, or hardcoded image value can break deployment behavior even if the Kubernetes YAML itself looks valid.

### Example

The image tag was templated like this in `deployment.yaml`:

```yaml
image: nayanjk/go-web-app:{{ .Values.image.tag }}
```

and then controlled through `values.yaml`.

This is powerful, but it also means the chart becomes dependent on:

* correct value names
* correct YAML structure
* correct update logic from CI/CD

### Lesson Learned

Helm reduces duplication and makes deployments environment-friendly, but it also adds a templating layer that must be treated carefully.

A Helm chart should always be validated mentally as:

```text
Kubernetes YAML + variable substitution + environment-driven configuration
```

which means debugging can happen at either the template layer or the final rendered manifest layer.

---

## 11. GitHub Actions Workflow Did Not Work Perfectly on the First Attempt

### Problem

While setting up CI, the GitHub Actions workflow did not succeed on the first run. There were a few workflow-level errors and version-related fixes needed before the pipeline completed successfully.

### Root Cause

This came from a combination of small issues such as:

* action version corrections
* workflow syntax adjustments
* understanding how Go test execution should be written inside CI
* ensuring the correct checkout and Docker build steps were being used

Another key learning was the importance of using:

```bash
go test ./...
```

instead of running tests only in the current directory.

### Lesson Learned

CI failures are often not application failures — they are pipeline wiring failures.

When writing GitHub Actions workflows, each stage should be debugged independently:

* checkout
* Go setup
* test execution
* Docker login
* Docker build/push
* Helm file update
* Git commit/push back to repo

Treating the workflow as a chain of smaller steps makes debugging much easier.

---

## 12. CI/CD Is Not Proven Until a Real Change Flows End to End

### Problem

It is easy to assume the pipeline works just because:

* the workflow ran once
* Docker image was pushed once
* ArgoCD application was created once

But that still does not prove that a real application change can travel all the way through the system automatically.

### Validation That Solved This

To verify the pipeline properly, a small change was made in:

```bash
static/courses.html
```

The change was committed and pushed, which triggered:

* GitHub Actions CI
* new Docker image build and push
* automatic Helm `values.yaml` update with the new tag
* ArgoCD sync
* Kubernetes deployment update

That proved the complete CI/CD path end to end.

### Lesson Learned

A CI/CD pipeline is only truly validated when a real code change flows through:

```text
Git push → CI build → image push → Helm update → ArgoCD sync → Kubernetes deployment
```

Without that test, the pipeline is only partially verified.

---

## 13. Cloud-Native Debugging Means Identifying Which Layer Is Failing

One of the biggest takeaways from the entire project was that cloud-native debugging is rarely about just “the app is not working.”

Most failures happen at one of several different layers:

### Application Layer

* wrong route
* missing file
* application-level `404`
* incorrect port inside the app

### Container Layer

* build failure
* wrong base image
* missing static files in the image
* incorrect `CMD` / `ENTRYPOINT`

### Kubernetes Layer

* wrong selector
* service not mapping to pods
* pod not healthy
* wrong `targetPort` / service port

### Ingress / Networking Layer

* ingress controller missing
* wrong host or path rule
* DNS not resolving
* load balancer not reachable
* security group restrictions

### CI/CD Layer

* workflow syntax errors
* secrets missing
* image not pushed
* Helm values not updated
* ArgoCD not syncing expected changes

---

# Final Lessons Learned

This project reinforced several practical DevOps lessons for me:

## 1. Always test the application locally first

If the app itself is not behaving correctly, moving to Docker or Kubernetes only makes debugging harder.

## 2. Kubernetes exposure should be understood layer by layer

Pod, Service, NodePort, Ingress, LoadBalancer, DNS, and security groups are all separate pieces of the traffic path.

## 3. Port-forwarding is one of the best debugging tools

If port-forward works, the pod and service are usually fine. The problem is then likely in ingress, DNS, or external access.

## 4. Ingress and DNS are not the same thing

Ingress controls traffic routing inside Kubernetes. DNS controls how the client finds the ingress endpoint.

## 5. Helm simplifies deployments, but adds a templating layer

This makes deployments more reusable, but it also adds a new place where configuration mistakes can happen.

## 6. CI/CD should be tested using a real application change

A successful pipeline setup is good, but an end-to-end deployment triggered by a real code change is the real proof.

## 7. DevOps debugging is about isolating layers

The fastest way to debug is to ask:

* Is the application broken?
* Is the container broken?
* Is the service broken?
* Is ingress broken?
* Is DNS broken?
* Is the CI/CD pipeline broken?

The moment the failing layer is identified, the problem becomes much easier to solve.

---

# Closing Note

This troubleshooting phase was one of the most valuable parts of the project because it turned the implementation from a “follow the steps” exercise into a real debugging and systems-understanding experience.

The project was not just about deploying a Go application on EKS.
It was about understanding how all the pieces fit together:

* local application behavior
* Docker packaging
* Kubernetes networking
* ingress-based exposure
* Helm-based configuration
* GitHub Actions automation
* ArgoCD-driven GitOps delivery

Solving these issues one by one gave a much clearer picture of how modern cloud-native application delivery actually works in practice.
