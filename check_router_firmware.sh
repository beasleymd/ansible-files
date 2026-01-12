#!/bin/bash

# Router Firmware Management Helper Script
# This script provides easy access to router firmware management functions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

show_help() {
    print_header "Router Firmware Management Helper"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  check         - Check current firmware status and generate report"
    echo "  upgrade       - Upgrade firmware (interactive)"
    echo "  verify        - Verify firmware image MD5 hash"
    echo "  backup        - Backup router configuration"
    echo "  help          - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 check"
    echo "  $0 upgrade"
    echo "  $0 backup"
    echo ""
}

check_firmware() {
    print_header "Checking Router Firmware Status"

    if [ ! -f "hosts" ]; then
        print_error "hosts file not found!"
        exit 1
    fi

    print_warning "Running firmware inventory playbook..."
    ansible-playbook -i hosts router_firmware_management.yml

    print_success "Firmware check complete!"
    echo ""
    print_warning "Reports generated in: ./firmware_reports/"

    if [ -d "firmware_reports" ]; then
        echo ""
        echo "Available reports:"
        ls -lh firmware_reports/
    fi
}

backup_config() {
    print_header "Backing Up Router Configuration"

    if [ ! -f "ios_backup.yml" ]; then
        print_warning "ios_backup.yml not found. Running basic config backup..."
        ansible-playbook -i hosts router_firmware_management.yml --tags backup
    else
        ansible-playbook -i hosts ios_backup.yml
    fi

    print_success "Configuration backup complete!"
}

upgrade_firmware() {
    print_header "Router Firmware Upgrade"

    echo ""
    print_warning "IMPORTANT: This will modify your router's boot configuration!"
    print_warning "Make sure you have:"
    echo "  1. Backed up your configuration"
    echo "  2. Verified firmware image exists in flash"
    echo "  3. Scheduled a maintenance window"
    echo "  4. Reviewed the upgrade documentation"
    echo ""

    read -p "Do you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_warning "Upgrade cancelled"
        exit 0
    fi

    echo ""
    read -p "Enter firmware image name (e.g., isr4300-universalk9.17.12.06.SPA.bin): " firmware_image

    if [ -z "$firmware_image" ]; then
        print_error "Firmware image name is required!"
        exit 1
    fi

    echo ""
    read -p "Enter MD5 hash (optional, press Enter to skip): " md5_hash

    echo ""
    read -p "Automatically reload router after configuration? (yes/no): " auto_reload

    # Build ansible command
    cmd="ansible-playbook -i hosts router_firmware_upgrade.yml -e \"firmware_image=$firmware_image\""

    if [ -n "$md5_hash" ]; then
        cmd="$cmd -e \"firmware_md5=$md5_hash\""
    fi

    if [ "$auto_reload" == "yes" ]; then
        cmd="$cmd -e \"reboot_required=true\""
        print_warning "Router will automatically reload after boot configuration!"
    fi

    echo ""
    print_warning "Running upgrade with command:"
    echo "$cmd"
    echo ""

    read -p "Proceed with upgrade? (yes/no): " final_confirm
    if [ "$final_confirm" != "yes" ]; then
        print_warning "Upgrade cancelled"
        exit 0
    fi

    # Execute upgrade
    eval $cmd

    print_success "Upgrade process complete!"

    if [ "$auto_reload" != "yes" ]; then
        echo ""
        print_warning "Next steps:"
        echo "  1. Verify boot configuration"
        echo "  2. Schedule reload during maintenance window"
        echo "  3. Use 'reload' command on the router"
    fi
}

verify_firmware() {
    print_header "Verify Firmware Image"

    echo ""
    read -p "Enter firmware image name: " firmware_image

    if [ -z "$firmware_image" ]; then
        print_error "Firmware image name is required!"
        exit 1
    fi

    read -p "Enter expected MD5 hash: " md5_hash

    if [ -z "$md5_hash" ]; then
        print_error "MD5 hash is required!"
        exit 1
    fi

    print_warning "Verifying firmware MD5 hash on router..."

    # Create temporary playbook for verification
    cat > /tmp/verify_firmware.yml << EOF
---
- name: Verify Firmware MD5
  hosts: routers
  gather_facts: no
  tasks:
    - name: Calculate MD5 hash
      cisco.ios.ios_command:
        commands:
          - verify /md5 flash:$firmware_image
      register: md5_result

    - name: Display MD5 result
      debug:
        msg: "{{ md5_result.stdout_lines }}"

    - name: Verify MD5 matches
      assert:
        that:
          - "'$md5_hash' in md5_result.stdout[0]"
        success_msg: "MD5 verification PASSED!"
        fail_msg: "MD5 verification FAILED! Hash mismatch detected."
EOF

    ansible-playbook -i hosts /tmp/verify_firmware.yml
    rm -f /tmp/verify_firmware.yml

    print_success "Verification complete!"
}

# Main script logic
case "${1:-help}" in
    check)
        check_firmware
        ;;
    upgrade)
        upgrade_firmware
        ;;
    verify)
        verify_firmware
        ;;
    backup)
        backup_config
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
