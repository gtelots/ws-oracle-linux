# Logger Quick Reference - Tham khảo nhanh

> **Hướng dẫn nhanh sử dụng Professional Logger Script**

## 🚀 Sử dụng cơ bản

### Standalone Commands
```bash
# Basic logging
./scripts/logger.sh info "Application started"
./scripts/logger.sh error "Database connection failed"
./scripts/logger.sh success "Task completed"
./scripts/logger.sh warning "Low disk space"
./scripts/logger.sh debug "Debug information"

# With options
./scripts/logger.sh --file app.log --level INFO info "Message to file"
./scripts/logger.sh --silent --colors false error "Silent error"
./scripts/logger.sh --verbose debug "Verbose debug message"
```

### Source vào Script
```bash
#!/bin/bash
source scripts/logger.sh

# Configure
set_log_file "/var/log/app.log"
set_log_level "INFO"

# Use functions
log_info "Application starting"
log_success "Operation completed"
log_error "Something went wrong"
```

## 📊 Log Levels

| Level | Function | Color | Usage |
|-------|----------|-------|-------|
| DEBUG | `log_debug` | Xám | Chi tiết debug |
| INFO | `log_info` | Xanh dương | Thông tin chung |
| SUCCESS | `log_success` | Xanh lá | Thành công |
| WARNING | `log_warning` | Vàng | Cảnh báo |
| ERROR | `log_error` | Đỏ | Lỗi nghiêm trọng |

## ⚙️ Configuration

### Command Line Options
```bash
--level LEVEL          # Set minimum log level
--file FILE           # Set log file path
--colors true/false   # Enable/disable colors
--silent              # Silent mode (errors only)
--verbose             # Verbose mode (caller info)
--format FORMAT       # Custom log format
--config              # Show configuration
--help                # Show help
```

### Functions (khi source)
```bash
set_log_level "WARNING"           # Set minimum level
set_log_file "/var/log/app.log"   # Set log file
set_colors true                   # Enable colors
set_silent_mode false             # Disable silent mode
set_verbose_mode true             # Enable verbose mode
show_config                       # Show current config
```

### Environment Variables
```bash
export LOGGER_LEVEL="INFO"
export LOGGER_FILE="/var/log/app.log"
export LOGGER_COLORS="true"
export LOGGER_SILENT="false"
export LOGGER_VERBOSE="false"
```

## 🎨 Custom Formats

### Format Placeholders
- `%timestamp%` - Timestamp (YYYY-MM-DD HH:MM:SS)
- `%level%` - Log level
- `%message%` - Message content

### Examples
```bash
# Default
"[%timestamp%] [%level%] %message%"
# Output: [2024-01-15 14:30:25] [INFO] Application started

# Minimal
"%level%: %message%"
# Output: INFO: Application started

# JSON-like
'{"time":"%timestamp%","level":"%level%","msg":"%message%"}'
# Output: {"time":"2024-01-15 14:30:25","level":"INFO","msg":"Application started"}
```

## 🔧 Common Patterns

### Basic Application Logging
```bash
#!/bin/bash
source scripts/logger.sh

set_log_file "/var/log/myapp.log"
set_log_level "INFO"

log_info "Starting application"
if ! initialize_app; then
    log_error "Failed to initialize"
    exit 1
fi
log_success "Application started successfully"
```

### Error Handling
```bash
#!/bin/bash
source scripts/logger.sh

# Set up error trap
trap 'log_error "Script failed at line $LINENO"' ERR

deploy() {
    log_info "Starting deployment"
    
    if ! check_prerequisites; then
        log_error "Prerequisites check failed"
        return 1
    fi
    
    log_success "Deployment completed"
}
```

### Debug Mode
```bash
#!/bin/bash
source scripts/logger.sh

# Enable debug based on environment
if [[ "${DEBUG:-}" == "true" ]]; then
    set_log_level "DEBUG"
    set_verbose_mode true
fi

log_debug "Debug mode enabled"
log_info "Application ready"
```

### Monitoring Script
```bash
#!/bin/bash
source scripts/logger.sh

set_log_file "/var/log/monitoring.log"
set_log_level "WARNING"  # Only warnings and errors
set_silent_mode true     # Don't spam console

check_system() {
    local cpu_usage=$(get_cpu_usage)
    
    if [[ $cpu_usage -gt 80 ]]; then
        log_error "High CPU usage: ${cpu_usage}%"
    elif [[ $cpu_usage -gt 60 ]]; then
        log_warning "Moderate CPU usage: ${cpu_usage}%"
    fi
}
```

## 🧪 Testing và Demo

### Run Examples
```bash
# Show all features
./scripts/logger.sh demo

# Run tests
./scripts/logger.sh test

# Run example scripts
./examples/logger-examples.sh basic
./examples/logger-examples.sh deployment
./examples/logger-examples.sh monitoring
./examples/logger-examples.sh all
```

### Quick Tests
```bash
# Test all log levels
for level in DEBUG INFO SUCCESS WARNING ERROR; do
    ./scripts/logger.sh $level "Test $level message"
done

# Test with file output
./scripts/logger.sh --file test.log info "Test message"
cat test.log && rm test.log

# Test configuration
./scripts/logger.sh --config
```

## 🔍 Troubleshooting

### Common Issues
```bash
# Colors not working
./scripts/logger.sh --config  # Check terminal support
./scripts/logger.sh --colors true info "Force colors"

# Log file not created
ls -la $(dirname "/path/to/log")  # Check permissions
mkdir -p $(dirname "/path/to/log")  # Create directory

# Wrong log level
./scripts/logger.sh --level DEBUG info "Should appear"
./scripts/logger.sh --level ERROR info "Should not appear"
```

### Debug Commands
```bash
# Show current configuration
./scripts/logger.sh --config

# Test all functions
./scripts/logger.sh test

# Check bash version (requires 4.0+)
echo $BASH_VERSION

# Verbose mode for debugging
./scripts/logger.sh --verbose debug "Debug with caller info"
```

## 💡 Tips & Tricks

### Aliases
```bash
# Add to ~/.bashrc
alias log='./scripts/logger.sh'
alias logd='./scripts/logger.sh debug'
alias logi='./scripts/logger.sh info'
alias logs='./scripts/logger.sh success'
alias logw='./scripts/logger.sh warning'
alias loge='./scripts/logger.sh error'
```

### Integration với Systemd
```bash
# /etc/systemd/system/myapp.service
[Service]
Environment=LOGGER_FILE=/var/log/myapp/app.log
Environment=LOGGER_LEVEL=INFO
ExecStart=/opt/myapp/start.sh
```

### Log Rotation
```bash
# Automatic rotation when file reaches 10MB
# Keeps 5 old files: app.log.1, app.log.2, ..., app.log.5
# Configure in script:
LOG_ROTATION_SIZE="10M"
LOG_ROTATION_COUNT=5
```

### Performance Tips
- Sử dụng appropriate log levels để tránh spam
- Enable silent mode cho monitoring scripts
- Sử dụng file logging cho production
- Disable colors trong non-interactive environments

## 📚 Advanced Usage

### Custom Log Processor
```bash
#!/bin/bash
source scripts/logger.sh

# Override _log function for custom processing
original_log=$(declare -f _log)
_log() {
    # Call original function
    eval "$original_log"
    
    # Custom processing
    if [[ "$1" == "ERROR" ]]; then
        # Send to monitoring system
        curl -X POST "https://alerts.company.com" -d "$2"
    fi
}
```

### JSON Logging
```bash
source scripts/logger.sh
set_log_format '{"timestamp":"%timestamp%","level":"%level%","message":"%message%"}'
log_info "JSON formatted message"
```

## 🔗 Resources

- **Full Documentation**: `docs/LOGGER_USAGE.md`
- **Examples**: `examples/logger-examples.sh`
- **Source Code**: `scripts/logger.sh`
- **Test Suite**: `./scripts/logger.sh test`

---

*Professional Logger Script cho Oracle Linux 9 Development Container - Enterprise-grade logging solution.*
