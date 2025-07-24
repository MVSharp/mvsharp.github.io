---
title: Extract Gameloft Bin Files With Rust  Step-By-Step Tutorial
published: 2025-07-23
description: "Learn how to extract  Gameloft bin files using Rust.Follow this tuturial for efficient game resource extraction"
image: "./ex.svg"
tags: [Rust]
category: "Rust"
draft: false
lang: ""
---

## Introduction

As a Rust enthusiast, I developed [GLoftBinExtractor](https://github.com/MichaelVanHouHei/GLoftBinExtractor) to extract resources from proprietary .bin files used in Gameloft games. Rust's memory safety, performance, and robust error handling make it ideal for parsing complex binary formats. This article details the file format analysis using 010 Editor, the Rust implementation based on the provided code, the extraction process visualized with a Mermaid diagram, and plans for future exploration.

## Background

My journey with Rust motivated me to tackle the challenge of extracting game assets—such as images, audio, and configuration files—from Gameloft's non-standard .bin archives. Unlike common formats like ZIP, these files demand custom parsing logic. Rust's compile-time safety and efficient binary data handling provided a solid foundation. I used 010 Editor, a hex editor with templating capabilities, to reverse-engineer the file format and guide the development of the extractor.

## File Format Investigation with 010 Editor

Using 010 Editor, I analyzed .bin files and identified the structure of each resource chunk:

- **Delimiter**: A 4-byte sequence `[0x47, 0x42, 0x4D, 0x50]` (ASCII: "GBMP") marks the chunk's start.
- **File Size**: Four bytes at indices `[17, 16, 15, 14]` (big-endian) specify the file data size.
- **Filename Length**: A single byte at index 22 indicates the length of the filename string.
- **Filename Buffer**: The filename starts at offset 26 and spans `filename_length` bytes.

This structure informed the parsing strategy. To streamline analysis, I created a 010 Editor template to parse chunks automatically.

### 010 Editor Template

The following template defines the structure of each resource chunk, aiding in format validation.

```cpp
// 010 Editor Template for Gameloft .bin Resource Files
// File: gloft_bin_template.1sc

typedef struct {
    char delimiter[4]; // GBMP delimiter [0x47, 0x42, 0x4D, 0x50]
    uchar padding[10]; // Padding bytes
    uint32 size;      // File size (big-endian)
    uchar filename_length; // Length of filename at index 22
    uchar padding2[3]; // Additional padding
    char filename[filename_length]; // Variable-length filename
    uchar data[size]; // File data
} ResourceChunk;

local int64 start = 0;
while (start < FileSize()) {
    FSeek(start);
    ResourceChunk chunk;
    start += sizeof(chunk);
}
```

This template captures the "GBMP" delimiter, file size, filename length, variable-length filename, and file data, iterating through all chunks.

## Implementation in Rust

The [GLoftBinExtractor](https://github.com/MichaelVanHouHei/GLoftBinExtractor) implementation processes .bin files by validating inputs, reading files, splitting chunks, and extracting resources. Below, the implementation is broken down into subheaders based on the provided code's functions.

### Argument Parsing and Validation

The program uses the `clap` crate to parse command-line arguments and validate input paths, supporting both single .bin files and directories containing .bin files.

```rust
use clap::Parser;

#[derive(Parser, Debug)]
#[command(version)]
struct Args {
    input_paths: Vec<String>,
}

fn validate_input(args: &[String]) -> Result<Vec<String>, String> {
    if args.len() != 2 {
        return Err(format!("Usage: {} <input_path>", args[0]));
    }
    let input_path = Path::new(&args[1]);

    if input_path.is_dir() {
        let bin_files: Vec<String> = fs::read_dir(input_path)
            .map_err(|e| format!("Failed to read directory {}: {e}", input_path.display()))?
            .filter_map(|entry| {
                let path = entry.ok()?.path();
                if path.is_file() && path.extension().and_then(|s| s.to_str()) == Some("bin") {
                    path.to_str().map(|s| s.to_string())
                } else {
                    None
                }
            })
            .collect();

        if bin_files.is_empty() {
            return Err("No .bin files found in directory".to_string());
        }
        Ok(bin_files)
    } else {
        if input_path.extension().and_then(|s| s.to_str()) != Some("bin") {
            return Err("Input file must have .bin extension".to_string());
        }
        Ok(vec![args[1].clone()])
    }
}
```

This function ensures the input is either a .bin file or a directory containing .bin files, returning a list of valid file paths.

### File Reading and Validation

The `read_and_validate_file` function reads the input file into a buffer and verifies it starts with the "GBMP" delimiter.

```rust
fn read_and_validate_file(path: &str, delimiter: &[u8]) -> Result<Vec<u8>, String> {
    let mut file = File::open(path).map_err(|e| format!("Failed to open file {path}: {e}"))?;
    let mut buffer = Vec::new();
    file.read_to_end(&mut buffer)
        .map_err(|e| format!("Failed to read file {path}: {e}"))?;

    if buffer.len() < delimiter.len() || buffer[0..delimiter.len()] != *delimiter {
        return Err(format!("File {path} does not start with valid delimiter"));
    }
    Ok(buffer)
}
```

This ensures the file is valid before processing, preventing errors from malformed inputs.

### Splitting Chunks

The `split_chunks` function divides the file buffer into chunks based on the "GBMP" delimiter.

```rust
fn split_chunks<'a>(buffer: &'a [u8], delimiter: &'a [u8]) -> Vec<&'a [u8]> {
    let mut chunks = Vec::new();
    let mut start = 0;

    for i in 0..buffer.len() - delimiter.len() + 1 {
        if buffer[i..i + delimiter.len()] == *delimiter {
            if i > start {
                chunks.push(&buffer[start..i]);
            }
            start = i + delimiter.len();
        }
    }
    if start < buffer.len() {
        chunks.push(&buffer[start..]);
    }
    chunks
}
```

This function returns a vector of slices, each representing a chunk starting with or following a delimiter.

### Processing Individual Chunks

The `process_chunk` function extracts metadata and data from each chunk, writing the resource to the output directory.

```rust
fn process_chunk(chunk: &[u8], output_dir: &str) -> Result<(), String> {
    if chunk.len() < 17 {
        return Ok(());
    }
    let buffer_size = u32::from_be_bytes([chunk[17], chunk[16], chunk[15], chunk[14]]) as usize;
    if buffer_size == 0 {
        return Ok(());
    }
    let string_length = chunk[22] as usize;

    if chunk.len() < 3 + string_length {
        return Ok(());
    }

    let filename_bytes = &chunk[26..26 + string_length];
    let filename = String::from_utf8_lossy(filename_bytes).to_string();
    let buffer_data = &chunk[26 + string_length..];

    let output_path = Path::new(output_dir).join(&filename);
    if let Some(parent) = output_path.parent() {
        fs::create_dir_all(parent)
            .map_err(|e| format!("Failed to create directory {}: {}", parent.display(), e))?;
    }

    println!("filename: {filename}, buffer: {buffer_size}");
    let mut output_file = File::create(&output_path)
        .map_err(|e| format!("Failed to create file {}: {}", output_path.display(), e))?;
    output_file
        .write_all(buffer_data)
        .map_err(|e| format!("Failed to write file {}: {}", output_path.display(), e))?;

    Ok(())
}
```

This function parses the file size, filename length, filename, and data, ensuring directories are created before writing.

### Processing Files

The `process_file` function orchestrates chunk extraction for a single file, creating an output directory based on the input filename.

```rust
fn process_file(input_path: &str, delimiter: &[u8]) -> Result<(), String> {
    let output_dir = Path::new("Output").join(
        Path::new(&input_path)
            .file_stem()
            .and_then(|s| s.to_str())
            .map(|s| s.to_string())
            .unwrap_or("output".to_string()),
    );
    let output_dir = output_dir
        .to_str()
        .ok_or_else(|| format!("Invalid output directory path for {input_path}"))?;

    fs::create_dir_all(output_dir)
        .map_err(|e| format!("Failed to create output directory {output_dir}: {e}"))?;

    let buffer = read_and_validate_file(input_path, delimiter)?;

    let chunks = split_chunks(&buffer, delimiter);

    for chunk in chunks {
        process_chunk(chunk, output_dir)?;
    }

    Ok(())
}
```

This function ties together file reading, chunk splitting, and processing, ensuring a structured output directory.

### Main Execution

The `main` function coordinates the entire process, handling multiple input files.

```rust
fn main() -> Result<(), String> {
    let args: Vec<String> = env::args().collect();
    let delimiter = [0x47, 0x42, 0x4D, 0x50];
    let args = Args::parse_from(args);

    let input_paths = validate_input(&args.input_paths)?;

    for input_path in input_paths {
        println!("Processing file: {input_path}");
        if let Err(e) = process_file(&input_path, &delimiter) {
            eprintln!("Error processing file {input_path}: {e}");
            continue;
        }
    }

    Ok(())
}
```

This orchestrates input validation, file processing, and error reporting.

## Summary

GLoftBinExtractor leverages Rust's safety and performance to extract resources from Gameloft .bin files. Using 010 Editor, I decoded the file format, enabling precise chunk parsing. The Rust implementation, with its modular functions, handles single files or directories, validates inputs, and extracts assets reliably, making it a valuable tool for game developers and modders.

## What's Next

Future articles will explore potential enhancements to GLoftBinExtractor, focusing on performance and usability improvements to make the tool even more robust for game resource extraction.

## Conclusion

Developing GLoftBinExtractor provided hands-on experience with Rust's capabilities for binary file processing. The project combined 010 Editor's analytical power with Rust's robust error handling and modular design, resulting in an effective tool for extracting game assets. I encourage readers to explore the [repository](https://github.com/MichaelVanHouHei/GLoftBinExtractor) and experiment with the code for their own projects.
