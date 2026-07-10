# Containerization

After verifying that the application works correctly in the local system, the next step is to **containerize it using Docker**.

Containerization helps package the application along with everything it needs to run, so that the same application can behave consistently across environments — whether it is executed on a local machine, inside Kubernetes, or as part of a CI/CD pipeline.

This step is important because once the application is converted into a Docker image, Kubernetes can deploy that image as a portable, reproducible unit.

---

# Why Containerization is Needed

Running an application locally is useful for validation, but local execution alone is not enough for deployment. Different environments may have different operating systems, package versions, or runtime configurations.

Containerization solves that problem by bundling the application together with its runtime dependencies into a single image.

This gives us a few major advantages:

* the application becomes portable across environments
* developers and deployment platforms run the same packaged artifact
* we avoid “it works on my machine” type issues
* Kubernetes can directly deploy the image
* the image can be versioned, stored, and reused across CI/CD pipelines

In short, **containerization converts the locally tested application into a deployable artifact**.

---

# Writing the Dockerfile

To containerize the Go web application, we created the following Dockerfile:

```Dockerfile
FROM golang:1.26 AS base

WORKDIR /app

COPY go.mod .

# Installing dependencies
RUN go mod download  

# Copying the entire source code to the docker image
COPY . .

RUN go build -o main .
# The above command creates a binary called main


# Final stage - Distroless image
FROM gcr.io/distroless/base

# Copying the binary from the build stage
COPY --from=base /app/main .

# Copying static files required by the application
COPY --from=base /app/static ./static

# Exposing the port on which the application runs
EXPOSE 8080

# Command to run the application
CMD ["./main"]
```

---

# Understanding the Dockerfile

This Dockerfile uses a **multi-stage build**, which is a common best practice when building production-ready container images.

---

## Stage 1: Build Stage

```Dockerfile
FROM golang:1.26 AS base
```

The first stage uses the official Go image as the build environment. This stage is responsible for compiling the application.

### What happens here?

#### 1. Set the working directory

```Dockerfile
WORKDIR /app
```

All commands in this stage will run from `/app`.

#### 2. Copy the `go.mod` file

```Dockerfile
COPY go.mod .
```

This allows Docker to understand the application’s dependencies.

#### 3. Download dependencies

```Dockerfile
RUN go mod download
```

This is similar in spirit to something like:

```bash
pip install -r requirements.txt
```

in Python projects. It ensures that the Go dependencies are available before building the application.

#### 4. Copy the entire source code

```Dockerfile
COPY . .
```

This brings the rest of the application code into the image.

#### 5. Build the Go binary

```Dockerfile
RUN go build -o main .
```

This compiles the application and creates a binary called `main`.

At the end of the build stage, we now have a ready-to-run application binary inside the image.

---

## Stage 2: Runtime Stage

```Dockerfile
FROM gcr.io/distroless/base
```

The second stage is the **final runtime image**. Instead of shipping the full Go build environment, we use a much smaller **distroless image**.

### Why use a distroless image?

A distroless image is useful because it:

* is smaller than a full OS image
* contains fewer unnecessary packages
* reduces the attack surface
* is better suited for production workloads

The idea is simple: once the binary is built, we only need the binary and the files required by the application at runtime.

---

## Copy the binary from the build stage

```Dockerfile
COPY --from=base /app/main .
```

This copies the compiled Go binary from the first stage into the final image.

---

## Copy static assets

```Dockerfile
COPY --from=base /app/static ./static
```

This part is very important.

The application is not just a compiled Go binary — it also depends on static HTML/CSS assets stored inside the `static/` directory. Those files are **not bundled into the Go binary**, so they must be copied into the final image separately.

Without this step, the container might start successfully but fail to serve the frontend pages because the required files would be missing.

---

## Expose the application port

```Dockerfile
EXPOSE 8080
```

This documents that the application listens on port `8080`.

---

## Start the application

```Dockerfile
CMD ["./main"]
```

This tells Docker to execute the compiled Go binary when the container starts.

---

# Why a Multi-Stage Build is Better Here

This Dockerfile is intentionally written as a **multi-stage build** instead of using a single large image.

If we had used only the Go image and shipped it directly, the final image would contain:

* Go compiler
* build tools
* unnecessary packages
* extra layers not required at runtime

With the multi-stage approach:

* the first stage is only for **building**
* the second stage is only for **running**
* the final image is cleaner and lighter
* the runtime image contains only what the application actually needs

This is a very common production-grade pattern for Go applications.

---

# Building the Docker Image

Once the Dockerfile was written, the next step was to build the image.

---

<img width="1776" height="485" alt="Screenshot 2026-06-17 190021" src="https://github.com/user-attachments/assets/6bf3ff47-0e9a-414f-af79-f1973cfc5e0c" />

---

At this stage, Docker packages the application source code, compiles it into a binary, copies the static files, and creates the final runtime image.

---

# Testing the Docker Image Locally

After the image is built, it is very important to test it locally before pushing it to a registry or deploying it into Kubernetes.

This step confirms that:

* the image builds successfully
* the container starts correctly
* the application is reachable from the expected port
* the static files are present in the image
* the `/courses` route still works exactly like it did during local testing

---

<img width="937" height="910" alt="image" src="https://github.com/user-attachments/assets/13cbfdb2-75d6-4073-b280-01cc8d8f0524" />

---

<img width="1538" height="773" alt="Screenshot 2026-06-17 180709" src="https://github.com/user-attachments/assets/6e2676b0-95bf-4ec9-b99c-9d638fbe7c25" />

---

This validation step is crucial because it proves that the application still works **inside the container**, not just on the local machine.

If the container runs successfully and the application is accessible at the expected route, then we know the Docker image is healthy and can be used in later stages such as Kubernetes and CI/CD.

---

# Pushing the Image to Docker Hub

Once the image was tested locally and confirmed to work, the next step was to push it to **Docker Hub**.

---

## Why push the image to an image registry?

Kubernetes typically expects container images to be pulled from an image registry.

Although it is technically possible to use a locally built image in some environments, the standard and recommended approach is to push the image to a central registry.

This is important because:

* Kubernetes worker nodes need a place from which they can pull the image
* CI/CD pipelines need a consistent source for application images
* versioned images can be reused across environments
* it becomes easier to roll back or track deployments

In this project, Docker Hub was used as the image registry.

---

<img width="872" height="471" alt="image" src="https://github.com/user-attachments/assets/33256895-339e-443b-8bed-37e6fe60e8a9" />

---

<img width="990" height="307" alt="image" src="https://github.com/user-attachments/assets/ecf72b37-4b89-4fa0-b1d6-24b2787a6782" />

---

At the end of this step, the application image is now stored in Docker Hub and is ready to be referenced by Kubernetes manifests and later by the CI/CD pipeline.

---

# Common Pitfalls During Containerization

This step looks straightforward, but a few small issues can easily break the image build or runtime behavior.

---

## 1. Go version mismatch

The Go version used in the Dockerfile should align with the version expected by the application.

For example:

* Dockerfile:

  ```Dockerfile
  FROM golang:1.25 AS base
  ```

* `go.mod`:

  ```go
  go 1.26
  ```

This mismatch can lead to unexpected build failures or compatibility issues.

So it’s a good practice to ensure the Go version in the Dockerfile matches the version declared in `go.mod`.

---

## 2. Typo in the base image name

Small typos in image names can be surprisingly frustrating to debug.

For example:

```Dockerfile
FROM grc.io/distroless/base
```

instead of:

```Dockerfile
FROM gcr.io/distroless/base
```

This would cause the build to fail because Docker would not be able to pull the image.

---

## 3. Forgetting to copy static files

The Go binary alone is not enough for this application. The `static/` directory is also required.

If the static files are not copied into the final image:

```Dockerfile
COPY --from=base /app/static ./static
```

the container may start, but the web pages may fail to load correctly.

---

## 4. Assuming a successful build means a successful runtime

A Docker image can build successfully and still fail when you run it.

For example:

* the application might not start
* the expected route may not work
* the static assets may not be present
* the wrong port may be exposed

That is why **building the image is not enough** — it must also be tested by actually running the container locally.

---

<img width="1207" height="421" alt="Screenshot 2026-06-17 185852" src="https://github.com/user-attachments/assets/a922c4c6-6638-4cbd-8405-a41441acdc22" />

---

# What We Achieved in This Step

By the end of the containerization phase, we had successfully:

* created a Dockerfile for the Go application
* used a multi-stage build to keep the final image clean and lightweight
* compiled the application into a binary
* copied the required static files into the final image
* tested the image locally to ensure the application still worked
* pushed the image to Docker Hub so Kubernetes can later pull it

At this point, the application is no longer just “working locally” — it has become a **portable deployable artifact**.

---

# Key Takeaway

Containerization is the bridge between **local development** and **platform deployment**.

In the previous phase, we confirmed that the application works on the local machine. In this phase, we packaged that working application into a Docker image that can now be:

* pulled by Kubernetes
* reused by CI/CD pipelines
* versioned and stored in Docker Hub
* deployed consistently across environments

This makes the Docker image the foundation for the next stages of the project.

---

# Next Step

Now that the application has been successfully containerized and pushed to a registry, the next step is to **deploy it on Kubernetes** using Deployment and Service manifests.

➡️ Continue to: [**Kubernetes Deployment**](/03-k8s/manifests/readme.md)
