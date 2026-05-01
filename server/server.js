const express = require('express');
const path = require('path');
const os = require('os');

const app = express();
const PORT = 3000;
const HOST = '0.0.0.0';

app.use(express.static(path.join(__dirname, 'public')));

function getLocalIP() {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            if (iface.family === 'IPv4' && !iface.internal) {
                return iface.address;
            }
        }
    }
    return '127.0.0.1';
}

app.listen(PORT, HOST, () => {
    const ip = getLocalIP();
    console.log(`==========================================`);
    console.log(` Ludo by AnA Devyra Server is running!`);
    console.log(` Access on local network: http://${ip}:${PORT}`);
    console.log(`==========================================`);
});
