# HSBC Onboarding Week — Day-by-Day Lab Guide

This project builds one continuous pipeline across seven days. Nothing you do on Day 1 gets thrown away — Day 7 uses the same VPC, cluster, image, and pipeline that Day 1 through Day 6 built. Tear down resources each night (`terraform destroy`) to stay inside free-tier limits, and re-apply the next morning; the state files will recreate everything identically.

Before Day 1: create a GCP free-tier account, create a new project, enable billing (free tier still requires a card on file but won't charge you if you stay in the always-free limits), and install `gcloud`, `terraform`, `kubectl`, `ansible`, and `docker` locally. Run `gcloud init` and `gcloud auth application-default login` once so Terraform can authenticate.

## Day 1 — GCP Networking and IAM
Files: `terraform/day1-network/`

1. `cd terraform/day1-network`, run `terraform init`, then `terraform apply -var="project_id=YOUR_PROJECT_ID"`.
2. This creates a VPC with two subnets, a firewall rule allowing internal traffic between them, a firewall rule allowing SSH only from Google's IAP range (not the open internet — this is the SecOps habit to build early), and two VMs with no public IP.
3. Test connectivity: `gcloud compute ssh lab-vm-a --zone us-central1-a --tunnel-through-iap`, then from inside VM A, `ping` VM B's internal IP (shown in the Terraform output) to confirm the internal firewall rule works.
4. Revise alongside this: IAM roles vs. predefined vs. custom roles, and why "no public IP + IAP" is the pattern GCP recommends over open SSH.
5. Do not destroy this yet — Day 2 builds on top of this VPC.

## Day 2 — Kubernetes and GKE
Files: `terraform/day2-gke/`, `k8s/`

1. `cd terraform/day2-gke`, `terraform init`, `terraform apply -var="project_id=YOUR_PROJECT_ID"`. This creates a GKE Autopilot cluster inside the Day 1 VPC.
2. `gcloud container clusters get-credentials hsbc-lab-cluster --region us-central1`.
3. Apply the namespace only for now: `kubectl apply -f k8s/namespace.yaml`. The Deployment needs a real image, which you build on Day 3, so hold off on `deployment.yaml` until then — or apply it as-is to see it fail on `ImagePullBackOff` and practice diagnosing that exact error, which is common in real GKE troubleshooting.
4. Apply `k8s/hpa.yaml` once the Deployment is running (Day 3 onward) and generate load with a simple loop of curl requests to watch it scale — this is your hands-on scaling exercise.
5. Revise alongside this: Deployments vs. ReplicaSets, readiness vs. liveness probes (both are already wired into `k8s/deployment.yaml`), and how HPA reads metrics.

## Day 3 — Docker
Files: `app/`, `docker/Dockerfile`

1. From the project root: `docker build -f docker/Dockerfile -t lab-app:local .`
2. Run it locally first: `docker run -p 8080:8080 lab-app:local`, then hit `http://localhost:8080` and `http://localhost:8080/healthz` to confirm it works before touching the cloud.
3. Create an Artifact Registry repo: `gcloud artifacts repositories create lab-repo --repository-format=docker --location=us-central1`.
4. Tag and push: `docker tag lab-app:local us-central1-docker.pkg.dev/YOUR_PROJECT_ID/lab-repo/lab-app:1.0.0`, then `gcloud auth configure-docker us-central1-docker.pkg.dev` and `docker push ...`.
5. Now go back to Day 2's cluster: edit `k8s/deployment.yaml`, replace the placeholder image line with your real pushed image, and `kubectl apply -f k8s/deployment.yaml -f k8s/service.yaml -f k8s/ingress.yaml`. Watch the ImagePullBackOff from Day 2 resolve.
6. Revise alongside this: multi-stage builds, why the image runs as a non-root user (`appuser`), and layer caching.

## Day 4 — Jenkins, CloudBees, and Pipeline as Code
Files: `jenkins/Jenkinsfile`

1. If you don't have a Jenkins instance, the fastest lab setup is `docker run -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts` locally, or install CloudBees CI's free trial if you want to see the actual CloudBees UI and RBAC differences the JD mentions.
2. Push this whole project folder to a personal GitHub repo, then create a Jenkins Pipeline job pointing at it with "Pipeline script from SCM" so it picks up `jenkins/Jenkinsfile` automatically — this is what "Pipeline as Code" means in practice, versus pasting a script into Jenkins's UI.
3. Update the `PROJECT_ID` value inside the Jenkinsfile to yours before running it.
4. Read CloudBees' own documentation for an hour today specifically on what it adds over open-source Jenkins — shared libraries at scale, RBAC, and managed controllers — so you can speak to the difference even without a CloudBees license.
5. Run the pipeline. It will fail at the Security Scan stage unless Trivy is installed on your Jenkins agent — that's expected and becomes the lab for Day 6.

## Day 5 — Terraform and Ansible together
Files: `terraform/day5-vm/`, `ansible/`

1. `cd terraform/day5-vm`, `terraform apply -var="project_id=YOUR_PROJECT_ID"` to provision a plain VM — deliberately not through Kubernetes, since the JD calls out VM management specifically.
2. Open an IAP tunnel: `gcloud compute start-iap-tunnel ansible-target-vm 22 --local-host-port=localhost:2222 --zone=us-central1-a`.
3. Update `ansible/inventory.ini` with your gcloud username, then from the `ansible/` folder: `ansible-playbook -i inventory.ini playbook.yml`.
4. Run it a second time and confirm nothing changes on the second run — that's idempotency, the core Ansible concept the JD is testing for.
5. Revise alongside this: the conceptual split between Terraform (provisions infrastructure) and Ansible (configures what's already provisioned), since interviewers often ask exactly this.

## Day 6 — SecOps and Identity
Files: revisit `jenkins/Jenkinsfile`, `terraform/day1-network/main.tf`

1. Install Trivy on your Jenkins agent (or locally: `trivy image lab-app:local`) and re-run the Day 4 pipeline so the Security Scan stage actually passes or fails meaningfully.
2. Move the `PROJECT_ID` and any credentials out of the Jenkinsfile and into Jenkins Credentials or GCP Secret Manager instead — practice retrieving a secret from Secret Manager via `gcloud secrets versions access latest --secret=my-secret` and wiring that into a pipeline stage.
3. Create one custom IAM role scoped to only what your pipeline's service account needs (Artifact Registry push, GKE deploy) instead of using a broad Editor role, and attach it.
4. Revise alongside this: least privilege, service account key rotation risks (and why workload identity federation is preferred over downloaded JSON keys on GKE), and basic audit logging in GCP.

## Day 7 — Consolidation
No new files — this is deliberate.

1. Tear everything down (`terraform destroy` in each of the three Terraform folders) and rebuild the entire chain from Day 1 through Day 6 from memory, using this README only to check yourself afterward, not while you work.
2. In the afternoon, skim Spring Boot basics and how AI-assisted coding tools fit into a DevOps workflow, since both are only nice-to-haves in the JD.
3. If everything in this rebuild works without you needing to stop and search for basic syntax, you're in good shape for the onboarding.
