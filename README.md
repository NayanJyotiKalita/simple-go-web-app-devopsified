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

# 2. Kubernetes Manifests

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

```
chucky@Dell:~/simple-go-web-app-devopsified$ k get svc
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
go-web-app   NodePort    10.100.245.61   <none>        80:32379/TCP   8h
kubernetes   ClusterIP   10.100.0.1      <none>        443/TCP        9h

chucky@Dell:~/simple-go-web-app-devopsified$ k get nodes -o wide
NAME                                           STATUS   ROLES    AGE   VERSION               INTERNAL-IP      EXTERNAL-IP     OS-IMAGE                        KERNEL-VERSION                    CONTAINER-RUNTIME
ip-192-168-56-151.us-west-2.compute.internal   Ready    <none>   9h    v1.34.9-eks-93b80c6   192.168.56.151   34.219.31.71    Amazon Linux 2023.12.20260611   6.12.90-120.164.amzn2023.x86_64   containerd://2.2.4+unknown
ip-192-168-66-77.us-west-2.compute.internal    Ready    <none>   9h    v1.34.9-eks-93b80c6   192.168.66.77    35.164.247.96   Amazon Linux 2023.12.20260611   6.12.90-120.164.amzn2023.x86_64   containerd://2.2.4+unknown
```

**We can take any the External IP of any of the Nodes and map it to the Port of the NodePort Service given to us i.e. 32379**

***BUT!!!!***

### Error Alert! 

---

<img width="750" height="571" alt="Screenshot 2026-06-23 000013" src="https://github.com/user-attachments/assets/36f6f5df-0a36-4ab6-99c3-f153798d9ca0" />

---
---

### TROUBLESHOOTING

Upong further investigation, we found that 
  - A NodePort only opens the port on the node. AWS must also allow traffic to reach that port.
  - First thing to check: Security Group
    
```
EKS worker nodes typically allow:
22
80
443
1025-65535 (internal only)
```

  - But NodePort 32379 is usually NOT open from the internet.
  - So we check the security group of our nodes
  - We found that it is open but only from a specific Security Group

---

<img width="1625" height="397" alt="image" src="https://github.com/user-attachments/assets/7092e11b-515f-460e-80b4-9c432909375b" />

---
---

**We opened the port that is given to us by the NodePort and check**

---

<img width="1642" height="356" alt="image" src="https://github.com/user-attachments/assets/8b060558-8618-4b24-8ece-23084b0beb70" />

---
---

**And Finally it worked**

---

<img width="1505" height="744" alt="image" src="https://github.com/user-attachments/assets/00132e4b-c54b-46aa-93df-08366fb37314" />

---

This means that our Deployment is working find!!!

---

## Testing our Ingress file by configuring a Load Balancer

```
chucky@Dell:~/simple-go-web-app-devopsified/k8s/manifests$ k apply -f ingress.yaml 
ingress.networking.k8s.io/go-web-app created

chucky@Dell:~/simple-go-web-app-devopsified/k8s/manifests$ k get ingress
NAME         CLASS   HOSTS              ADDRESS   PORTS   AGE
go-web-app   nginx   go-web-app.local             80      30s
```

  - Ingress got created created sucessfully
  - But we see the `ADDRESS` field is still blank
  - It will be filled with the DNS name of the Load Balancer once it is configured
  - For that we need an Ingress Controller (We actually need to implement GatewayAPI but we'll do ingress for now)
  - Ingress Controller's Primary Responsibility is to look for an ingress resource and create a Load Balancer for it
  - We use the below command to intall the Nginx Ingress Controller

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.15.1/deploy/static/provider/aws/deploy.yaml
```
```
chucky@Dell:~/simple-go-web-app-devopsified/k8s/manifests$ k get pods -n ingress-nginx
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-controller-6fb6bc46cb-td2cl   1/1     Running     0          7m57s
```

#### NOTE:
  - In our `service.yaml` file, we have mentioned: `host: go-web-app.local`
  - This means that we need to be able to access our application when we run `go-web-app.local` in our browser instead of the address of the load balancer
  - And it should request to the service which would eventually forward our request to our pods/application

```
chucky@Dell:~/simple-go-web-app-devopsified/k8s/manifests$ k get ingress
NAME         CLASS   HOSTS              ADDRESS                                                                         PORTS   AGE
go-web-app   nginx   go-web-app.local   af1c475d2f805413b85b38159055f2bc-f193cd6541f83b02.elb.us-west-2.amazonaws.com   80      25m
```

**We can now see that the address field is now filled with the DNS/FQDL - Fully Qualified Domain Name of the load balancer (network) whihc is created by the ingress controller

---

<img width="1605" height="693" alt="Screenshot 2026-06-23 005502" src="https://github.com/user-attachments/assets/ded515bb-8b11-4eab-9483-44365d0afb96" />

---
---

But still we cannot access our application:

---

<img width="1046" height="159" alt="image" src="https://github.com/user-attachments/assets/18f56414-eb4b-4525-9328-fc57c57652ee" />

---

```
chucky@Dell:~/simple-go-web-app-devopsified$ curl go-web-app.local/courses
curl: (6) Could not resolve host: go-web-app.local
```

---

#### This is happening because in our Ingress file we have explicitely mentioned the host name to exactly as **go-web-app.local** 
  - This means that we can only access our application if our host name is mapped correctly to the IP address of the Load Balancer

```
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

#### So what we do here is - we take any of the IP Address from above and map it to our host name in _/etc/hosts_ path
```
127.0.0.1       localhost
127.0.1.1       Dell.localdomain        Dell
52.42.84.42   go-web-app.local
```

**We are all set but and seems like we would be able to access our application** </br>

***BUT!!!***

---

<img width="720" height="637" alt="image" src="https://github.com/user-attachments/assets/06b70cc4-31d5-4446-94e0-e9440bd63db9" />

---


---

### After some head hitting troubleshooting, I found out that it was happening due to misconfiguration with the System
  - I am using WSL and so I configured the DNS in my WSL, no in my windows system
  - So either I need to configure the DNS in my Windows or I can just verify in from the terminal of my WSL

**IT was successful**

```
chucky@Dell:~/simple-go-web-app-devopsified$ curl go-web-app.local/courses
<DocType html>

<html>
    <head>
        <title>Learn DevOps from Basics</title>
        <style>
            body {
                margin: 0;
                padding: 0;
            }

            header {
                background-color: #333;
                color: #fff;
                padding: 10px 0;
                text-align: center;
            }

            nav ul {
                list-style-type: none;
                padding: 0;
            }

            nav ul li {
                display: inline;
                margin-right: 10px;
            }

            nav ul li a {
                color: #fff;
                text-decoration: none;
            }

            main {
                padding: 20px;
            }

            section {
                margin-bottom: 20px;
            }

            footer {
                background-color: #333;
                color: #fff;
                text-align: center;
                padding: 10px 0;
                position: fixed;
                bottom: 0;
                width: 100%;
            }
        </style>
    </head>
    <body>
        <header>
            <nav>
                <ul>
                    <li><a href="home">Home</a></li>
                    <li><a href="about">About</a></li>
                    <li><a href="contact">Contact</a></li>
                    <li><a href="courses">Courses</a></li>
                </ul>
            </nav>
        </header>

        <main>
            <section>
                <h1>Learn DevOps from Basics</h1>
                <p>DevOps is a set of practices that combines software development (Dev) and IT operations (Ops)</p>
                <p>It aims to shorten the systems development life cycle and provide continuous delivery with high software quality. DevOps is complementary with Agile software development; several DevOps aspects came from Agile methodology</p>    
```

---
---
---

# HELM

  - Helm helps us launching the same files/configurations into different environments with ease

  - It helps us in variabalizing various hardcoded values
    - e.g. : `image: nayanjk/go-web-app:dev` for our developer environment and we `image: nayanjk/go-web-app:stage/prod` for the respective env.

    - It helps us in variabalizing those env parameters with an ease reducing our efforts to write same files repeatedly

    - We would have needed to create one folder for each env.

## Installing Helm

**For Debian/Ubuntu**:

```bash
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

For other systems: [Documentation](https://helm.sh/docs/intro/install/)


**After installation, verify**:
```
chucky@Dell:~/simple-go-web-app-devopsified$ helm version
version.BuildInfo{Version:"v3.18.4", GitCommit:"d80839cf37d860c8aa9a0503fe463278f26cd5e2", GitTreeState:"clean", GoVersion:"go1.24.4"}
```

### Helm initialization

```
chucky@Dell:~/simple-go-web-app-devopsified/helm$ helm create go-web-app-chart
Creating go-web-app-chart
```

**As soon as the creation is over, we can see the a lot of files and folders getting created inside it:**

---

<img width="306" height="534" alt="image" src="https://github.com/user-attachments/assets/47a8f833-565b-4668-988c-ef3a65fa79f2" />

---
---

**We remove the charts directory**:

```bash
rm -rf charts/
```

**Delete everything inside the templates directory and copy all of our k8s manifests that we created:**

```bash
cd templates/
rm -rf *
```

```bash
chucky@Dell:~/simple-go-web-app-devopsified/helm/go-web-app-chart/templates$ cp ../../../k8s/manifests/* .
chucky@Dell:~/simple-go-web-app-devopsified/helm/go-web-app-chart/templates$ ls
--> deployment.yaml  ingress.yaml  service.yaml
```

## Variabalizing our values

Inside the `deployment.yaml` under the `templates` directory:

```yaml
    spec:
      containers:
      - image: nayanjk/go-web-app:{{ .Values.image.tag }}
        name: nginx
        ports:
        - containerPort: 8080
```

Whatever portion we want to variabalize, we can variabalize them and then update the same in the `values.yaml` file:

  - We will delete all the default content in the `values.yaml` file and add something of our own:

```yaml
replicaCount: 1

image:
  repository: nayanjk/go-web-app
  pullPolicy: IfNotPresent
  # Overrides the image tag whose default is the chart appVersion.
  # tag: "10016307834"  # Not just a random number (explained below)
  tag: "v1"  # because our current tag is v1
ingress:
  enabled: false
  className: ""
  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: ImplementationSpecific
```
```
tag: "10016307834" -> This number is not just a random number - it has its significance - we'll see it clearly in the CI/CD part
So what happens is, every time the CI/CD is run, we'll update the Values.yaml with the latest image that we create during the CI 
And with the help of ArgoCD the image with the latest tag will be deployed
```


## Verifying the proper working of our Helm

  - We have our kubernetes resources
  - We will delete those
  - We will create the resources using Helm

```
chucky@Dell:~/simple-go-web-app-devopsified/k8s/manifests$ k get all
NAME                              READY   STATUS    RESTARTS   AGE
pod/go-web-app-784bd6b777-fhkqv   1/1     Running   0          20m

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/go-web-app   NodePort    10.100.137.79   <none>        80:31377/TCP   2m52s
service/kubernetes   ClusterIP   10.100.0.1      <none>        443/TCP        56m

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/go-web-app   1/1     1            1           20m

NAME                                    DESIRED   CURRENT   READY   AGE
replicaset.apps/go-web-app-784bd6b777   1         1         1       21m
```

```
chucky@Dell:~/simple-go-web-app-devopsified/k8s/manifests$ k delete deploy go-web-app
deployment.apps "go-web-app" deleted
chucky@Dell:~/simple-go-web-app-devopsified/k8s/manifests$ k delete svc go-web-app
service "go-web-app" deleted
chucky@Dell:~/simple-go-web-app-devopsified/k8s/manifests$ k delete ingress go-web-app
ingress.networking.k8s.io "go-web-app" deleted
chucky@Dell:~/simple-go-web-app-devopsified/k8s/manifests$ k get all
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP   70m
```

**Deploying resources using Helm**:

---

<img width="845" height="486" alt="image" src="https://github.com/user-attachments/assets/dc45ce9c-209f-4554-8846-882700176914" />

---
---

**Inside our Deployment, we can see the image being used at the same as that of what we uploaded into our registry with tag v1 even though we have variabalized the tag in the deployment.yaml file**

---

<img width="549" height="257" alt="image" src="https://github.com/user-attachments/assets/34cbf738-59f9-4ded-934a-53b4ce23a6dd" />

---
```yaml
spec:
      containers:
      - image: nayanjk/go-web-app:{{ .Values.image.tag }}
        name: nginx
        ports:
        - containerPort: 8080
```
---

## Cleanup of Resources using Helm

```
chucky@Dell:~/simple-go-web-app-devopsified$ helm uninstall go-web-app
release "go-web-app" uninstalled
chucky@Dell:~/simple-go-web-app-devopsified$ k get all
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP   2d3h
```

---
---
---

# CI/CD

## CI - Using GitHub Actions

  - **Build and Unit Test**
  - **Static Code Analysis**
  - **Create Docker Image and Push it**
  - **Update Helm with our Docker Image**

## CD - Using ArgoCd

  - **ArgoCD will pull the Helm Chart as soon as Helm (values.yaml) tag is updated and deploy it on to the Kubernetes cluster** 

---

## CI

### Wrote the Entire CI pipeline to Build, Code Analysis, Creating Docker Image 

You can check out the entire file here: [ci.yaml](.github/workflows/ci.yaml) </br>

**We used a few secrets to avoid hardcoding of sensitive information**:

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

    update-newtag-in-helm-chart:
        runs-on: ubuntu-latest

        needs: push-docker

        steps:
        - name: Checkout Repository
          uses: actions/checkout@v7
          with:
            token: ${{ secrets.TOKEN_GITHUB }}  # Github Personal Access Token
```

### Secrets added in the repo for the github workflow to fetch
---

<img width="921" height="229" alt="image" src="https://github.com/user-attachments/assets/32af666b-eddf-493e-be18-a8f442c51a70" />

---

## Testing the CI part:

```
chucky@Dell:~/simple-go-web-app-devopsified$ git add .
chucky@Dell:~/simple-go-web-app-devopsified$ git commit -m "Adding and Testing CI"
[main 933e786] Adding and Testing CI
 2 files changed, 157 insertions(+)
 create mode 100644 .github/workflows/ci.yaml
chucky@Dell:~/simple-go-web-app-devopsified$ git push -o origin
Enumerating objects: 8, done.
Counting objects: 100% (8/8), done.
Delta compression using up to 8 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (6/6), 2.11 KiB | 2.11 MiB/s, done.
Total 6 (delta 2), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
To https://github.com/NayanJyotiKalita/simple-go-web-app-devopsified.git
   f51a931..933e786  main -> main
```

**Troubleshooting**:
  - Came across a little error:

---

<img width="1859" height="946" alt="image" src="https://github.com/user-attachments/assets/6028c8a4-7b71-40d9-bd73-955fd66873b4" />

---
---

  - Fixed the error in the shown version
  - Fixed a few errors in the testing part --> understood the importance of **three dots** in Go **(./..)**
  - Fixed a few version errors in the checkout action

**And finally:**

---

<img width="1304" height="873" alt="image" src="https://github.com/user-attachments/assets/1dac56c7-e569-42b5-8565-f21f318b3a7d" />

---
---

**We will check our Docker Hub Registry whether the Docker Image with the appropriate tag is pushed or not**:

---

<img width="1585" height="805" alt="image" src="https://github.com/user-attachments/assets/58c4161f-6657-4ca7-ba5b-e92fd6d15ab0" />

---
---

### This resulted in the same tag with the github run_id being updated in the values.yaml file:

<img width="1328" height="174" alt="image" src="https://github.com/user-attachments/assets/a0ce3707-7f9f-4085-ab26-fdd8b599e8f0" />

---
---

## CD

**We install ArgoCD**:

```bash
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Setting up the Service for LoadBalancer
```
chucky@Dell:~/simple-go-web-app-devopsified$ kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
service/argocd-server patched
```

---

<img width="1520" height="441" alt="image" src="https://github.com/user-attachments/assets/b239aa76-2022-4e75-835c-d2f794c9eb69" />

---
---

**Once we try to access our ArgoCD using the external IP provided to us, we are prompted to type username and password**:

---

<img width="1918" height="792" alt="Screenshot 2026-06-28 193813" src="https://github.com/user-attachments/assets/43de8cc6-8ce2-4d43-921e-20e6f2832111" />

---
---

- The username can be `admin`
- Steps for retrieving the password is given below:

```
chucky@Dell:~/simple-go-web-app-devopsified$ k get secrets -n argocd
NAME                          TYPE     DATA   AGE
argocd-initial-admin-secret   Opaque   1      13m
argocd-notifications-secret   Opaque   0      14m
argocd-redis                  Opaque   1      13m
argocd-secret                 Opaque   5      14m

chucky@Dell:~/simple-go-web-app-devopsified$ k edit secret -n argocd argocd-initial-admin-secret
```

- Copy the password from the file
- The password is base64 encoded
- We need to decode it:

```
chucky@Dell:~/simple-go-web-app-devopsified$ echo password | base64 --decode
```

- **The output is the final password and we can access our ArgoCd**

---

<img width="1871" height="597" alt="image" src="https://github.com/user-attachments/assets/34fd7e09-8ded-45ea-a0b4-40bb05077547" />

---
---

- **Then we select on New App to create our Deployment**

---

<img width="1871" height="597" alt="image" src="https://github.com/user-attachments/assets/34fd7e09-8ded-45ea-a0b4-40bb05077547" />

---
---

**We Configure the Argo Application as below:**

---

<img width="354" height="508" alt="Screenshot 2026-06-28 230311" src="https://github.com/user-attachments/assets/1f4bccb8-18f8-42f8-aa3d-6ff3e9cff33e" />

---
---

<img width="788" height="857" alt="image" src="https://github.com/user-attachments/assets/3cf1ac96-350f-47a9-8177-ec21ef91eb82" />

---
---

## All done with CD:

***Make sure the ingress-controller is running otherwise ingress won't be able to get the DNS name**

---

<img width="1871" height="626" alt="image" src="https://github.com/user-attachments/assets/51306706-954d-4692-967c-6c103d06d573" />

---
---

**We can see our resources:**

---

<img width="1202" height="360" alt="image" src="https://github.com/user-attachments/assets/b35039da-ec8d-4d7a-b778-11de4b3b391e" />

---
---

### We can access our website:

```bash
chucky@Dell:~/simple-go-web-app-devopsified$ curl go-web-app.local/courses
<DocType html>

<html>
    <head>
        <title>Learn DevOps from Basics</title>
        <style>
            body {
                margin: 0;
                padding: 0;
            }
    
```

#### DNS mapping in the /etc/hosts is still required as our system doesn't understand what go-web-app.local means
#### In production environment, we will buy a domain and map it e.g.:

```
go-web-app.com
        │
        ▼
a4a31af79657346d08d198d7a8999102.elb.us-west-2.amazonaws.com
```

---
---
---

# Entire CI/CD pipeline flow

- We make a tiny change in the static folder - `courses.html`:
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

#### As soon as it is committed, it will trigger the CI part of GitHub Action:

---

<img width="1274" height="491" alt="image" src="https://github.com/user-attachments/assets/b3433bf5-cdda-457c-94d3-461f8c148c91" />

---
---

#### This process will lead to a new Docker image being built and pushed:

---

<img width="1564" height="770" alt="image" src="https://github.com/user-attachments/assets/43e5d8ca-881d-47c8-94db-f5707b3bdcd5" />

---
---

#### Leading to changes in the Helm's values.yaml file with the latest tag:

```yaml
image:
  repository: nayanjk/go-web-app
  pullPolicy: IfNotPresent
  tag: "28332165890"
```

#### Now this change in the Helm values.yaml will be fetched by ArgoCD and deployed on to the Kubernetes:

- We can verify it by looking at the deployment:

---

<img width="442" height="170" alt="image" src="https://github.com/user-attachments/assets/c1afb1c5-64d6-4d6a-b65b-68345a138797" />

---
**Also**
---

<img width="690" height="248" alt="image" src="https://github.com/user-attachments/assets/978bf394-1af1-4f93-a876-e58b763f3741" />

---