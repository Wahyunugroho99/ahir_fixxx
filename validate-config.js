#!/usr/bin/env node

/**
 * Configuration Validator for n8n Video Summarizer Workflow
 * Validates the workflow JSON and configuration files
 */

const fs = require('fs');
const path = require('path');

// Color codes for console output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  bold: '\x1b[1m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function validateWorkflowJSON() {
  log('\n🔍 Validating n8n-workflow.json...', 'blue');
  
  try {
    const workflowPath = path.join(__dirname, 'n8n-workflow.json');
    const workflowContent = fs.readFileSync(workflowPath, 'utf8');
    const workflow = JSON.parse(workflowContent);
    
    // Check required properties
    const requiredProps = ['name', 'nodes', 'connections'];
    const missingProps = requiredProps.filter(prop => !workflow.hasOwnProperty(prop));
    
    if (missingProps.length > 0) {
      log(`❌ Missing required properties: ${missingProps.join(', ')}`, 'red');
      return false;
    }
    
    // Check nodes
    if (!Array.isArray(workflow.nodes) || workflow.nodes.length === 0) {
      log('❌ Workflow must contain at least one node', 'red');
      return false;
    }
    
    log(`✅ Found ${workflow.nodes.length} nodes`, 'green');
    
    // Validate critical nodes
    const requiredNodes = [
      'n8n-nodes-base.googleDrive',
      'n8n-nodes-base.openAi', 
      'n8n-nodes-base.telegram',
      'n8n-nodes-base.webhook'
    ];
    
    const foundNodeTypes = workflow.nodes.map(node => node.type);
    const missingNodeTypes = requiredNodes.filter(type => !foundNodeTypes.includes(type));
    
    if (missingNodeTypes.length > 0) {
      log(`❌ Missing required node types: ${missingNodeTypes.join(', ')}`, 'red');
      return false;
    }
    
    log('✅ All required node types found', 'green');
    
    // Check credentials placeholders
    const credentialPlaceholders = [
      'your-google-api-credentials-id',
      'your-openai-credentials-id',
      'your-telegram-bot-credentials-id'
    ];
    
    let hasPlaceholders = false;
    workflow.nodes.forEach(node => {
      if (node.credentials) {
        Object.values(node.credentials).forEach(cred => {
          if (credentialPlaceholders.includes(cred.id)) {
            hasPlaceholders = true;
          }
        });
      }
    });
    
    if (hasPlaceholders) {
      log('⚠️  Found credential placeholders - remember to update with actual IDs', 'yellow');
    }
    
    return true;
  } catch (error) {
    log(`❌ Error validating workflow: ${error.message}`, 'red');
    return false;
  }
}

function validateConfigJSON() {
  log('\n🔍 Validating config-example.json...', 'blue');
  
  try {
    const configPath = path.join(__dirname, 'config-example.json');
    const configContent = fs.readFileSync(configPath, 'utf8');
    const config = JSON.parse(configContent);
    
    // Check main sections
    const requiredSections = ['workflowConfig', 'credentials', 'parameters'];
    const missingSections = requiredSections.filter(section => !config.hasOwnProperty(section));
    
    if (missingSections.length > 0) {
      log(`❌ Missing config sections: ${missingSections.join(', ')}`, 'red');
      return false;
    }
    
    log('✅ All required config sections found', 'green');
    
    // Check credential configurations
    const requiredCredentials = ['google', 'openai', 'telegram'];
    const missingCredentials = requiredCredentials.filter(cred => !config.credentials.hasOwnProperty(cred));
    
    if (missingCredentials.length > 0) {
      log(`❌ Missing credential configs: ${missingCredentials.join(', ')}`, 'red');
      return false;
    }
    
    log('✅ All credential configurations found', 'green');
    
    // Check for placeholder values
    const placeholderValues = [
      'REPLACE_WITH_YOUR_FOLDER_ID',
      'REPLACE_WITH_YOUR_CHAT_ID',
      'your-google-drive-folder-id',
      'your-telegram-chat-id'
    ];
    
    let hasConfigPlaceholders = false;
    function checkPlaceholders(obj, path = '') {
      for (const [key, value] of Object.entries(obj)) {
        if (typeof value === 'string' && placeholderValues.includes(value)) {
          hasConfigPlaceholders = true;
          log(`⚠️  Placeholder found at ${path}.${key}: ${value}`, 'yellow');
        } else if (typeof value === 'object' && value !== null) {
          checkPlaceholders(value, path ? `${path}.${key}` : key);
        }
      }
    }
    
    checkPlaceholders(config);
    
    if (hasConfigPlaceholders) {
      log('⚠️  Remember to replace placeholder values with actual configuration', 'yellow');
    }
    
    return true;
  } catch (error) {
    log(`❌ Error validating config: ${error.message}`, 'red');
    return false;
  }
}

function validateDockerCompose() {
  log('\n🔍 Validating docker-compose.yml...', 'blue');
  
  try {
    const dockerPath = path.join(__dirname, 'docker-compose.yml');
    const dockerContent = fs.readFileSync(dockerPath, 'utf8');
    
    // Basic YAML structure checks
    if (!dockerContent.includes('version:')) {
      log('❌ Missing version specification', 'red');
      return false;
    }
    
    if (!dockerContent.includes('services:')) {
      log('❌ Missing services section', 'red');
      return false;
    }
    
    // Check for required services
    const requiredServices = ['n8n', 'postgres', 'nginx'];
    const missingServices = requiredServices.filter(service => !dockerContent.includes(`${service}:`));
    
    if (missingServices.length > 0) {
      log(`❌ Missing services: ${missingServices.join(', ')}`, 'red');
      return false;
    }
    
    log('✅ All required services found', 'green');
    
    // Check for security placeholders
    const securityPlaceholders = [
      'your_secure_password',
      'your-domain.com',
      'your_redis_password'
    ];
    
    let hasSecurityPlaceholders = false;
    securityPlaceholders.forEach(placeholder => {
      if (dockerContent.includes(placeholder)) {
        hasSecurityPlaceholders = true;
      }
    });
    
    if (hasSecurityPlaceholders) {
      log('⚠️  Security placeholders found - update passwords and domain names', 'yellow');
    }
    
    return true;
  } catch (error) {
    log(`❌ Error validating Docker Compose: ${error.message}`, 'red');
    return false;
  }
}

function validateTestScript() {
  log('\n🔍 Validating test-webhook.sh...', 'blue');
  
  try {
    const testPath = path.join(__dirname, 'test-webhook.sh');
    const testContent = fs.readFileSync(testPath, 'utf8');
    
    // Check for executable permissions
    const stats = fs.statSync(testPath);
    const isExecutable = (stats.mode & parseInt('111', 8)) !== 0;
    
    if (!isExecutable) {
      log('⚠️  Test script is not executable. Run: chmod +x test-webhook.sh', 'yellow');
    } else {
      log('✅ Test script has executable permissions', 'green');
    }
    
    // Check for required configurations
    if (testContent.includes('your-n8n-instance.com')) {
      log('⚠️  Remember to update N8N_WEBHOOK_URL in test script', 'yellow');
    }
    
    if (testContent.includes('your-google-drive-folder-id')) {
      log('⚠️  Remember to update GOOGLE_DRIVE_FOLDER_ID in test script', 'yellow');
    }
    
    return true;
  } catch (error) {
    log(`❌ Error validating test script: ${error.message}`, 'red');
    return false;
  }
}

function main() {
  log('🚀 n8n Video Summarizer Workflow Validator', 'bold');
  log('==========================================\n');
  
  let allValid = true;
  
  allValid &= validateWorkflowJSON();
  allValid &= validateConfigJSON();
  allValid &= validateDockerCompose();
  allValid &= validateTestScript();
  
  log('\n📋 Validation Summary:', 'bold');
  if (allValid) {
    log('✅ All validations passed! Workflow is ready for deployment.', 'green');
    log('\n📝 Next Steps:', 'blue');
    log('1. Update credential IDs in n8n-workflow.json');
    log('2. Replace placeholder values in config files');
    log('3. Configure actual API keys and tokens');
    log('4. Test with a small video folder first');
  } else {
    log('❌ Some validations failed. Please fix the issues above.', 'red');
  }
}

// Run validation if script is called directly
if (require.main === module) {
  main();
}

module.exports = {
  validateWorkflowJSON,
  validateConfigJSON,
  validateDockerCompose,
  validateTestScript
};