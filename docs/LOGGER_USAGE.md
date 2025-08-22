# Professional Logger Script - Hướng dẫn sử dụng

Hướng dẫn chi tiết về cách sử dụng logger script chuyên nghiệp cho Oracle Linux 9 development container.

## 🚀 Tổng quan

Logger script cung cấp hệ thống logging chuyên nghiệp với:
- **5 log levels** với màu sắc khác nhau
- **Dual output** (console và file)
- **Log rotation** tự động
- **Configurable format** và settings
- **Terminal compatibility** checking
- **Bash 4.0+** compatibility

## 📋 Log Levels

| Level | Màu sắc | Mục đích | Numeric Value |
|-------|---------|----------|---------------|
| DEBUG | Xám | Thông tin debug chi tiết | 0 |
| INFO | Xanh dương | Thông tin chung | 1 |
| SUCCESS | Xanh lá | Thông báo thành công | 2 |
| WARNING | Vàng | Cảnh báo | 3 |
| ERROR | Đỏ | Lỗi nghiêm trọng | 4 |

## 🛠️ Cách sử dụng

### 1. Standalone Script

```bash
# Basic usage
./scripts/logger.sh info "Application started"
./scripts/logger.sh error "Database connection failed"
./scripts/logger.sh success "Task completed successfully"

# With options
./scripts/logger.sh --level WARNING --file app.log warning "Low disk space"
./scripts/logger.sh --silent --colors false error "Critical error"
./scripts/logger.sh --verbose debug "Debugging information"
```

### 2. Source vào Scripts khác

```bash
#!/bin/bash
# Import logger
source scripts/logger.sh

# Configure logger
set_log_file "/var/log/myapp.log"
set_log_level "INFO"

# Use logging functions
log_info "Application starting..."
log_success "Configuration loaded"
log_warning "Using default settings"
log_error "Failed to connect to database"
```

## ⚙️ Configuration Options

### Command Line Options

```bash
# Set minimum log level
--level DEBUG|INFO|SUCCESS|WARNING|ERROR

# Set log file
--file /path/to/logfile.log

# Enable/disable colors
--colors true|false

# Silent mode (only errors to console)
--silent

# Verbose mode (show caller info)
--verbose

# Custom log format
--format "[%timestamp%] [%level%] %message%"

# Show current configuration
--config

# Show help
--help
```

### Environment Variables

```bash
export LOGGER_LEVEL="INFO"
export LOGGER_FILE="/var/log/app.log"
export LOGGER_COLORS="true"
export LOGGER_SILENT="false"
export LOGGER_VERBOSE="false"
export LOGGER_FORMAT="[%timestamp%] [%level%] %message%"
```

### Configuration Functions

```bash
# Set log level filter
set_log_level "WARNING"

# Set log file
set_log_file "/var/log/application.log"

# Enable/disable colors
set_colors true

# Silent mode (only errors to console)
set_silent_mode false

# Verbose mode (show caller information)
set_verbose_mode true

# Custom log format
set_log_format "[%timestamp%] <%level%> %message%"

# Show current configuration
show_config
```

## 📝 Log Format Templates

### Default Format
```
[2024-01-15 14:30:25] [INFO] Application started
```

### Custom Formats
```bash
# Minimal format
set_log_format "%level%: %message%"
# Output: INFO: Application started

# Detailed format
set_log_format "%timestamp% | %level% | %message%"
# Output: 2024-01-15 14:30:25 | INFO | Application started

# JSON-like format
set_log_format '{"timestamp":"%timestamp%","level":"%level%","message":"%message%"}'
# Output: {"timestamp":"2024-01-15 14:30:25","level":"INFO","message":"Application started"}
```

### Available Placeholders
- `%timestamp%` - Current timestamp (YYYY-MM-DD HH:MM:SS)
- `%level%` - Log level (DEBUG, INFO, SUCCESS, WARNING, ERROR)
- `%message%` - Log message content

## 🔄 Log Rotation

Logger tự động rotate log files khi đạt kích thước tối đa:

```bash
# Default settings
LOG_ROTATION_SIZE="10M"    # 10 megabytes
LOG_ROTATION_COUNT=5       # Keep 5 old files

# Files created:
# app.log        (current)
# app.log.1      (previous)
# app.log.2      (older)
# ...
# app.log.5      (oldest)
```

## 📊 Examples

### 1. Basic Application Logging

```bash
#!/bin/bash
source scripts/logger.sh

# Configure
set_log_file "/var/log/myapp.log"
set_log_level "INFO"

# Application logic
log_info "Starting application..."

if ! connect_to_database; then
    log_error "Failed to connect to database"
    exit 1
fi

log_success "Database connected successfully"
log_info "Processing data..."

if process_data; then
    log_success "Data processing completed"
else
    log_warning "Some data processing issues occurred"
fi

log_info "Application finished"
```

### 2. Debug Mode Script

```bash
#!/bin/bash
source scripts/logger.sh

# Enable debug mode based on environment
if [[ "${DEBUG:-}" == "true" ]]; then
    set_log_level "DEBUG"
    set_verbose_mode true
    log_debug "Debug mode enabled"
else
    set_log_level "INFO"
fi

# Your application code with debug logging
log_debug "Checking configuration files..."
log_debug "Loading user preferences..."
log_info "Application ready"
```

### 3. Error Handling with Logging

```bash
#!/bin/bash
source scripts/logger.sh

# Set up error handling
set -e
trap 'log_error "Script failed at line $LINENO"' ERR

# Configure logging
set_log_file "/var/log/deployment.log"
set_log_level "INFO"

deploy_application() {
    log_info "Starting deployment..."
    
    if ! check_prerequisites; then
        log_error "Prerequisites check failed"
        return 1
    fi
    
    log_success "Prerequisites OK"
    
    if ! build_application; then
        log_error "Build failed"
        return 1
    fi
    
    log_success "Build completed"
    log_info "Deployment finished successfully"
}

deploy_application
```

### 4. Monitoring Script

```bash
#!/bin/bash
source scripts/logger.sh

# Configure for monitoring
set_log_file "/var/log/monitoring.log"
set_log_level "WARNING"  # Only warnings and errors
set_silent_mode true     # Don't spam console

monitor_system() {
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    
    if [[ ${cpu_usage%.*} -gt 80 ]]; then
        log_warning "High CPU usage: ${cpu_usage}%"
    fi
    
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [[ $disk_usage -gt 90 ]]; then
        log_error "Critical disk usage: ${disk_usage}%"
    elif [[ $disk_usage -gt 80 ]]; then
        log_warning "High disk usage: ${disk_usage}%"
    fi
    
    log_info "System check completed"
}

# Run monitoring
while true; do
    monitor_system
    sleep 300  # Check every 5 minutes
done
```

## 🧪 Testing và Demo

### Run Demo
```bash
# Show all features
./scripts/logger.sh demo

# Run tests
./scripts/logger.sh test
```

### Manual Testing
```bash
# Test different log levels
./scripts/logger.sh debug "Debug message"
./scripts/logger.sh info "Info message"
./scripts/logger.sh success "Success message"
./scripts/logger.sh warning "Warning message"
./scripts/logger.sh error "Error message"

# Test with file output
./scripts/logger.sh --file test.log info "Message to file"
cat test.log

# Test without colors
./scripts/logger.sh --colors false info "No colors"

# Test verbose mode
./scripts/logger.sh --verbose info "Verbose message"
```

## 🔧 Troubleshooting

### Common Issues

1. **Colors không hiển thị**
   ```bash
   # Check terminal support
   ./scripts/logger.sh --config
   
   # Force enable colors
   ./scripts/logger.sh --colors true info "Test message"
   ```

2. **Log file không được tạo**
   ```bash
   # Check permissions
   ls -la $(dirname "/path/to/log/file")
   
   # Create directory if needed
   mkdir -p $(dirname "/path/to/log/file")
   ```

3. **Log level filtering không hoạt động**
   ```bash
   # Check current level
   ./scripts/logger.sh --config
   
   # Set correct level
   ./scripts/logger.sh --level DEBUG info "Test message"
   ```

### Debug Commands

```bash
# Show configuration
./scripts/logger.sh --config

# Test all functions
./scripts/logger.sh test

# Run demo
./scripts/logger.sh demo

# Check bash version
echo $BASH_VERSION
```

## 📚 Advanced Usage

### Custom Log Processors

```bash
#!/bin/bash
source scripts/logger.sh

# Custom log processor
process_log_entry() {
    local level="$1"
    local message="$2"
    
    # Send critical errors to monitoring system
    if [[ "$level" == "ERROR" ]]; then
        curl -X POST "https://monitoring.company.com/alerts" \
             -d "{\"level\":\"$level\",\"message\":\"$message\"}"
    fi
    
    # Log normally
    _log "$level" "$message"
}

# Use custom processor
process_log_entry "ERROR" "Database connection failed"
```

### Integration với Systemd

```bash
# /etc/systemd/system/myapp.service
[Unit]
Description=My Application
After=network.target

[Service]
Type=simple
User=myapp
Environment=LOGGER_FILE=/var/log/myapp/app.log
Environment=LOGGER_LEVEL=INFO
ExecStart=/opt/myapp/start.sh
Restart=always

[Install]
WantedBy=multi-user.target
```

---

*Logger script này cung cấp giải pháp logging chuyên nghiệp cho Oracle Linux 9 development environment với đầy đủ tính năng enterprise-grade.*
