#!/bin/bash

# ===========================================
# 📝 EDIT THESE TWILIO CREDENTIALS
# ===========================================
ACCOUNT_SID="YOURS HERE"
AUTH_TOKEN="YOURS HERE"
# ===========================================

echo "
========================================
🔄 Starting Socat UDP Forwarding Setup...
========================================
"

# Overwrite Twilio credentials in .bashrc
echo "
----------------------------------------
🔑 Overwriting persistent Twilio credentials...
----------------------------------------"
# Remove any existing Twilio credentials
sed -i '/export TWILIO_ACCOUNT_SID=/d' ~/.bashrc
sed -i '/export TWILIO_AUTH_TOKEN=/d' ~/.bashrc

# Add fresh Twilio credentials to .bashrc
echo "export TWILIO_ACCOUNT_SID=$ACCOUNT_SID" >> ~/.bashrc
echo "export TWILIO_AUTH_TOKEN=$AUTH_TOKEN" >> ~/.bashrc
echo "✅ Overwritten Twilio credentials in ~/.bashrc"

# Export for current session
export TWILIO_ACCOUNT_SID=$ACCOUNT_SID
export TWILIO_AUTH_TOKEN=$AUTH_TOKEN
echo "✅ Twilio credentials exported for current session:"
echo "🆔 ACCOUNT_SID: $TWILIO_ACCOUNT_SID"
echo "🔒 AUTH_TOKEN:  $TWILIO_AUTH_TOKEN"

# Check and initialize Conda in .bashrc
echo "
----------------------------------------
🛠️ Ensuring Conda is initialized in .bashrc...
----------------------------------------"
# Remove any existing Conda initialization
sed -i '/source \/workspace\/miniconda3\/etc\/profile.d\/conda.sh/d' ~/.bashrc
sed -i '/conda activate base/d' ~/.bashrc

# Add Conda initialization to .bashrc
echo "source /workspace/miniconda3/etc/profile.d/conda.sh" >> ~/.bashrc
echo "conda activate base" >> ~/.bashrc
echo "✅ Added Conda initialization to ~/.bashrc"

# Source Conda for the current session
source /workspace/miniconda3/etc/profile.d/conda.sh
conda activate base
echo "✅ Conda activated for current session"

# Check and install socat if needed
echo "
----------------------------------------
📦 Checking socat installation...
----------------------------------------"
if command -v socat >/dev/null 2>&1; then
    echo "✅ Socat is already installed"
else
    echo "📥 Installing socat..."
    apt-get update && apt-get install -y socat
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install socat! Exiting..."
        exit 1
    fi
    echo "✅ Socat installed successfully"
fi

# Start socat forwarding
echo "
----------------------------------------
🌐 Starting socat TCP to UDP forwarding...
----------------------------------------"
echo "🔄 Forwarding TCP:4321 to UDP:5678..."
socat TCP4-LISTEN:4321,fork UDP4:127.0.0.1:5678

# Note: The script will stay running with socat
