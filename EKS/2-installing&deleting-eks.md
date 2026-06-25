# Install EKS

Please follow the prerequisites doc before this - [prerequisites](/EKS/1-prerequisites.md)

## Install a EKS cluster with EKSCTL

```bash
eksctl create cluster --name <CLUSTER-NAME> --region <YOUR-REGION>
```

---

## Deleting the cluster after usage

```bash
eksctl delte cluster --name <CLUSTER-NAME> --region <YOUR-REGION>
```
