# Helm

After deploying the application successfully on Kubernetes using raw manifest files, the next step was to make that deployment **reusable, configurable, and environment-friendly**.

That is where **Helm** comes in.

Helm helps package Kubernetes resources into a chart so that the same application can be deployed across multiple environments — such as **dev**, **stage**, and **prod** — without having to maintain separate copies of the same YAML files.

Instead of hardcoding values directly into the Kubernetes manifests, Helm allows those values to be **parameterized** through a `values.yaml` file. This makes deployments easier to manage and becomes especially useful later in the project when CI/CD updates the image tag automatically.

---

# Why Helm Was Introduced

Up to this point in the project, the application had already been deployed successfully using Kubernetes manifests such as:

* `deployment.yaml`
* `service.yaml`
* `ingress.yaml`

That approach works, but it becomes difficult to maintain when the same application needs to be deployed into multiple environments.

For example, different environments may need different values for:

* image tag
* replica count
* ingress hostnames
* resource limits
* environment-specific settings

Without Helm, one common approach would be to create separate folders such as:

```text id="9p8c7d"
dev/
stage/
prod/
```

and keep slightly different versions of the same manifests in each folder.

That quickly becomes repetitive and hard to maintain.

Helm solves this problem by allowing us to keep a **single set of templates** and inject environment-specific values through a `values.yaml` file.

For example, instead of hardcoding:

```yaml id="e0r8mr"
image: nayanjk/go-web-app:dev
```

for one environment and:

```yaml id="0bjlwm"
image: nayanjk/go-web-app:stage
```

for another, we can parameterize the image tag and let Helm decide which value to use at deployment time.

This makes the deployment cleaner, more maintainable, and much better suited for automation.

---

# What Helm Helps Us Achieve

In this project, Helm was introduced mainly for the following reasons:

## 1. Reuse the same Kubernetes manifests across environments

The same deployment logic can now be reused without duplicating YAML files.

## 2. Replace hardcoded values with variables

Things like image tags, replica counts, and ingress settings can be parameterized.

## 3. Make the deployment CI/CD friendly

Later in the project, the CI pipeline updates the image tag in `values.yaml`, and ArgoCD deploys the new version automatically.

## 4. Simplify upgrades and cleanup

Helm provides a clean way to install, upgrade, and uninstall application resources as a single release.

---

# Installing Helm

Helm was installed on the local system before creating the chart.

## For Debian / Ubuntu

```bash id="zk4x9l"
HELM_BUILDKITE_APT_KEY_ID="DDF78C3E6EBB2D2CC223C95C62BA89D07698DBC6"

sudo apt-get install curl gpg apt-transport-https --yes

curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey > "${TMPDIR:-/tmp}/helm.gpg"

# Ensure that the key ID matches to prevent a repository compromise from establishing an attacker controlled key
if [ "$(gpg --show-keys --with-colons "${TMPDIR:-/tmp}/helm.gpg" | awk -F: '$1 == "fpr" {print $10}' | head -n 1)" != "${HELM_BUILDKITE_APT_KEY_ID}" ]; then echo "ERROR: Unexpected Helm APT key ID: potential key compromise"; exit 1; fi

cat "${TMPDIR:-/tmp}/helm.gpg" | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

sudo apt-get update
sudo apt-get install helm
```

For other operating systems, Helm installation instructions can be found on the official Helm documentation site.

---

# Verify Helm Installation

After installation, Helm was verified using:

```bash id="35lu8n"
helm version
```

Output:

```bash id="pksiyt"
version.BuildInfo{Version:"v3.18.4", GitCommit:"d80839cf37d860c8aa9a0503fe463278f26cd5e2", GitTreeState:"clean", GoVersion:"go1.24.4"}
```

This confirmed that Helm was installed successfully and ready to use.

---

# Creating the Helm Chart

Helm provides a command to bootstrap a chart structure.

Inside the `helm/` directory, the chart was initialized using:

```bash id="6iuhal"
helm create go-web-app-chart
```

This generated a standard Helm chart scaffold.

---

## Chart Creation

```bash id="gf08au"
chucky@Dell:~/simple-go-web-app-devopsified/helm$ helm create go-web-app-chart
Creating go-web-app-chart
```

As soon as the chart was created, Helm generated multiple files and directories inside it.

---

<img width="306" height="534" alt="image" src="https://github.com/user-attachments/assets/47a8f833-565b-4668-988c-ef3a65fa79f2" />

---

The generated structure contains default chart files, example templates, and helper files. However, in this project, the goal was not to use Helm’s default example templates. The goal was to **convert the Kubernetes manifests that were already working into Helm templates**.

So the next step was to clean up the generated content and replace it with our own manifests.

---

# Cleaning the Default Helm Chart Structure

The default chart includes a `charts/` directory and a number of generated templates that were not needed for this project.

## Remove the `charts/` directory

```bash id="7z9zh5"
rm -rf charts/
```

## Remove the default templates

```bash id="o5o0tq"
cd templates/
rm -rf *
```

At this point, the chart’s template directory was empty and ready to receive the Kubernetes manifests that had already been created and tested earlier.

---

# Reusing the Existing Kubernetes Manifests

Instead of rewriting everything from scratch, the existing Kubernetes manifests from the `k8s/manifests/` directory were copied into the Helm chart’s `templates/` directory.

```bash id="an4vxj"
cp ../../../k8s/manifests/* .
```

After copying, the chart’s template directory contained:

```bash id="6f11pc"
deployment.yaml
ingress.yaml
service.yaml
```

This was a very practical step because the manifests had already been tested directly on Kubernetes in the previous phase. Helm was not replacing the deployment logic — it was simply turning that logic into a reusable chart.

---

# Converting Hardcoded Values into Helm Variables

The next step was to **parameterize the hardcoded values** inside the Kubernetes manifests.

This is the most important part of using Helm.

The goal is to replace fixed values with placeholders that pull data from `values.yaml`.

---

# Example: Parameterizing the Image Tag

Inside `templates/deployment.yaml`, the container image was updated from a hardcoded value to a Helm template expression.

Example:

```yaml id="j3h2kn"
spec:
  containers:
    - image: nayanjk/go-web-app:{{ .Values.image.tag }}
      name: nginx
      ports:
        - containerPort: 8080
```

This means that the image tag is no longer fixed directly in the manifest. Instead, Helm will look inside `values.yaml` and substitute the value of:

```yaml id="jlc4go"
.Values.image.tag
```

during chart rendering.

---

# Why This Matters

This single change is what makes the deployment reusable across environments.

For example:

* in **dev**, the image tag might be `dev`
* in **stage**, the image tag might be `stage`
* in **prod**, the image tag might be `prod`
* during CI/CD, the image tag might be a build-specific tag such as a pipeline run ID

Without Helm, each of these would require separate manifest files or manual editing. With Helm, the template remains the same and only the values change.

---

# Defining the Values in `values.yaml`

Once the manifests were parameterized, the next step was to define the actual values in `values.yaml`.

The default content of `values.yaml` generated by Helm was removed and replaced with values specific to this project.

```yaml id="b8wbcu"
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

# Understanding `values.yaml`

This file becomes the central place where configurable deployment values are stored.

## `replicaCount`

Controls how many pod replicas the Deployment should create.

## `image.repository`

Defines the Docker image repository.

## `image.pullPolicy`

Specifies how Kubernetes should pull the image.

## `image.tag`

Defines which image tag should be deployed.

## `ingress.*`

Contains ingress-related values such as hostnames, paths, annotations, and ingress behavior.

---

# Why the Image Tag Matters So Much

At this point in the project, the image tag was set to:

```yaml id="qucimc"
tag: "v1"
```

because the image that had already been built and pushed earlier used the `v1` tag.

However, this field becomes much more important later in the CI/CD phase.

A value such as:

```yaml id="31fyvn"
tag: "10016307834"
```

is not just a random number. It can represent a build-specific tag generated by the CI pipeline.

The idea is:

1. CI builds a new Docker image
2. CI tags that image uniquely
3. CI updates `values.yaml` with the latest tag
4. ArgoCD detects the change in Git
5. ArgoCD deploys the new image into Kubernetes

So the parameterization done here is what later enables the **GitOps-style deployment flow**.

---

# Verifying Helm by Replacing the Manually Created Resources

Once the Helm chart was prepared, the next step was to verify that it actually worked.

To do that properly, the Kubernetes resources that had been created manually in the earlier phase were deleted, and then the same application was redeployed using Helm.

This was an important test because it proved that the Helm chart could independently reproduce the same deployment without relying on the raw `kubectl apply` flow.

---

# Existing Kubernetes Resources Before Helm Deployment

Before testing Helm, the cluster already had the manually created Deployment, Service, and related resources.

Example:

```bash id="lrcs1r"
kubectl get all
```

showed:

* application pod
* NodePort service
* Deployment
* ReplicaSet

This confirmed that the application was already running through the raw Kubernetes manifests.

---

# Delete the Existing Resources

To avoid conflicts and to test Helm cleanly, the manually created resources were deleted.

```bash id="hprqsl"
kubectl delete deploy go-web-app
kubectl delete svc go-web-app
kubectl delete ingress go-web-app
```

After cleanup, only the default Kubernetes service remained in the cluster.

This left the environment clean for a fresh Helm-based deployment.

---

# Deploy the Application Using Helm

With the chart ready and the old resources removed, the application was deployed using Helm.

Helm installation creates a **release**, which is Helm’s way of tracking a deployed application instance.

In this project, the release was installed using a command similar to:

```bash id="4e6h7c"
helm install go-web-app ./go-web-app-chart
```

This told Helm to:

* read the chart templates
* substitute values from `values.yaml`
* render the Kubernetes manifests
* create the resources in the cluster as a Helm-managed release

---

## Helm Deployment

---

<img width="845" height="486" alt="image" src="https://github.com/user-attachments/assets/dc45ce9c-209f-4554-8846-882700176914" />

---

This successfully recreated the application resources through Helm rather than through manual `kubectl apply`.

---

# Verifying That Helm Rendered the Correct Image Tag

One of the most important checks after Helm deployment was to verify that the Deployment was actually using the image tag defined in `values.yaml`.

Inside the Helm-templated `deployment.yaml`, the image field had been written as:

```yaml id="mknkw4"
image: nayanjk/go-web-app:{{ .Values.image.tag }}
```

Since `values.yaml` contained:

```yaml id="mgsl4d"
tag: "v1"
```

the deployed Kubernetes Deployment should resolve the final image as:

```yaml id="z2b1yk"
image: nayanjk/go-web-app:v1
```

That is exactly what was observed in the deployed resources.

---

<img width="549" height="257" alt="image" src="https://github.com/user-attachments/assets/34cbf738-59f9-4ded-934a-53b4ce23a6dd" />

---

This was a key validation step because it proved that Helm was correctly substituting the variable values into the templates.

---

# Cleanup of Resources Using Helm

One of the operational advantages of Helm is that it makes cleanup much simpler.

Instead of deleting the Deployment, Service, and Ingress one by one, Helm can remove the entire application release in one command.

```bash id="9v2d2m"
helm uninstall go-web-app
```

Output:

```bash id="ekz54j"
release "go-web-app" uninstalled
```

After uninstalling the release, the Helm-managed resources were removed from the cluster, leaving only the default Kubernetes service.

This is one of the reasons Helm is so convenient operationally: installation, upgrades, rollbacks, and cleanup are all handled at the release level rather than resource by resource.

---

# What This Helm Phase Achieved

By the end of this phase, the Kubernetes deployment had been successfully transformed from a set of raw manifests into a reusable Helm chart.

More specifically, this phase achieved the following:

## 1. Reused the already working Kubernetes manifests

The Deployment, Service, and Ingress manifests that had already been validated were reused as the base for the chart.

## 2. Introduced parameterization

Hardcoded values such as the image tag were replaced with Helm variables.

## 3. Centralized environment-specific configuration

Configurable values were moved into `values.yaml`.

## 4. Proved that Helm could recreate the deployment

The manually created Kubernetes resources were deleted, and the application was redeployed successfully through Helm.

## 5. Prepared the project for CI/CD and GitOps

Because the image tag is now parameterized, a CI pipeline can update `values.yaml`, and ArgoCD can deploy the new image automatically.

---

# Why This Step Matters for the Rest of the Project

Helm is the bridge between **manually managed Kubernetes manifests** and **automated, environment-aware deployment pipelines**.

Without Helm, later CI/CD automation would be much more awkward because the pipeline would have to edit raw YAML manifests directly in multiple places.

With Helm in place:

* the CI pipeline only needs to update the image tag in `values.yaml`
* ArgoCD can watch the chart and sync the updated deployment
* the same chart can be reused across multiple environments
* the deployment becomes easier to upgrade, manage, and uninstall

In other words, Helm is what turns the Kubernetes deployment from a working setup into a **maintainable deployment system**.

---

# Key Takeaways from This Phase

### 1. Helm does not replace Kubernetes — it packages Kubernetes

The underlying resources are still Deployments, Services, and Ingresses. Helm simply makes them easier to manage.

### 2. Parameterization is the real power of Helm

The biggest benefit is not “Helm install” itself — it is the ability to remove hardcoded values and make the deployment configurable.

### 3. Reusing already working manifests is a practical strategy

There is no need to rewrite everything from scratch. Existing Kubernetes manifests can be copied into Helm templates and then gradually parameterized.

### 4. Helm makes CI/CD integration much cleaner

By parameterizing the image tag, the deployment becomes ready for automated image promotion in the next phase.

### 5. Helm releases simplify lifecycle management

Install, upgrade, and uninstall operations become much easier compared to managing resources one by one.

---

# Summary of the Helm Journey

This phase took the Kubernetes deployment that had already been validated in the previous step and converted it into a **Helm chart**.

That involved:

* creating a chart scaffold
* replacing the default templates with the project’s own Kubernetes manifests
* parameterizing hardcoded values
* defining those values in `values.yaml`
* deploying the application using Helm
* verifying that Helm rendered the correct values
* cleaning up the release using Helm uninstall

At the end of this phase, the project was no longer just “an application deployed on Kubernetes.” It had become **a configurable, reusable Helm-based deployment**, ready to be integrated into CI/CD and GitOps workflows.

---

# Next Step

Now that the Kubernetes deployment is packaged as a Helm chart, the next step is to automate the image build, push, and deployment update flow using **CI/CD**.

➡️ Continue to: [**GitHub Actions CI + ArgoCD GitOps**](/gitops/readme.md)
