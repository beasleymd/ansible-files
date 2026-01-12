# Router Firmware Management with Ansible

This guide provides comprehensive instructions for managing Cisco router firmware using Ansible automation.

## Overview

Two playbooks are provided:
1. **router_firmware_management.yml** - Inventory and reporting
2. **router_firmware_upgrade.yml** - Automated firmware upgrade process

## Cisco IOS Commands Reference

### Checking Current Firmware

```
Router# show version
Router# show bootvar
Router# show boot system
```

### Listing Firmware Images

```
Router# dir flash:*.bin
Router# dir bootflash:*.bin
```

### Verifying Firmware Integrity

```
Router# verify /md5 flash:firmware-image.bin
```

### Configuring Boot System

```
Router# configure terminal
Router(config)# no boot system
Router(config)# boot system flash:isr4300-universalk9.17.12.06.SPA.bin
Router(config)# end
Router# write memory
Router# reload
```

## Ansible Playbook Usage

### 1. Firmware Inventory and Reporting

This playbook checks current firmware status and generates a detailed report.

#### Running the Playbook

```bash
ansible-playbook -i hosts router_firmware_management.yml
```

#### What It Does

- Gathers router hardware facts
- Checks current boot configuration
- Lists all firmware images in flash
- Displays current IOS version
- Generates detailed HTML/text report in `./firmware_reports/`

#### Output

Reports are saved to:
```
./firmware_reports/EdgeLabRouter_firmware_report.txt
```

### 2. Firmware Upgrade Process

This playbook automates the firmware upgrade process including MD5 verification and boot configuration.

#### Prerequisites

1. Firmware image must be present in router flash
2. Sufficient flash space available
3. Backup configuration exists
4. Maintenance window scheduled

#### Running the Playbook

**Basic usage (configure boot only, no reload):**
```bash
ansible-playbook -i hosts router_firmware_upgrade.yml \
  -e "firmware_image=isr4300-universalk9.17.12.06.SPA.bin"
```

**With MD5 verification:**
```bash
ansible-playbook -i hosts router_firmware_upgrade.yml \
  -e "firmware_image=isr4300-universalk9.17.12.06.SPA.bin" \
  -e "firmware_md5=abc123def456..."
```

**With automatic reload:**
```bash
ansible-playbook -i hosts router_firmware_upgrade.yml \
  -e "firmware_image=isr4300-universalk9.17.12.06.SPA.bin" \
  -e "reboot_required=true"
```

#### What It Does

1. Verifies firmware image exists in flash
2. Validates MD5 hash (if provided)
3. Backs up current configuration
4. Configures boot system
5. Saves configuration
6. Optionally reloads router
7. Verifies new firmware version

## Based on Your Router Output

From your router output, you have:

```
isr4300-universalk9.17.12.06.SPA.bin      (777 MB) - Jan 12 2026
isr4300-universalk9.03.16.04b.S.155-3.S4b-ext.SPA.bin  (486 MB) - Oct 31 2022
```

### To check which firmware is currently running:

```
Router# show version | include IOS
```

### To check boot configuration:

```
Router# show bootvar
```

**Note:** The command `show boot` is ambiguous. Use `show bootvar` or `show boot system` instead.

### To set boot to the newer firmware:

```
Router# configure terminal
Router(config)# no boot system
Router(config)# boot system flash:isr4300-universalk9.17.12.06.SPA.bin
Router(config)# end
Router# write memory
```

### To upgrade using Ansible:

```bash
ansible-playbook -i hosts router_firmware_upgrade.yml \
  -e "firmware_image=isr4300-universalk9.17.12.06.SPA.bin"
```

## Best Practices

### Before Upgrade

1. **Backup Configuration**
   ```bash
   ansible-playbook -i hosts ios_backup.yml
   ```

2. **Check Cisco Advisories**
   - Review release notes for new firmware
   - Check for known bugs
   - Verify hardware compatibility

3. **Verify Flash Space**
   ```
   Router# dir flash:
   ```
   - Ensure at least 1GB free space
   - Delete old firmware images if needed

4. **Verify MD5 Hash**
   - Download MD5 from Cisco
   - Verify with: `verify /md5 flash:image.bin`

### During Upgrade

1. **Schedule Maintenance Window**
   - Plan for 30-60 minute downtime
   - Notify stakeholders
   - Have rollback plan ready

2. **Monitor Upgrade Process**
   - Watch console output
   - Check for errors
   - Verify boot process

3. **Post-Upgrade Verification**
   ```
   Router# show version
   Router# show bootvar
   Router# show interfaces status
   Router# show ip route
   ```

### After Upgrade

1. **Verify Functionality**
   - Test routing protocols
   - Verify interface status
   - Check connectivity

2. **Update Documentation**
   - Record new firmware version
   - Update network diagrams
   - Document any issues

3. **Monitor for 24-48 Hours**
   - Watch for unexpected behavior
   - Monitor CPU/memory usage
   - Check logs for errors

## Troubleshooting

### Issue: "% Ambiguous command: show boot"

**Solution:** Use complete command:
- `show bootvar`
- `show boot system`

### Issue: Firmware image not found in flash

**Solution:** Copy firmware to flash:
```
Router# copy tftp: flash:
```

### Issue: Insufficient flash space

**Solution:** Delete old firmware:
```
Router# delete flash:old-firmware.bin
Router# squeeze flash:
```

### Issue: Router doesn't boot from new firmware

**Solution:** Check boot configuration:
```
Router# show bootvar
```

If incorrect, reconfigure:
```
Router(config)# boot system flash:correct-image.bin
Router(config)# end
Router# write memory
Router# reload
```

## Rollback Procedure

If upgrade fails or causes issues:

1. **Console Access Required**
   ```
   Router# configure terminal
   Router(config)# no boot system
   Router(config)# boot system flash:old-firmware.bin
   Router(config)# end
   Router# write memory
   Router# reload
   ```

2. **Restore Configuration**
   ```bash
   ansible-playbook -i hosts restore_config.yml
   ```

## Security Considerations

1. **Verify Firmware Authenticity**
   - Download only from Cisco official sources
   - Always verify MD5/SHA hashes

2. **Maintain Configuration Backups**
   - Automated daily backups
   - Store securely offsite

3. **Test in Lab First**
   - Never upgrade production first
   - Validate in test environment

4. **Change Management**
   - Document all changes
   - Follow approval process
   - Have rollback plan

## Additional Resources

- [Cisco IOS Software Management](https://www.cisco.com/c/en/us/support/docs/ios-nx-os-software/ios-software-releases-listing.html)
- [Ansible cisco.ios Collection](https://docs.ansible.com/ansible/latest/collections/cisco/ios/)
- [Cisco Software Download Center](https://software.cisco.com/)

## Support

For issues with:
- **Ansible playbooks**: Check logs in `./logs/`
- **Router commands**: Consult Cisco IOS documentation
- **Network connectivity**: Verify SSH access and credentials in hosts file
