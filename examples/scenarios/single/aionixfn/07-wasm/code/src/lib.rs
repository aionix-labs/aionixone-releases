//! AionixFn WASM ABI v1 compliant module
//!
//! This is a starter example showing how to write WASM functions for AionixFn.
//!
//! ## Required exports (ABI v1):
//! - `handler(input_ptr: i32, input_len: i32) -> i64` - Main entry point
//! - `get_last_error() -> i64` - Error retrieval
//! - `alloc(size: i32) -> i32` - Memory allocation
//! - `dealloc(ptr: i32, size: i32)` - Memory deallocation (optional)
//!
//! ## Return value encoding:
//! - Success: `(output_ptr << 32) | output_len`
//! - Failure: `0` (call `get_last_error()` for details)

// ============================================================================
// Memory Management (simple bump allocator)
// ============================================================================

static mut HEAP: [u8; 65536] = [0; 65536]; // 64KB heap
static mut HEAP_POS: usize = 0;

static mut LAST_ERROR: [u8; 256] = [0; 256];
static mut LAST_ERROR_LEN: usize = 0;

/// Allocate memory
#[no_mangle]
pub extern "C" fn alloc(size: i32) -> i32 {
    if size <= 0 {
        return 0;
    }
    unsafe {
        let size = size as usize;
        if HEAP_POS + size > HEAP.len() {
            return 0;
        }
        let ptr = HEAP.as_mut_ptr().add(HEAP_POS);
        HEAP_POS += size;
        ptr as i32
    }
}

/// Deallocate memory (no-op for bump allocator)
#[no_mangle]
pub extern "C" fn dealloc(_ptr: i32, _size: i32) {
    // No-op for bump allocator
}

// ============================================================================
// Handler
// ============================================================================

/// Main handler function
///
/// Input: JSON like `{"name": "World"}`
/// Output: JSON like `{"message": "Hello, World!", "source": "wasm"}`
#[no_mangle]
pub extern "C" fn handler(input_ptr: i32, input_len: i32) -> i64 {
    unsafe {
        // Clear any previous error
        LAST_ERROR_LEN = 0;

        // Read input bytes
        let input_bytes = core::slice::from_raw_parts(input_ptr as *const u8, input_len as usize);

        // Extract "name" field value
        let name = match extract_string_field(input_bytes, b"name") {
            Some(n) => n,
            None => b"World" as &[u8],
        };

        // Build output JSON
        let prefix = b"{\"message\":\"Hello, ";
        let middle = b"!\",\"source\":\"wasm\",\"runtime\":\"wasm32\"}";

        let output_len = prefix.len() + name.len() + middle.len();
        let output_ptr = alloc(output_len as i32);
        if output_ptr == 0 {
            set_error(b"Failed to allocate output");
            return 0;
        }

        let output = core::slice::from_raw_parts_mut(output_ptr as *mut u8, output_len);
        let mut pos = 0;

        // Copy parts
        for b in prefix {
            output[pos] = *b;
            pos += 1;
        }
        for b in name {
            output[pos] = *b;
            pos += 1;
        }
        for b in middle {
            output[pos] = *b;
            pos += 1;
        }

        // Return (ptr << 32) | len
        ((output_ptr as i64) << 32) | (output_len as i64)
    }
}

/// Get last error message
#[no_mangle]
pub extern "C" fn get_last_error() -> i64 {
    unsafe {
        if LAST_ERROR_LEN == 0 {
            return 0;
        }

        let ptr = alloc(LAST_ERROR_LEN as i32);
        if ptr == 0 {
            return 0;
        }

        let dest = core::slice::from_raw_parts_mut(ptr as *mut u8, LAST_ERROR_LEN);
        for i in 0..LAST_ERROR_LEN {
            dest[i] = LAST_ERROR[i];
        }

        ((ptr as i64) << 32) | (LAST_ERROR_LEN as i64)
    }
}

// ============================================================================
// Helpers
// ============================================================================

fn set_error(msg: &[u8]) {
    unsafe {
        let len = if msg.len() > LAST_ERROR.len() {
            LAST_ERROR.len()
        } else {
            msg.len()
        };
        for i in 0..len {
            LAST_ERROR[i] = msg[i];
        }
        LAST_ERROR_LEN = len;
    }
}

/// Extract string field value from simple JSON
fn extract_string_field<'a>(input: &'a [u8], field: &[u8]) -> Option<&'a [u8]> {
    // Build pattern: "field":"
    let mut pattern = [0u8; 64];
    let mut pattern_len = 0;

    pattern[pattern_len] = b'"';
    pattern_len += 1;

    for b in field {
        if pattern_len >= pattern.len() - 3 {
            return None;
        }
        pattern[pattern_len] = *b;
        pattern_len += 1;
    }

    pattern[pattern_len] = b'"';
    pattern_len += 1;
    pattern[pattern_len] = b':';
    pattern_len += 1;
    pattern[pattern_len] = b'"';
    pattern_len += 1;

    let pattern = &pattern[..pattern_len];

    // Find pattern in input
    let mut start = None;
    'outer: for i in 0..input.len().saturating_sub(pattern.len()) {
        for j in 0..pattern.len() {
            if input[i + j] != pattern[j] {
                continue 'outer;
            }
        }
        start = Some(i + pattern.len());
        break;
    }

    let start = start?;

    // Find closing quote
    for i in start..input.len() {
        if input[i] == b'"' {
            return Some(&input[start..i]);
        }
    }

    None
}
