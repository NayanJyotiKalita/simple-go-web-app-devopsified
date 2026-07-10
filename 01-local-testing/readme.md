# Local Testing

Before moving into **containerization, Kubernetes, Helm, or CI/CD**, the very first thing to do is verify whether the application works correctly on the **local machine**.

This is one of the most important steps in any deployment workflow because if the application itself is not running correctly locally, then debugging it later inside Docker, Kubernetes, or a CI/CD pipeline becomes much harder. Local testing helps isolate application-level issues early before we introduce infrastructure complexity.

---

# Why Local Testing is Important

When starting a DevOps project, it is tempting to jump straight into Docker or Kubernetes, but that often leads to unnecessary confusion.

Testing the application locally first helps confirm:

* the application actually starts successfully
* the correct port is being used
* the correct route/path is being served
* required files and dependencies are present
* any errors are application-level and not infrastructure-related

In short, **local testing gives us a known working baseline**. Once the application works locally, we can confidently move to the next layers such as Docker, Kubernetes, and CI/CD.

---

# Step 1: Try Running the Application Locally

Before doing any containerization, the first attempt was simply to run the application in the local system.

---

<img width="755" height="218" alt="Screenshot 2026-06-17 165006" src="https://github.com/user-attachments/assets/3bf1be65-d191-4f24-bdc4-b2ad0cd43bae" />

---

At this point, the goal was to confirm whether the application starts properly and whether it is accessible from the expected port and route.

---

# Step 2: Initial Error Observed

On the first attempt, the application did not behave as expected and an error was encountered.

---

<img width="672" height="128" alt="Screenshot 2026-06-17 164851" src="https://github.com/user-attachments/assets/74992959-9f41-431e-a955-45a0ca884689" />

---

This is exactly why local testing is a crucial step. If we had skipped this stage and gone directly into Docker or Kubernetes, we might have wrongly assumed that the issue was related to:

* Docker image configuration
* Kubernetes manifests
* service exposure
* ingress setup
* CI/CD pipeline problems

whereas the actual issue was still at the **application usage / route discovery** level.

---

# Step 3: Understand the Correct Application Route

After checking the project and the developer’s intended behavior, it became clear that the application was expected to be accessed at the following route:

```bash
http://localhost:8080/courses
```

or via terminal:

```bash
curl http://localhost:8080/courses
```

This was an important finding because the application was **not meant to be tested only at the root path**. The correct route included `/courses`.

That means a simple test like:

```bash
curl http://localhost:8080
```

would not have been sufficient to verify the actual functionality of the application.

---

# Step 4: Verify the Application from the Browser

Once the correct route was identified, the application was tested in the browser using:

```bash
http://localhost:8080/courses
```

and the application loaded successfully.

---

<img width="1538" height="773" alt="image" src="https://github.com/user-attachments/assets/9ce6f769-ae45-4e35-95ca-47d0186633fd" />

---

This confirmed that:

* the application was starting successfully
* it was listening on port `8080`
* the `/courses` route was working correctly
* the HTML/static content was being served properly

---

# Step 5: Verify the Application from the Terminal

To double-check the behavior without depending only on the browser, the same route was tested using `curl`:

```bash
curl http://localhost:8080/courses
```

This also returned the expected output, confirming that the route was functional from the application side.

---

<img width="1272" height="927" alt="image" src="https://github.com/user-attachments/assets/b628191f-044f-43bd-9a16-f12fec7ea775" />

---

# What We Confirmed Through Local Testing

By completing this local validation, we established a reliable baseline for the rest of the project.

We confirmed that:

* the Go application itself is working correctly
* the application listens on **port 8080**
* the correct accessible route is **`/courses`**
* the issue was not with the application logic anymore
* the same route must be preserved and tested later in:

  * Docker
  * Kubernetes
  * Ingress
  * CI/CD deployments

---

# Why This Step Saved Time Later

This local testing phase was extremely valuable because it prevented confusion in the later stages of the project.

Once the application was confirmed to work locally, any future issue could be narrowed down to one of the outer layers such as:

* Docker image build/runtime issues
* missing static files inside the container
* incorrect `targetPort` or `service` configuration in Kubernetes
* ingress path/host issues
* DNS or hostname mapping problems
* CI/CD deployment issues

Without this local validation, debugging later stages would have been much harder because we would not know whether the problem came from the **application itself** or the **deployment environment**.

---

# Key Takeaway

**Always test the application locally before containerizing or deploying it.**

In this project, local testing helped identify the correct route (`/courses`) and confirmed that the application was healthy before moving to Docker and Kubernetes. That gave us a solid reference point for all the troubleshooting that happened later in the project.

---

# Next Step

Now that the application is verified locally, the next step is to **containerize it using Docker** so that the same application can run consistently across environments.

➡️ Continue to: [**Containerization**](/02-containerization/readme.md)
