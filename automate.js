const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

// --- CONFIGURATION ---
const FLUTTER_PATH = 'C:\\src\\flutter\\bin\\flutter.bat';
const APP_DIR = path.join(__dirname, 'ludo_app');
const SERVER_DIR = path.join(__dirname, 'server');
const APK_SOURCE = path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk');
const APK_DEST = path.join(__dirname, 'app-release.apk');
const PORT = 4000;

// --- UTILS ---
function log(msg) {
  console.log(`\x1b[36m[AURA PIPELINE]\x1b[0m ${msg}`);
}

function getLocalIP() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost';
}

// --- PIPELINE STEPS ---

async function run() {
  try {
    // 1. Build APK
    log('Starting Flutter Build (Release APK)...');
    execSync(`"${FLUTTER_PATH}" pub get`, { cwd: APP_DIR, stdio: 'inherit' });
    execSync(`"${FLUTTER_PATH}" build apk --release`, { cwd: APP_DIR, stdio: 'inherit' });

    // 2. Copy APK to Server
    log('Copying APK to server/public...');
    if (fs.existsSync(APK_SOURCE)) {
      fs.copyFileSync(APK_SOURCE, APK_DEST);
      log('APK copied successfully.');
    } else {
      throw new Error('APK build failed: Source file not found.');
    }

    // 3. Start Server
    log('Installing server dependencies...');
    execSync('npm install', { cwd: SERVER_DIR, stdio: 'inherit' });

    log('Launching local server...');
    const localIP = getLocalIP();
    
    const serverProcess = spawn('node', ['server.js'], { 
      cwd: SERVER_DIR,
      stdio: 'inherit',
      detached: false
    });

    log('--- PIPELINE COMPLETE ---');
    console.log(`\n\x1b[32m🚀 Local Dashboard: http://${localIP}:${PORT}\x1b[0m`);
    console.log(`\x1b[32m📦 APK Download:   http://${localIP}:${PORT}/app-release.apk\x1b[0m\n`);
    log('Press Ctrl+C to stop the server.');

  } catch (error) {
    console.error(`\x1b[31m[ERROR]\x1b[0m ${error.message}`);
    process.exit(1);
  }
}

run();
