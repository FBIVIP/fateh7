MODDIR=${0%/*}
cd "$MODDIR"

# Fork-based supervisor for instant restart of the keystore hook.
./supervisor ./daemon "$MODDIR" &

# Wait for boot, then apply verified-boot / bootloader spoofing props and
# clear logd sizing. These props back up the attestation with matching system
# state so a device that inspects both sees a consistent "locked & verified"
# picture. Applied once at boot; harmless if a prop is read-only on some ROMs.
(
  until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
  done

  # --- verified boot / bootloader state ---
  resetprop -n ro.boot.verifiedbootstate green
  resetprop -n ro.boot.flash.locked 1
  resetprop -n ro.boot.veritymode enforcing
  resetprop -n ro.boot.vbmeta.device_state locked
  resetprop -n vendor.boot.verifiedbootstate green
  resetprop -n vendor.boot.vbmeta.device_state locked
  resetprop -n ro.boot.warranty_bit 0
  resetprop -n ro.warranty_bit 0
  resetprop -n ro.secure 1
  resetprop -n ro.debuggable 0
  resetprop -n sys.oem_unlock_allowed 0

  # --- build tags / type (release-keys look) ---
  resetprop -n ro.build.type user
  resetprop -n ro.build.tags release-keys
  resetprop -n ro.build.selinux 1

  # --- clear logd sizing (reduce footprint) ---
  setprop persist.logd.size ""
  setprop persist.logd.size.crash ""
  setprop persist.logd.size.system ""
  setprop persist.logd.size.main ""
) &
