# Tesseract OCR Windows Installation Guide

This guide helps you install Tesseract OCR on Windows so the SafeMama backend can perform local document OCR.

## Quick Installation (Recommended)

### Option 1: Using Chocolatey (Easiest)

If you have Chocolatey installed, open **PowerShell as Administrator** and run:

```powershell
choco install tesseract
```

### Option 2: Manual Download

1. **Download Tesseract Installer**
   - Go to: https://github.com/UB-Mannheim/tesseract/wiki
   - Download the latest Windows installer (e.g., `tesseract-ocr-w64-setup-5.x.x.exe`)

2. **Run the Installer**
   - Double-click the downloaded `.exe` file
   - Choose installation directory (default: `C:\Program Files\Tesseract-OCR`)
   - **IMPORTANT**: Check the box to add to PATH during installation

3. **Verify PATH is set**
   - The installer should add Tesseract to your system PATH
   - If not, manually add `C:\Program Files\Tesseract-OCR` to your PATH

## Verify Installation

After installation, open a **new** PowerShell/Command Prompt window and run:

```powershell
tesseract --version
```

You should see output like:
```
tesseract 5.x.x
 leptonica-1.xx.x
  ...
```

## Add to PATH Manually (if needed)

If `tesseract --version` doesn't work:

1. Press `Win + R`, type `sysdm.cpl`, press Enter
2. Go to **Advanced** tab → **Environment Variables**
3. Under **System Variables**, find `Path` and click **Edit**
4. Click **New** and add: `C:\Program Files\Tesseract-OCR`
5. Click **OK** on all dialogs
6. **Restart your terminal/PowerShell**

## Restart Backend

After installing Tesseract:

1. Stop your backend server (`Ctrl+C`)
2. Start it again: `npm run dev` or `node server.js`
3. You should see: `✅ Tesseract OCR module loaded`

## Troubleshooting

### "tesseract is not recognized"
- Make sure you added Tesseract to PATH
- Open a **NEW** terminal window after installation
- Restart your computer if needed

### OCR returns empty text
- Image might be too blurry or low quality
- GPT-4o Vision fallback will be used automatically

### Module not found error
- Run `npm install node-tesseract-ocr` in backend folder

## Test Locally

After installation, upload a document in the app. Backend logs should show:
```
✅ Tesseract OCR module loaded
🔧 Preprocessing image for OCR...
🔍 Running Tesseract OCR...
✅ PSM 6 OCR completed, chars: XXX
```

Instead of:
```
⚠️ Tesseract not available, returning empty string
⚠️ OCR result insufficient, will try GPT-4o Vision fallback
```
