# DevSecOps Pipeline Demo - Projet de Démonstration Académique

## Avertissement

**Ce projet contient des vulnérabilités de sécurité INTENTIONNELLES à des fins éducatives uniquement.**
Ne jamais utiliser ce code en production ou dans un environnement réel.

## Description

Projet de démonstration pour un pipeline CI/CD sécurisé intégrant plusieurs outils de sécurité DevSecOps. Ce projet illustre comment détecter automatiquement les vulnérabilités de sécurité à différentes étapes du cycle de développement.

## Architecture du Projet

```
devsecops-pipeline-demo/
├── app/
│   ├── main.py                  # Application FastAPI avec vulnérabilités SAST
│   └── requirements.txt         # Dépendances Python avec CVE connus
├── kubernetes/
│   └── deployment.yaml          # Configuration K8s avec misconfigurations
├── terraform/
│   └── main.tf                  # Infrastructure AWS avec misconfigurations
├── .github/
│   └── workflows/
│       └── devsecops.yml        # Pipeline CI/CD avec 5 outils de sécurité
├── Dockerfile                   # Image Docker avec vulnérabilités
└── README.md                    # Documentation
```

## Outils de Sécurité Intégrés

### 1. GitLeaks - Détection de Secrets
- Scanne le code pour détecter les secrets hardcodés
- Détecte les clés API, tokens, mots de passe
- **Findings attendus**: 1 secret

### 2. Semgrep - Analyse SAST (Static Application Security Testing)
- Analyse statique du code source
- Détecte les vulnérabilités courantes (OWASP Top 10)
- **Findings attendus**: 3 vulnérabilités
  - SQL Injection
  - Utilisation de MD5 (cryptographie faible)
  - Validation d'entrée manquante (SSRF)

### 3. pip-audit - Analyse des Dépendances Python
- Scanne les dépendances Python pour les CVE connus
- Utilise la base de données PyPI Advisory
- **Findings attendus**: 6+ CVE

### 4. Checkov - Analyse Infrastructure as Code
- Scanne Kubernetes, Terraform, Dockerfile
- Détecte les misconfigurations de sécurité
- **Findings attendus**: 11 misconfigurations
  - 8 dans Kubernetes (pas de securityContext, limits, probes, etc.)
  - 3 dans Terraform (Security Group ouvert, S3 sans encryption, etc.)

### 5. Trivy - Scan de Vulnérabilités Container
- Scanne les images Docker pour les CVE
- Analyse les dépendances OS et applicatives
- **Findings attendus**: 2+ CVE HIGH/CRITICAL

## Résultats Attendus

### Récapitulatif des Findings

| Outil       | Type                    | Nombre de Findings | Sévérité          |
|-------------|-------------------------|--------------------|-------------------|
| GitLeaks    | Secrets hardcodés       | 1                  | CRITICAL          |
| Semgrep     | SAST (Code)             | 3                  | HIGH              |
| pip-audit   | Dépendances Python      | 6+                 | HIGH/MEDIUM       |
| Checkov     | IaC Kubernetes          | 8                  | MEDIUM/HIGH       |
| Checkov     | IaC Terraform           | 3                  | HIGH/CRITICAL     |
| Trivy       | Container Image         | 2+                 | HIGH/CRITICAL     |
| **TOTAL**   |                         | **23+**            |                   |

### Temps d'Exécution Pipeline
- **Durée totale**: ~4-5 minutes
- GitLeaks: ~30 secondes
- Semgrep: ~1 minute
- pip-audit: ~45 secondes
- Checkov: ~1 minute
- Trivy: ~1-2 minutes

## Détails des Vulnérabilités Intentionnelles

### 1. GitLeaks Findings

**app/main.py**:
```python
API_KEY = "AKIAIOSFODNN7EXAMPLE1234567890ABCDEFGHIJ"  # Fake AWS-like key
DATABASE_PASSWORD = "SuperSecret123!@#"
STRIPE_KEY = "sk_test_4eC39HqLyjWDarjtT1zdp7dc"  # Example test key
```

### 2. Semgrep SAST Findings

**SQL Injection** (app/main.py:37):
```python
query = "SELECT * FROM users WHERE username = '" + username + "'"
cursor.execute(query)
```

**Weak Cryptography - MD5** (app/main.py:52):
```python
password_hash = hashlib.md5(password.encode()).hexdigest()
```

**Missing Input Validation - SSRF** (app/main.py:74):
```python
response = requests.get(url)  # No URL validation
```

### 3. pip-audit Dependency CVEs

**requirements.txt** contient des versions vulnérables:
- `fastapi==0.65.0` - Plusieurs CVE
- `requests==2.25.1` - CVE dans urllib3
- `pyyaml==5.3.1` - CVE-2020-14343, CVE-2020-1747
- `urllib3==1.26.4` - CVE-2021-33503
- `jinja2==2.11.3` - CVE-2020-28493
- `cryptography==3.3.2` - Plusieurs CVE

### 4. Checkov IaC Findings

**Kubernetes (deployment.yaml)**:
- CKV_K8S_8: Liveness probe not defined
- CKV_K8S_9: Readiness probe not defined
- CKV_K8S_10: CPU requests not defined
- CKV_K8S_11: CPU limits not defined
- CKV_K8S_12: Memory requests not defined
- CKV_K8S_13: Memory limits not defined
- CKV_K8S_14: Image tag not specified (uses :latest)
- CKV_K8S_20-30: Security context not defined (runAsNonRoot, capabilities, etc.)

**Terraform (main.tf)**:
- CKV_AWS_23: Security group allows ingress from 0.0.0.0/0
- CKV_AWS_19: S3 bucket encryption not enabled
- CKV_AWS_21: S3 bucket versioning not enabled

### 5. Trivy Container Findings

**Dockerfile**:
- Base image `python:3.9-slim` contient des CVE connus
- Dépendances vulnérables dans requirements.txt
- Pas d'utilisateur non-root
- Pas de HEALTHCHECK

## Installation et Utilisation

### Prérequis
- Git
- Docker
- Compte GitHub (pour Actions)
- Python 3.9+ (pour tests locaux)

### Installation Locale

```bash
# Cloner le repository
git clone <your-repo-url>
cd devsecops-pipeline-demo

# Créer un environnement virtuel Python
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate  # Windows

# Installer les dépendances (ATTENTION: contient des CVE)
pip install -r app/requirements.txt

# Lancer l'application (pour test uniquement)
python app/main.py
```

### Exécution des Outils en Local

#### GitLeaks
```bash
# Installer GitLeaks
brew install gitleaks  # Mac
# ou télécharger depuis https://github.com/gitleaks/gitleaks/releases

# Exécuter le scan
gitleaks detect --source . --report-format json --report-path gitleaks-report.json
```

#### Semgrep
```bash
# Installer Semgrep
pip install semgrep

# Exécuter le scan
semgrep --config=auto --json --output=semgrep-results.json
```

#### pip-audit
```bash
# Installer pip-audit
pip install pip-audit

# Exécuter le scan
pip-audit --requirement app/requirements.txt
```

#### Checkov
```bash
# Installer Checkov
pip install checkov

# Scanner Kubernetes
checkov --directory kubernetes/

# Scanner Terraform
checkov --directory terraform/

# Scanner Dockerfile
checkov --file Dockerfile
```

#### Trivy
```bash
# Installer Trivy
brew install trivy  # Mac
# ou télécharger depuis https://github.com/aquasecurity/trivy/releases

# Builder l'image
docker build -t devsecops-demo:latest .

# Scanner l'image
trivy image devsecops-demo:latest

# Scanner le filesystem
trivy fs .
```

### Exécution du Pipeline GitHub Actions

1. Pusher le code sur GitHub:
```bash
git init
git add .
git commit -m "Initial commit - DevSecOps demo project"
git branch -M main
git remote add origin <your-repo-url>
git push -u origin main
```

2. Le pipeline se déclenche automatiquement sur:
   - Push vers `main` ou `develop`
   - Pull request vers `main`
   - Déclenchement manuel via l'interface GitHub Actions

3. Consulter les résultats:
   - Aller dans l'onglet "Actions" de votre repository GitHub
   - Cliquer sur le dernier workflow run
   - Télécharger les artifacts pour voir les rapports détaillés

## Résultats du Pipeline

### Artifacts Générés

Après l'exécution du pipeline, les artifacts suivants sont disponibles:

1. **gitleaks-report**: Secrets détectés
2. **semgrep-report**: Vulnérabilités SAST
3. **pip-audit-report**: CVE dans les dépendances
4. **checkov-report**: Misconfigurations IaC
5. **trivy-report**: Vulnérabilités container
6. **all-security-reports**: Tous les rapports combinés

### Format des Rapports

Chaque outil génère plusieurs formats:
- JSON (pour automatisation)
- SARIF (pour intégration GitHub Security)
- CLI (pour lecture humaine)

## Métriques du Pipeline

### Performance
- **Jobs parallèles**: 5
- **Temps total**: ~4-5 minutes
- **Coût GitHub Actions**: ~5 minutes de compute time

### Couverture de Sécurité
- **Secrets**: ✅ GitLeaks
- **Code source**: ✅ Semgrep SAST
- **Dépendances**: ✅ pip-audit
- **Infrastructure**: ✅ Checkov
- **Container**: ✅ Trivy
- **Runtime**: ❌ (Non inclus dans cette demo)

## Utilisation Académique

Ce projet est conçu pour un mémoire académique démontrant:

1. **Implémentation DevSecOps**: Intégration de la sécurité dans le CI/CD
2. **Shift-Left Security**: Détection précoce des vulnérabilités
3. **Automatisation**: Pipeline entièrement automatisé
4. **Outils Open Source**: Tous les outils sont gratuits et open source
5. **Mesures quantifiables**: Métriques précises sur les findings

### Résultats pour le Mémoire

```
Statistiques de sécurité détectées automatiquement:
├── Total findings: 23+
├── Secrets exposés: 1
├── Vulnérabilités code: 3
├── CVE dépendances: 6+
├── Misconfigurations IaC: 11
└── CVE containers: 2+

Temps d'exécution: 4-5 minutes
Niveau d'automatisation: 100%
Coût: Gratuit (GitHub Actions free tier)
```

## Améliorations Possibles

### Corrections des Vulnérabilités

Pour corriger les vulnérabilités (exercice):

1. **Secrets**: Utiliser GitHub Secrets, Azure Key Vault, AWS Secrets Manager
2. **SQL Injection**: Utiliser des requêtes paramétrées
3. **MD5**: Utiliser bcrypt, argon2, ou PBKDF2
4. **SSRF**: Valider et sanitiser les URLs, utiliser une allowlist
5. **Dépendances**: Mettre à jour vers les dernières versions sécurisées
6. **Kubernetes**: Ajouter securityContext, limits, probes
7. **Terraform**: Restreindre les Security Groups, activer encryption
8. **Docker**: Utiliser un USER non-root, ajouter HEALTHCHECK

### Outils Additionnels

Pour étendre le pipeline:
- **DAST**: OWASP ZAP, Burp Suite
- **SCA**: Snyk, WhiteSource
- **Container Runtime**: Falco, Sysdig
- **IAST**: Contrast Security
- **Secrets Management**: HashiCorp Vault

## Références

### Documentation des Outils
- [GitLeaks](https://github.com/gitleaks/gitleaks)
- [Semgrep](https://semgrep.dev/)
- [pip-audit](https://github.com/pypa/pip-audit)
- [Checkov](https://www.checkov.io/)
- [Trivy](https://aquasecurity.github.io/trivy/)

### Standards de Sécurité
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)

## Licence

Ce projet est destiné uniquement à des fins éducatives.
Ne pas utiliser en production.

## Contact

Pour questions sur le mémoire ou le projet: [Votre contact]

---

**Rappel Important**: Ce projet contient des vulnérabilités intentionnelles. Ne jamais déployer ce code dans un environnement de production ou accessible publiquement.
