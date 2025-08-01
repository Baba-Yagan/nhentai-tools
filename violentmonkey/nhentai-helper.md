add meta file check `ComicInfo.xml` and `info.json (eze)`

custom filename function:
```javascript
// Input validation
if (!filename || typeof filename !== 'string') {
  throw new Error("Filename must be a non-empty string.");
}
if (!gallery || typeof gallery.id === 'undefined' || typeof gallery.id !== 'number') {
  throw new Error("Gallery object or gallery ID (number) is missing or invalid.");
}

// 1. Get the base filename by removing any existing extension
let baseFilename = filename;
const lastDotIndex = filename.lastIndexOf('.');

// Only remove extension if a dot is found AND it's not the very first character
// (to prevent issues with hidden files like ".htaccess")
if (lastDotIndex > 0) {
  baseFilename = filename.substring(0, lastDotIndex);
}

// 2. Construct the desired filename format:
//    baseFilename_[gallery_id].cbz
//    The gallery ID needs to be wrapped in square brackets as per your desired output.
const cbzFilename = `${baseFilename}_[${gallery.id}].cbz`;

// Final check (for robustness, though unlikely to be empty if inputs are valid)
if (!cbzFilename) {
  throw new Error("Filename is empty after construction.");
}

return cbzFilename;

```
