Before trying to do any Containerization, we first try to run the application in our local system whether it works - It's a very crucial step:

---

<img width="755" height="218" alt="Screenshot 2026-06-17 165006" src="https://github.com/user-attachments/assets/3bf1be65-d191-4f24-bdc4-b2ad0cd43bae" />

---
---

But we see error:
---

<img width="672" height="128" alt="Screenshot 2026-06-17 164851" src="https://github.com/user-attachments/assets/74992959-9f41-431e-a955-45a0ca884689" />

---
---

This is why testing it in our local system is important, because in this case, the developer has mentioned that we can access the application under the path `http://localhost:8080/courses` in our browser or `curl http://localhost:8080/courses` in the terminal

---

<img width="1538" height="773" alt="image" src="https://github.com/user-attachments/assets/9ce6f769-ae45-4e35-95ca-47d0186633fd" />

---

<img width="1272" height="927" alt="image" src="https://github.com/user-attachments/assets/b628191f-044f-43bd-9a16-f12fec7ea775" />

---
---

# 1. Containerization

### Writing Dockerfile

```Dockerfile
FROM golang:1.26 AS base

WORKDIR /app

COPY go.mod .

# Installing dependencies e.g. pip install -r requirements.txt in python
RUN go mod download  

# Copying the entire source code to the docker image
COPY . .

RUN go build -o main .
# The above command will create a artifact/binary called main in the docker image


# Final stage - Distroless image
FROM gcr.io/distroless/base

# Copying the artifact/main from the previous stage 
COPY --from=base /app/main .

# We need the static files also which consists of the HTML, CSS files which are not bundled in the binary
COPY --from=base /app/static ./static

# Exposing the port on which the application will run
EXPOSE 8080

# Command to run the application
CMD [ "./main" ]
```

### Building and testing the image:

---

<img width="1776" height="485" alt="Screenshot 2026-06-17 190021" src="https://github.com/user-attachments/assets/6bf3ff47-0e9a-414f-af79-f1973cfc5e0c" />

---
---

<img width="937" height="910" alt="image" src="https://github.com/user-attachments/assets/13cbfdb2-75d6-4073-b280-01cc8d8f0524" />

---
---

<img width="1538" height="773" alt="Screenshot 2026-06-17 180709" src="https://github.com/user-attachments/assets/6e2676b0-95bf-4ec9-b99c-9d638fbe7c25" />

---
---

### Pushing the image into the our Docker Hub:

  - Kubernetes by defualt tries to pull the images mentioned its deployments from the image registry
  - We can also use the local image
  - Best practice is to use the image registry

---

<img width="872" height="471" alt="image" src="https://github.com/user-attachments/assets/33256895-339e-443b-8bed-37e6fe60e8a9" />

---

<img width="990" height="307" alt="image" src="https://github.com/user-attachments/assets/ecf72b37-4b89-4fa0-b1d6-24b2787a6782" />

---
---

## Common Pitfalls in this step:

  - There could difference in the image version in the Dockerfile and the dependency file which could cause issue
      - e.g. In Dockerfile: `FROM golang:1.25 AS base` but in go.mod: `go 1.26`

  - There could be silly typos too whihc are sometimes frustrating to debug
      - e.g. `FROM grc.io/distroless/base` instead of `FROM gcr.io/distroless/base`

---

<img width="1207" height="421" alt="Screenshot 2026-06-17 185852" src="https://github.com/user-attachments/assets/a922c4c6-6638-4cbd-8405-a41441acdc22" />

---
---
---

# Kubernetes Manifests

- We have written Kubernetes manifest files:
    - [deployment.yaml](/k8s/manifests/deployment.yaml)    # For our application with labels, selectors, and containerPort as 8080
    - [service.yaml](/k8s/manifests/service.yaml)       # ClusterIP Service to expose our pods internally for uninterrupted communication -> ServicePort: 80 and TargetPort:8080 because the application is exposed at port 8080
    - [ingress.yaml](/k8s/manifests/ingress.yaml)       # To open our application to the external world
 
## Testing Our Application using NodePort Service

- We need a Kubernetes cluster to test our application
- We'll use EKS Cluster (as we are trying to implement production grade project here)
- Before running the below command, make sure you setup the pre-requisite tools: [pre-requisites]()
  
```bash
eksctl create cluster --name <CLUSTER-NAME> --region <YOUR-REGION>
```

---

<img width="1498" height="752" alt="image" src="https://github.com/user-attachments/assets/bae119d6-c64f-4ce1-af2e-9415ebc2f97d" />

---
---

All Set! Our Cluster ready with EC2 instances:

---

<img width="1129" height="320" alt="image" src="https://github.com/user-attachments/assets/82abb538-a21d-49bc-8013-e8095d3ba07a" />

---
---

<img width="1553" height="809" alt="image" src="https://github.com/user-attachments/assets/b21f723b-1f69-4268-9202-b271c4eabd27" />

---
---

#### Resolved some RBAC issues by giving the necessary permission to our user to be able to access our Resources:

---

<img width="1538" height="611" alt="image" src="https://github.com/user-attachments/assets/1f69779d-f420-48f2-b148-3a9e171536d1" />

---
---

#### We can see our resources:

---

<img width="1545" height="712" alt="image" src="https://github.com/user-attachments/assets/e5ca92f7-8295-4ed9-8731-ed7bed766c85" />

---
---

#### Now it's time to launch our deployement and service:

---

<img width="845" height="360" alt="image" src="https://github.com/user-attachments/assets/7fea2646-2683-46d1-8124-f4649510cedf" />

---
---

**We can verify the deployment and service getting created in our Cluster**

---

<img width="1631" height="733" alt="image" src="https://github.com/user-attachments/assets/e9fb67d0-30fc-424b-acd4-123977f483fc" />

---
---

**But this way we cannot access our application because ClusteIP Service does not map/expose our application to any export ports** </br>

**So we use NodePort Service to expose our application

**In our service.yaml file, we change the service type from ClusterIP to NodePort**

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
  # type: CLusterIP
  type: NodePort
```

```
k apply -f service.yaml
```


















