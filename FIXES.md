# Guide des Corrections de Sécurité

Ce document détaille toutes les corrections apportées pour résoudre les 27+ vulnérabilités détectées par le pipeline DevSecOps.

## Table des Matières

1. [Corrections GitLeaks - Secrets Hardcodés](#1-corrections-gitleaks)
2. [Corrections Semgrep - SAST](#2-corrections-semgrep)
3. [Corrections pip-audit - Dépendances](#3-corrections-pip-audit)
4. [Corrections Checkov - Kubernetes](#4-corrections-checkov-kubernetes)
5. [Corrections Checkov - Terraform](#5-corrections-checkov-terraform)
6. [Corrections Trivy - Container](#6-corrections-trivy)

---

## 1. Corrections GitLeaks

### 🔴 Problème: Secrets Hardcodés (CWE-798)

**Fichier**: `app/main.py`

**Vulnérabilités détectées**: 4+ secrets
- AWS Access Key ID
- AWS Secret Access Key
- GitHub Personal Access Token
- Database Password
- Slack Webhook URL

### ✅ Solution

**Fichier corrigé**: `fixed/app/main.py`

```python
# AVANT (Vulnérable)
AWS_ACCESS_KEY_ID = "AKIA[REDACTED]EXAMPLE"  # Hardcoded AWS key
AWS_SECRET_ACCESS_KEY = "[SECRET_KEY_REDACTED]"  # Hardcoded secret
GITHUB_TOKEN = "ghp_[REDACTED]"  # Hardcoded GitHub token

# APRÈS (Sécurisé)
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')
```

**Actions prises**:
1. Utilisation de variables d'environnement via `os.getenv()`
2. Secrets stockés dans un gestionnaire de secrets (AWS Secrets Manager, Kubernetes Secrets)
3. Rotation immédiate des credentials exposés
4. Documentation du processus dans le README

---

## 2. Corrections Semgrep

### 🔴 Problème 1: SQL Injection (CWE-89)

**Fichier**: `app/main.py:37`

```python
# AVANT (Vulnérable)
query = "SELECT * FROM users WHERE username = '" + username + "'"
cursor.execute(query)
```

### ✅ Solution

```python
# APRÈS (Sécurisé)
cursor.execute("SELECT * FROM users WHERE username = ?", (username,))
```

**Actions prises**:
- Utilisation de requêtes paramétrées (prepared statements)
- Séparation des données et du code SQL
- Prévention de l'injection SQL

---

### 🔴 Problème 2: Cryptographie Faible - MD5 (CWE-327)

**Fichier**: `app/main.py:52`

```python
# AVANT (Vulnérable)
password_hash = hashlib.md5(password.encode()).hexdigest()
```

### ✅ Solution

```python
# APRÈS (Sécurisé)
import bcrypt
salt = bcrypt.gensalt()
password_hash = bcrypt.hashpw(password.encode(), salt)
```

**Actions prises**:
- Remplacement de MD5 par bcrypt
- Utilisation de salt automatique
- Ajout de bcrypt dans requirements.txt
- Coût adaptatif pour résister aux attaques par force brute

---

### 🔴 Problème 3: SSRF - Validation d'Entrée Manquante (CWE-918)

**Fichier**: `app/main.py:74`

```python
# AVANT (Vulnérable)
response = requests.get(url)  # No URL validation
```

### ✅ Solution

```python
# APRÈS (Sécurisé)
from urllib.parse import urlparse

ALLOWED_DOMAINS = ['api.example.com', 'safe-api.com']

parsed_url = urlparse(url)
if parsed_url.netloc not in ALLOWED_DOMAINS:
    raise HTTPException(status_code=400, detail="Domain not allowed")

if parsed_url.scheme not in ['http', 'https']:
    raise HTTPException(status_code=400, detail="Invalid URL scheme")

response = requests.get(url, timeout=5)
```

**Actions prises**:
- Validation du domaine avec allowlist
- Vérification du schéma URL
- Ajout de timeout pour éviter les blocages
- Gestion d'erreurs appropriée

---

## 3. Corrections pip-audit

### 🔴 Problème: Dépendances Vulnérables

**Fichier**: `app/requirements.txt`

**CVE détectés**: 6+

| Package | Version Vulnérable | CVEs | Version Corrigée |
|---------|-------------------|------|------------------|
| fastapi | 0.65.0 | Multiples | 0.115.0 |
| requests | 2.25.1 | CVE dans urllib3 | 2.32.3 |
| pyyaml | 5.3.1 | CVE-2020-14343, CVE-2020-1747 | 6.0.2 |
| urllib3 | 1.26.4 | CVE-2021-33503 | 2.2.3 |
| jinja2 | 2.11.3 | CVE-2020-28493 | 3.1.4 |
| cryptography | 3.3.2 | Multiples | 44.0.0 |

### ✅ Solution

**Fichier corrigé**: `fixed/app/requirements.txt`

```txt
# Versions mises à jour
fastapi==0.115.0
requests==2.32.3
pyyaml==6.0.2
urllib3==2.2.3
jinja2==3.1.4
cryptography==44.0.0
bcrypt==4.2.1
```

**Actions prises**:
1. Mise à jour vers les dernières versions stables
2. Vérification de compatibilité entre packages
3. Tests de régression après mise à jour
4. Mise en place de Dependabot/Renovate pour automatiser les mises à jour

---

## 4. Corrections Checkov - Kubernetes

### 🔴 Problèmes Détectés: 8+ Misconfigurations

**Fichier**: `kubernetes/deployment.yaml`

#### Liste des problèmes:
1. ❌ Pas de liveness probe
2. ❌ Pas de readiness probe
3. ❌ Pas de resource limits (CPU)
4. ❌ Pas de resource requests (CPU)
5. ❌ Pas de resource limits (Memory)
6. ❌ Pas de resource requests (Memory)
7. ❌ Image tag `:latest` utilisé
8. ❌ Pas de securityContext
9. ❌ Secrets hardcodés dans env

### ✅ Solutions

**Fichier corrigé**: `fixed/kubernetes/deployment.yaml`

#### 1. Probes de Santé

```yaml
# Liveness Probe
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 30
  periodSeconds: 10

# Readiness Probe
readinessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 5
  periodSeconds: 5

# Startup Probe
startupProbe:
  httpGet:
    path: /health
    port: 8000
  failureThreshold: 30
```

#### 2. Resource Limits

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

#### 3. Security Context

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
    add:
      - NET_BIND_SERVICE
```

#### 4. Tag d'Image Spécifique

```yaml
# AVANT
image: devsecops-demo:latest

# APRÈS
image: devsecops-demo:v2.0.0
```

#### 5. Secrets Kubernetes

```yaml
env:
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: aws-credentials
      key: access-key-id
```

---

## 5. Corrections Checkov - Terraform

### 🔴 Problèmes Détectés: 3+ Misconfigurations

**Fichier**: `terraform/main.tf`

#### Liste des problèmes:
1. ❌ Security Group ouvert à 0.0.0.0/0
2. ❌ S3 bucket sans encryption
3. ❌ S3 bucket sans versioning
4. ❌ EC2 root volume non chiffré
5. ❌ IMDSv1 activé

### ✅ Solutions

**Fichier corrigé**: `fixed/terraform/main.tf`

#### 1. Security Group Restreint

```hcl
# AVANT
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # Ouvert au monde entier
}

# APRÈS
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["10.0.1.0/24"]  # Restreint au bastion
}
```

#### 2. S3 Encryption

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}
```

#### 3. S3 Versioning

```hcl
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

#### 4. S3 Public Access Block

```hcl
resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

#### 5. EC2 Root Volume Encryption

```hcl
root_block_device {
  volume_size = 20
  volume_type = "gp3"
  encrypted   = true  # Encryption activée
}
```

#### 6. IMDSv2 Requis

```hcl
metadata_options {
  http_endpoint = "enabled"
  http_tokens   = "required"  # Force IMDSv2
}
```

---

## 6. Corrections Trivy

### 🔴 Problèmes Détectés: 2+ CVE HIGH/CRITICAL

**Fichier**: `Dockerfile`

#### Liste des problèmes:
1. ❌ Image de base avec CVEs
2. ❌ Dépendances vulnérables
3. ❌ Running as root
4. ❌ Pas de HEALTHCHECK

### ✅ Solutions

**Fichier corrigé**: `fixed/Dockerfile`

#### 1. Multi-Stage Build

```dockerfile
# Build stage
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
```

#### 2. Non-Root User

```dockerfile
RUN groupadd -r appuser && useradd --no-log-init -r -g appuser appuser
USER appuser
```

#### 3. HEALTHCHECK

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1
```

#### 4. Exec Form CMD

```dockerfile
# AVANT
CMD uvicorn main:app --host 0.0.0.0 --port 8000

# APRÈS
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## Résumé des Corrections

| Catégorie | Problèmes | Solutions | Status |
|-----------|-----------|-----------|--------|
| **Secrets** | 4+ hardcodés | Variables d'env | ✅ |
| **SAST** | 4 vulnérabilités | Paramétrées, bcrypt, validation | ✅ |
| **Dépendances** | 6+ CVE | Mise à jour versions | ✅ |
| **K8s** | 8+ misconfigs | SecurityContext, probes, limits | ✅ |
| **Terraform** | 3+ misconfigs | Encryption, SG restreints, IMDSv2 | ✅ |
| **Container** | 2+ CVE | Multi-stage, non-root, healthcheck | ✅ |

## Vérification des Corrections

Pour vérifier que toutes les corrections fonctionnent:

```bash
# 1. Vérifier les secrets
cd fixed/
grep -r "AKIA" . # Devrait être vide
grep -r "ghp_" . # Devrait être vide

# 2. Lancer les scans sur les fichiers corrigés
gitleaks detect --source ./fixed/
semgrep scan --config=auto fixed/app/
pip-audit --requirement fixed/app/requirements.txt
checkov --directory fixed/kubernetes/
checkov --directory fixed/terraform/
```

## Prochaines Étapes

1. ✅ Tester les fichiers corrigés en local
2. ✅ Déployer sur environnement de dev
3. ✅ Exécuter le pipeline sur les fichiers corrigés
4. ✅ Vérifier que tous les scans passent
5. ✅ Documenter les leçons apprises
6. ✅ Mettre en place une surveillance continue

## Références

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Terraform Security Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)

---

**Note**: Tous les fichiers corrigés se trouvent dans le répertoire `fixed/` et peuvent être comparés avec les versions vulnérables dans le répertoire racine.
