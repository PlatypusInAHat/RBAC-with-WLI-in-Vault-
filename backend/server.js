const express = require('express');
const cors = require('cors');
const fs = require('fs');
const { Client } = require('pg');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Kubernetes service account info
const NAMESPACE_PATH = '/var/run/secrets/kubernetes.io/serviceaccount/namespace';
const TOKEN_PATH = '/var/run/secrets/kubernetes.io/serviceaccount/token';
const CA_CERT_PATH = '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt';

// Helper function to read file safely
function readFileSafe(path) {
  try {
    return fs.readFileSync(path, 'utf8').trim();
  } catch (error) {
    return null;
  }
}

// Helper function to read Vault secrets
function readVaultSecrets() {
  const secrets = {};
  const vaultPath = '/vault/secrets';
  
  try {
    if (fs.existsSync(vaultPath)) {
      const files = fs.readdirSync(vaultPath);
      files.forEach(file => {
        const content = fs.readFileSync(`${vaultPath}/${file}`, 'utf8');
        secrets[file] = content.substring(0, 100) + '...'; // Truncate for security
      });
    }
  } catch (error) {
    console.error('Error reading Vault secrets:', error.message);
  }
  
  return secrets;
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// Service info endpoint - shows K8s workload identity
app.get('/api/info', (req, res) => {
  const namespace = readFileSafe(NAMESPACE_PATH);
  const hasToken = fs.existsSync(TOKEN_PATH);
  const hasCACert = fs.existsSync(CA_CERT_PATH);
  
  res.json({
    podName: process.env.HOSTNAME || 'unknown',
    namespace: namespace || 'unknown',
    serviceAccount: process.env.SERVICE_ACCOUNT || 'unknown',
    nodeEnv: process.env.NODE_ENV || 'development',
    workloadIdentity: {
      hasServiceAccountToken: hasToken,
      hasCACertificate: hasCACert,
      namespace: namespace
    },
    environment: {
      dbHost: process.env.DB_HOST || 'not-set',
      dbName: process.env.DB_NAME || 'not-set',
      port: PORT
    }
  });
});

// RBAC check endpoint - demonstrates RBAC permissions
app.get('/api/rbac', (req, res) => {
  const namespace = readFileSafe(NAMESPACE_PATH);
  const hasToken = fs.existsSync(TOKEN_PATH);
  
  res.json({
    serviceAccount: {
      name: 'prj-backend-sa',
      namespace: namespace || 'prj',
      hasToken: hasToken
    },
    rbacPermissions: {
      canReadSecrets: true, // Backend has secret-reader role
      canReadConfigMaps: true, // Backend has configmap-reader role
      canReadPods: true, // Backend has pod-reader role
      canListServices: false // Not granted
    },
    roles: [
      'secret-reader',
      'configmap-reader', 
      'pod-reader'
    ],
    clusterRoles: [
      'system:auth-delegator-prj'
    ]
  });
});

// Secrets endpoint - demonstrates access to K8s secrets and Vault
app.get('/api/secrets', (req, res) => {
  const vaultSecrets = readVaultSecrets();
  
  res.json({
    kubernetesSecrets: {
      dbUser: process.env.DB_USER ? '***' : 'not-set',
      dbPassword: process.env.DB_PASSWORD ? '***' : 'not-set',
      jwtSecret: process.env.JWT_SECRET ? '***' : 'not-set',
      apiKey: process.env.API_KEY ? '***' : 'not-set'
    },
    vaultSecrets: {
      available: Object.keys(vaultSecrets).length > 0,
      files: Object.keys(vaultSecrets),
      note: 'Secrets are injected by Vault Agent'
    },
    sharedSecrets: {
      encryptionKey: process.env.ENCRYPTION_KEY ? '***' : 'not-set',
      sessionSecret: process.env.SESSION_SECRET ? '***' : 'not-set',
      note: 'Shared between backend and frontend via Vault'
    }
  });
});

// Vault integration endpoint
app.get('/api/vault', (req, res) => {
  const vaultSecrets = readVaultSecrets();
  const hasVaultAnnotations = true; // Based on deployment config
  
  res.json({
    vaultAgent: {
      injected: Object.keys(vaultSecrets).length > 0,
      role: 'prj-backend',
      secretsPath: '/vault/secrets',
      files: Object.keys(vaultSecrets)
    },
    workloadIdentity: {
      enabled: hasVaultAnnotations,
      authMethod: 'kubernetes',
      serviceAccount: 'prj-backend-sa'
    },
    secretSharing: {
      enabled: true,
      sharedWith: ['prj-frontend'],
      sharedSecrets: ['encryption_key', 'session_secret']
    }
  });
});

// Database connection test
app.get('/api/database', async (req, res) => {
  const client = new Client({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  });

  try {
    await client.connect();
    const result = await client.query('SELECT NOW() as current_time, version() as version');
    await client.end();
    
    res.json({
      status: 'connected',
      database: process.env.DB_NAME,
      host: process.env.DB_HOST,
      currentTime: result.rows[0].current_time,
      version: result.rows[0].version.split(' ')[0] + ' ' + result.rows[0].version.split(' ')[1]
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message,
      database: process.env.DB_NAME,
      host: process.env.DB_HOST
    });
  }
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'K8s Demo Backend - RBAC & Workload Identity',
    endpoints: [
      'GET /health - Health check',
      'GET /api/info - Service and workload identity info',
      'GET /api/rbac - RBAC permissions check',
      'GET /api/secrets - Secrets access demo',
      'GET /api/vault - Vault integration status',
      'GET /api/database - Database connection test'
    ]
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Backend server running on port ${PORT}`);
  console.log(`📦 Pod: ${process.env.HOSTNAME || 'unknown'}`);
  console.log(`🔐 Namespace: ${readFileSafe(NAMESPACE_PATH) || 'unknown'}`);
});
