# Environment Variables Setup Guide

Your Vertex AI configuration now uses environment variables for security! 🔒

## Quick Setup

### 1. Create your .env file
```bash
cp .env.example .env
```

### 2. Edit .env with your actual values
```bash
# Open .env in your editor
code .env  # VS Code
# or
nano .env  # Terminal editor
```

### 3. Update the required values

**Minimum required:**
```env
VERTEX_AI_PROJECT_ID=your-actual-gcp-project-id
VERTEX_AI_SERVICE_ACCOUNT_KEY={"your":"actual","service":"account","json":"here"}
```

**Full configuration example:**
```env
# Google Cloud Project Configuration
VERTEX_AI_PROJECT_ID=my-gcp-project-123
VERTEX_AI_LOCATION=us-central1
VERTEX_AI_MODEL=claude-3-5-sonnet@20241022

# Service Account (paste entire JSON as single line)
VERTEX_AI_SERVICE_ACCOUNT_KEY={"type":"service_account","project_id":"my-gcp-project-123","private_key_id":"abc123","private_key":"-----BEGIN PRIVATE KEY-----\nMIIEvQIB...your-key-here...\n-----END PRIVATE KEY-----\n","client_email":"hushh-pda@my-gcp-project-123.iam.gserviceaccount.com","client_id":"123456789","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"https://www.googleapis.com/robot/v1/metadata/x509/hushh-pda%40my-gcp-project-123.iam.gserviceaccount.com"}

# Optional: Custom Claude settings
VERTEX_AI_MAX_TOKENS=2048
VERTEX_AI_TEMPERATURE=0.8
```

## Security Features ✅

### What's Secure Now:
- ✅ No hardcoded credentials in source code
- ✅ .env files are gitignored automatically
- ✅ Configuration validation at runtime
- ✅ Safe defaults if .env is missing
- ✅ Separate configs for dev/staging/prod

### What You Need to Do:
1. **Never commit .env files** (already protected)
2. **Use different .env files per environment**
3. **Rotate service account keys regularly**
4. **Use GCP IAM for production secrets**

## Different Environments

### Development (.env)
```env
VERTEX_AI_PROJECT_ID=my-dev-project
VERTEX_AI_LOCATION=us-central1
```

### Staging (.env.staging)  
```env
VERTEX_AI_PROJECT_ID=my-staging-project
VERTEX_AI_LOCATION=us-central1
```

### Production
Use your CI/CD to inject environment variables, not .env files!

## Troubleshooting

### App won't start?
**Check your .env file:**
```bash
# Verify file exists
ls -la .env

# Check content (don't share this output!)
cat .env
```

### "Not properly configured" error?
1. Ensure `VERTEX_AI_PROJECT_ID` is not empty
2. Ensure `VERTEX_AI_SERVICE_ACCOUNT_KEY` is valid JSON
3. Check the service account has proper permissions

### Test configuration:
Add this to your debug code:
```dart
import 'package:hushh_user_app/features/pda/data/config/vertex_ai_config.dart';

// In your debug/test function:
print('Config status: ${VertexAiConfig.debugInfo}');
```

## Service Account JSON Tips

### ⚠️ Common Issues:

1. **Multi-line JSON**: Paste as single line in .env
   ```env
   # ❌ Wrong (multi-line)
   VERTEX_AI_SERVICE_ACCOUNT_KEY={
     "type": "service_account",
     ...
   }
   
   # ✅ Correct (single line)
   VERTEX_AI_SERVICE_ACCOUNT_KEY={"type":"service_account",...}
   ```

2. **Escape sequences**: Private key newlines should be `\n`
   ```env
   "private_key":"-----BEGIN PRIVATE KEY-----\nYOUR_KEY_HERE\n-----END PRIVATE KEY-----\n"
   ```

3. **No quotes around the entire value**:
   ```env
   # ❌ Wrong
   VERTEX_AI_SERVICE_ACCOUNT_KEY="{"type":"service_account"}"
   
   # ✅ Correct  
   VERTEX_AI_SERVICE_ACCOUNT_KEY={"type":"service_account"}
   ```

## Production Deployment

### Don't use .env files in production!

**Instead, use:**
- **Google Cloud Run**: Environment variables in YAML
- **Kubernetes**: ConfigMaps/Secrets
- **Firebase**: Environment config
- **CI/CD**: Encrypted secrets

### Example for Cloud Run:
```yaml
apiVersion: serving.knative.dev/v1
kind: Service
spec:
  template:
    spec:
      containers:
      - image: gcr.io/PROJECT/hushh-app
        env:
        - name: VERTEX_AI_PROJECT_ID
          value: "production-project-id"
        - name: VERTEX_AI_SERVICE_ACCOUNT_KEY
          valueFrom:
            secretKeyRef:
              name: vertex-ai-key
              key: service-account-json
```

## Need Help?

1. **Missing .env?** App will use defaults and show warnings
2. **Invalid JSON?** Check service account key format
3. **Permission errors?** Verify GCP IAM roles
4. **Still stuck?** Check `VERTEX_AI_SETUP.md` for full GCP setup

Your secrets are now secure! 🔐
