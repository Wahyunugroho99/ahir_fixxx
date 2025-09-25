# N8N Video Summarizer Workflow - Setup Guide

## Overview
This n8n workflow automatically:
1. Scans Google Drive folders for video files
2. Extracts metadata and generates AI-powered summaries
3. Creates a professional PDF report
4. Sends the report via Telegram

## Prerequisites

### Required Services
1. **n8n instance** (self-hosted or cloud)
2. **Google Drive API** access
3. **OpenAI API** key
4. **Telegram Bot** token
5. **FFmpeg** installed on n8n server

### Required Credentials in n8n

#### 1. Google API Credentials
- Go to Google Cloud Console
- Enable Google Drive API
- Create service account credentials
- Download JSON key file
- In n8n: Add new credential → Google Service Account
- Upload the JSON key file

#### 2. OpenAI API Credentials
- Get API key from OpenAI platform
- In n8n: Add new credential → OpenAI
- Enter your API key

#### 3. Telegram Bot Credentials
- Create bot with @BotFather on Telegram
- Get bot token
- Get your chat ID (send message to bot, check webhook)
- In n8n: Add new credential → Telegram
- Enter bot token

## Installation Steps

### 1. Import Workflow
1. Copy the content of `n8n-workflow.json`
2. In n8n interface: Settings → Import from JSON
3. Paste the workflow JSON and import

### 2. Configure Credentials
Update these credential IDs in the workflow:
- `your-google-api-credentials-id` → Your Google Service Account credential ID
- `your-openai-credentials-id` → Your OpenAI API credential ID  
- `your-telegram-bot-credentials-id` → Your Telegram Bot credential ID

### 3. Set Required Parameters
Replace these placeholders:
- `your-google-drive-folder-id` → Target Google Drive folder ID
- `your-telegram-chat-id` → Your Telegram chat ID
- `your-n8n-instance-id` → Your n8n instance ID

### 4. Install FFmpeg (if not already installed)
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install ffmpeg

# CentOS/RHEL  
sudo yum install ffmpeg

# Docker n8n
docker exec -it n8n-container bash
apt update && apt install ffmpeg
```

## Usage

### Method 1: Webhook Trigger
Send POST request to webhook URL:
```bash
curl -X POST "https://your-n8n-instance.com/webhook/video-summarizer-webhook" \
  -H "Content-Type: application/json" \
  -d '{
    "folderId": "your-google-drive-folder-id",
    "telegramChatId": "your-telegram-chat-id"
  }'
```

### Method 2: Manual Execution
1. Open workflow in n8n
2. Set input parameters in "Workflow Input" node
3. Click "Execute Workflow"

## Configuration Options

### Video Processing
- **Supported formats**: MP4, AVI, MOV, MKV, WMV
- **Metadata extraction**: Duration, resolution, format, file size
- **Thumbnail generation**: 320x240 preview images

### AI Summary Configuration
Modify the OpenAI prompt in "Generate Video Summary with AI" node to customize:
- Summary length
- Focus areas (technical specs, content analysis, etc.)
- Output format

### PDF Styling
Customize the HTML template in "Generate PDF Report" node:
- Colors and fonts
- Layout structure  
- Additional metadata fields

### Telegram Integration
- Supports file attachments up to 50MB
- HTML formatting for messages
- Custom captions and filenames

## Troubleshooting

### Common Issues

1. **Google Drive API Errors**
   - Verify service account has access to target folder
   - Check API quotas and limits
   - Ensure Drive API is enabled

2. **Video Processing Failures**
   - Confirm FFmpeg installation
   - Check file format compatibility
   - Verify sufficient disk space

3. **PDF Generation Problems**
   - Large number of videos may cause memory issues
   - Consider batching for folders with 50+ videos
   - Increase n8n memory limits if needed

4. **Telegram Delivery Issues**
   - Check bot permissions in target chat
   - Verify chat ID format
   - File size must be under 50MB

### Performance Optimization

- **Large folders**: Process in batches to avoid timeouts
- **File size**: Consider video compression for faster processing
- **Concurrent processing**: Adjust n8n execution settings

## Security Considerations

- Store all API keys securely in n8n credentials
- Use service accounts with minimal required permissions
- Regularly rotate API keys and tokens
- Monitor workflow execution logs

## Monitoring & Maintenance

### Workflow Monitoring
- Set up email notifications for failures
- Monitor execution logs regularly
- Track API usage and costs

### Regular Maintenance
- Update AI model versions periodically
- Review and optimize prompts
- Clean up temporary files
- Update credentials before expiration

## Customization Examples

### Adding Video Content Analysis
```javascript
// In OpenAI node, enhance the prompt:
"Analyze this video and provide insights on:
1. Estimated content type (educational, entertainment, etc.)
2. Audio quality indicators
3. Video quality assessment
4. Potential use cases"
```

### Custom PDF Branding
```html
<!-- Add company logo to PDF template -->
<div class="header">
    <img src="data:image/png;base64,YOUR_LOGO_BASE64" alt="Logo" style="height: 50px;">
    <h1>Your Company - Video Summary Report</h1>
</div>
```

### Batch Processing Configuration
```javascript
// Process videos in batches of 10
{
  "batchSize": 10,
  "processInterval": "5m",
  "maxConcurrentProcessing": 3
}
```

## Support

For issues and questions:
1. Check n8n community forums
2. Review API documentation for integrated services
3. Monitor workflow execution logs
4. Test with small folders first

## License
This workflow configuration is provided under MIT License.