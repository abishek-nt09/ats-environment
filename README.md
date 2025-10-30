# 🚀 ATS Environment Setup

This repository automates the **environment provisioning** for the ATS (Applicant Tracking System) project on an **AWS EC2 instance** using **GitHub Actions**.

It prepares the EC2 instance for both the **backend (FastAPI)** and **frontend (Vite/React)** applications — installing dependencies, creating required directories, configuring PostgreSQL and Nginx, and setting up everything needed for deployment.

---

## 🧩 Overview

This workflow sets up the following on a fresh EC2 instance:

- ✅ Installs required system dependencies:
  - Python 3, pip, and venv  
  - PostgreSQL and extensions  
  - Nginx web server  
  - Node.js and npm  
  - Git and cURL

- ✅ Creates directory structure:
  - `/var/www/ats` → Application root  
  - `/var/www/ats-backups` → Stores backend database backups

- ✅ Configures PostgreSQL:
  - Creates a database and user (`ak_db`, `ak_user`) if not already present.

- ✅ Configures Nginx:
  - Reverse proxy for FastAPI backend  
  - Serves frontend static files  
  - Automatically injects the **EC2 IP address** from repository secrets

> 🧠 This workflow does **not start Nginx or frontend build** — those will be handled in the respective backend and frontend workflows.

---

## 🛠️ Folder Structure After Setup

/var/www/
│
├── ats/
│ ├── backend/ # FastAPI project (from ak-backend repo)
│ ├── frontend/ # Frontend project (deployed later)
│
└── ats-backups/
└── backend/ # Database backups (max 3 retained)


---

## 🔐 Required GitHub Secrets

Add the following secrets in your **`ats-environment` repository → Settings → Secrets → Actions**:

| Secret Name | Description |
|--------------|-------------|
| `EC2_HOST` | EC2 instance public IP address *(update when IP changes)* |
| `EC2_SSH_KEY` | Private SSH key for connecting to EC2 |
| `EC2_USER` | Usually `ubuntu` |

> 💡 **Note:** The SSH key you generated locally (e.g., `github_actions_deploy_key`) should have its **public key added to the EC2 instance** under `~/.ssh/authorized_keys`.

---

## ⚙️ Workflow Details

### File Path
.github/workflows/ats-environment.yml


### Trigger
- Manually triggered using **“Run workflow”** button in GitHub Actions.

### Purpose
Used **only once** when:
- Setting up a new EC2 instance
- Rebuilding from a terminated instance
- Preparing base system for deployments

---

## 🧾 What This Workflow Does

1. **Connects to EC2**
   - Uses SSH to securely connect using your provided key and IP.

2. **Installs Dependencies**
   ```bash
   sudo apt update -y
   sudo apt install -y python3 python3-venv python3-pip postgresql postgresql-contrib nginx nodejs npm git curl
   
3. Creates Directories
   sudo mkdir -p /var/www/ats /var/www/ats-backups
   sudo chown -R ubuntu:www-data /var/www/ats /var/www/ats-backups
   
4.Configures Database
  Creates ak_user and ak_db if missing.
  
5.Sets Up Nginx
  Adds /etc/nginx/sites-available/ats.conf
  Configures frontend and backend routes
  Uses ${{ secrets.EC2_HOST }} as server name
  Validates config with nginx -t
  
🧪 How to Run the Workflow

Push this workflow to your ats-environment repository.

Go to GitHub → Actions → ATS Environment Setup → Run workflow.

Wait ~2–3 minutes while it installs and configures everything.

Once complete:

/var/www/ats and /var/www/ats-backups are ready.

PostgreSQL and Nginx are configured.

🧹 After Setup

Once this workflow completes successfully:

Proceed to deploy the backend using the ak-backend repository’s CI/CD workflow.

Later, deploy the frontend which will start Nginx and serve static files.

You only need to re-run this workflow if:

You terminate and recreate the EC2 instance

You want to reset the environment cleanly

🧠 Notes

The IP address (EC2_HOST) should be updated in GitHub Secrets whenever your EC2 instance changes.

No need to manually edit Nginx — it’s generated automatically from this workflow.

Nginx will be enabled and started only during frontend deployment.

All configurations follow /var/www/ats as the base project directory.

✅ Summary

  Feature	                           Description
  
Provisioning	             Automated setup of EC2 dependencies
PostgreSQL	               Database and user auto-created
Nginx	                     Reverse proxy pre-configured
Directories	               /var/www/ats and /var/www/ats-backups auto-created
Manual Trigger	           Run anytime from GitHub Actions
Dynamic IP	               Controlled via EC2_HOST secret

👨‍💻 Maintainer

Author: Abishek S
Role: DevOps Engineer
Purpose: Environment setup automation for ATS project
Date: October 2025

🧩 Next Step:
Once the environment setup workflow is complete, deploy the backend using the
`ak-backend` repository’s GitHub Actions workflow.
