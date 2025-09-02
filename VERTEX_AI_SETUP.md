# Vertex AI with Claude Sonnet 4 Setup Guide

This guide explains how to configure Google Cloud Vertex AI with Claude Sonnet 4 for your Hushh PDA feature.

## Prerequisites

1. **Google Cloud Project**: You need an active GCP project with billing enabled
2. **Vertex AI API**: Enable the Vertex AI API in your project
3. **Service Account**: Create a service account with proper permissions
4. **Claude Model Access**: Ensure you have access to Claude models in Vertex AI

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select an existing one
3. Note your **Project ID** - you'll need this later

## Step 2: Enable Required APIs

Enable these APIs in your project:
```bash
gcloud services enable aiplatform.googleapis.com
gcloud services enable compute.googleapis.com
```

Or via the Console:
- Go to **APIs & Services > Library**
- Search for and enable:
  - Vertex AI API
  - Compute Engine API

## Step 3: Create Service Account

1. Go to **IAM & Admin > Service Accounts**
2. Click **Create Service Account**
3. Name: `hushh-pda-vertex-ai`
4. Description: `Service account for Hushh PDA Vertex AI integration`
5. Grant these roles:
   - `Vertex AI User` 
   - `AI Platform Developer`
6. Click **Done**

## Step 4: Generate Service Account Key

1. Click on your newly created service account
2. Go to **Keys** tab
3. Click **Add Key > Create new key**
4. Choose **JSON** format
5. Download the JSON file
6. **Keep this file secure!**

## Step 5: Configure the Application

1. Open `lib/features/pda/data/config/vertex_ai_config.dart`
2. Replace the following values:

```dart
class VertexAiConfig {
  // Replace with your actual project ID
  static const String projectId = 'your-actual-project-id';
  
  // Choose your preferred region (where Claude is available)
  static const String location = 'us-central1'; // or us-east1, europe-west1, etc.
  
  // Replace with the contents of your service account JSON file
  static const String serviceAccountKey = '''
{
  "type": "service_account",
  "project_id": "your-actual-project-id",
  "private_key_id": "actual-private-key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nACTUAL_PRIVATE_KEY_CONTENT\\n-----END PRIVATE KEY-----\\n",
  "client_email": "hushh-pda-vertex-ai@your-actual-project-id.iam.gserviceaccount.com",
  "client_id": "actual-client-id",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/hushh-pda-vertex-ai%40your-actual-project-id.iam.gserviceaccount.com"
}
''';
}
```

## Step 6: Request Claude Model Access

Claude models in Vertex AI require special access:

1. Go to **Vertex AI > Model Garden**
2. Search for "Claude"
3. Request access to Claude 3.5 Sonnet
4. Wait for approval (usually 1-2 business days)

## Step 7: Test the Configuration

1. Build and run your Flutter app
2. Navigate to the PDA feature
3. Send a test message
4. Check logs for any authentication or API errors

## Security Best Practices

### 🚨 IMPORTANT SECURITY NOTES:

1. **Never commit service account keys to version control**
2. **Use environment variables in production**
3. **Rotate service account keys regularly**
4. **Use IAM conditions to restrict access**

### Production Configuration

For production, consider using:

```dart
// Use environment variables instead of hardcoded values
static String get projectId => 
    const String.fromEnvironment('GCP_PROJECT_ID', defaultValue: 'your-project-id');

static String get serviceAccountKey => 
    const String.fromEnvironment('GCP_SERVICE_ACCOUNT_KEY', defaultValue: '');
```

## Regional Availability

Claude models are available in these regions:
- `us-central1` (Iowa)
- `us-east1` (South Carolina)  
- `europe-west1` (Belgium)
- `asia-southeast1` (Singapore)

Choose the region closest to your users for better latency.

## Troubleshooting

### Common Issues:

1. **Authentication Error**: Check service account permissions
2. **Model Not Found**: Ensure you have access to Claude models
3. **Quota Exceeded**: Check your Vertex AI quotas
4. **Region Error**: Verify Claude is available in your selected region

### Debug Steps:

1. Enable detailed logging in your app
2. Check Cloud Logging in GCP Console
3. Verify API quotas in GCP Console
4. Test with Google Cloud SDK locally

## Cost Considerations

- Claude Sonnet 4 charges per token (input + output)
- Monitor usage in **Vertex AI > Endpoints** 
- Set up billing alerts
- Consider caching responses for common queries

## Next Steps

Once configured:
1. Test thoroughly in development
2. Monitor costs and usage
3. Optimize prompts for better responses
4. Consider implementing response caching
5. Set up monitoring and alerting

For more details, see the [Vertex AI documentation](https://cloud.google.com/vertex-ai/docs).
