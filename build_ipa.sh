#!/usr/bin/env bash
# ==============================================================================
# ApexTelemetry - Zero-Config iOS IPA Packaging Script for FlareStore
# 
# Compiles the native Swift / SwiftUI Xcode project without code signing,
# packages the resulting .app bundle into an unsigned .ipa archive, and places
# it in the project root ready for upload to https://flarestore.app/web-signer
# ==============================================================================

set -euo pipefail

# ANSI Color Codes
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}        ApexTelemetry - Build & Unsigned IPA Packager          ${NC}"
echo -e "${CYAN}================================================================${NC}"

# Project definitions
PROJECT_NAME="ApexTelemetry"
PROJECT_FILE="${PROJECT_NAME}.xcodeproj"
SCHEME="${PROJECT_NAME}"
CONFIGURATION="Release"
SDK="iphoneos"
BUILD_DIR="$(pwd)/build"
PAYLOAD_DIR="$(pwd)/Payload"
OUTPUT_IPA="$(pwd)/${PROJECT_NAME}.ipa"

# 1. Clean previous build artifacts
echo -e "${YELLOW}==> Cleaning previous build artifacts...${NC}"
rm -rf "${BUILD_DIR}"
rm -rf "${PAYLOAD_DIR}"
rm -f "${OUTPUT_IPA}"

# 2. Check Xcode project existence
if [ ! -d "${PROJECT_FILE}" ]; then
    echo -e "${RED}Error: ${PROJECT_FILE} not found in $(pwd)${NC}"
    exit 1
fi

# 3. Compile with xcodebuild
echo -e "${YELLOW}==> Compiling ${PROJECT_NAME} for ${SDK} (${CONFIGURATION})...${NC}"
xcodebuild -project "${PROJECT_FILE}" \
           -scheme "${SCHEME}" \
           -sdk "${SDK}" \
           -configuration "${CONFIGURATION}" \
           clean build \
           CODE_SIGNING_ALLOWED=NO \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGN_IDENTITY="" \
           AD_HOC_CODE_SIGNING_ALLOWED=YES \
           CONFIGURATION_BUILD_DIR="${BUILD_DIR}"

APP_BUNDLE="${BUILD_DIR}/${PROJECT_NAME}.app"

if [ ! -d "${APP_BUNDLE}" ]; then
    echo -e "${RED}Error: Built application not found at ${APP_BUNDLE}${NC}"
    exit 1
fi

echo -e "${GREEN}==> App compiled successfully at ${APP_BUNDLE}${NC}"

# 4. Construct Payload directory for iOS IPA format
echo -e "${YELLOW}==> Preparing IPA Payload directory...${NC}"
mkdir -p "${PAYLOAD_DIR}"
cp -R "${APP_BUNDLE}" "${PAYLOAD_DIR}/"

# 5. Archive Payload into .ipa file
echo -e "${YELLOW}==> Archiving into unsigned ${PROJECT_NAME}.ipa...${NC}"
cd "$(pwd)"
zip -qr "${OUTPUT_IPA}" "Payload"

# 6. Verify and cleanup
rm -rf "${PAYLOAD_DIR}"
rm -rf "${BUILD_DIR}"

if [ -f "${OUTPUT_IPA}" ]; then
    IPA_SIZE=$(ls -lh "${OUTPUT_IPA}" | awk '{print $5}')
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}  BUILD SUCCESSFUL!                                             ${NC}"
    echo -e "${GREEN}  IPA Output: ${OUTPUT_IPA} (${IPA_SIZE})                       ${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${CYAN}Next Step: Upload this IPA to https://flarestore.app/web-signer ${NC}"
    echo -e "${CYAN}to sign with your Apple certificate and install on your iPhone! ${NC}"
else
    echo -e "${RED}Error: Failed to create ${OUTPUT_IPA}${NC}"
    exit 1
fi
