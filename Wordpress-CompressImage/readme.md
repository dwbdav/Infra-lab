# 🖼️ Web Image Compression Script

## 🔧 What it does
- Recursively scans a folder for **PNG** and **WebP** images.  
- Uses **ImageMagick (`magick`)** to recompress:
  - PNG → strip metadata, set quality/compression, write temp file
  - WebP → lossy re-encode with target quality
- **Replaces the original** only if the compressed file is **smaller**; otherwise keeps the original.  
- Logs basic progress to the console.

## ✅ Prerequisites
- **ImageMagick** installed and `magick` available in **PATH**.  
- Read/Write permissions to the target folder (supports UNC paths).  
- The script **modifies files in place** → make a **backup** or test on a copy first.  
- Run when the site load is low to avoid serving partially written files.