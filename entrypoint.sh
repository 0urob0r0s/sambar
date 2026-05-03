#!/bin/bash
set -euo pipefail

SMB_CONF="/etc/samba/smb.conf"

cat > "$SMB_CONF" <<EOF
[global]
    workgroup = ${WORKGROUP:-WORKGROUP}
    map to guest = Bad User
    guest account = nobody
    interfaces = ${INTERFACES:-lo eth0}
    bind interfaces only = yes
    load printers = no
    printing = bsd
    printcap name = /dev/null
    disable spoolss = yes
    log level = 1
    log file = /dev/stdout
EOF

case "${PROFILE:-MODERN}" in
    VINTAGE_FULL)
        cat >> "$SMB_CONF" <<EOF
    server min protocol = LANMAN1
    server max protocol = SMB3
    client min protocol = LANMAN1
    client max protocol = SMB3
    ntlm auth = ntlmv1-permitted
    lanman auth = yes
    client lanman auth = yes
    client plaintext auth = yes
    restrict anonymous = 0
    name resolve order = bcast host lmhosts wins
    disable netbios = no
    smb ports = 139 445
EOF
        ;;
    VINTAGE_ONLY)
        cat >> "$SMB_CONF" <<EOF
    server min protocol = LANMAN1
    server max protocol = NT1
    client min protocol = LANMAN1
    client max protocol = NT1
    ntlm auth = ntlmv1-permitted
    lanman auth = yes
    client lanman auth = yes
    client plaintext auth = yes
    restrict anonymous = 0
    name resolve order = bcast host lmhosts wins
    disable netbios = no
    smb ports = 139
EOF
        ;;
    OLDWINDOWS_FULL)
        cat >> "$SMB_CONF" <<EOF
    server min protocol = NT1
    server max protocol = SMB3
    client min protocol = NT1
    client max protocol = SMB3
    ntlm auth = ntlmv1-permitted
    lanman auth = yes
    client lanman auth = yes
    client plaintext auth = yes
    restrict anonymous = 0
    disable netbios = no
    smb ports = 139 445
EOF
        ;;
    OLDWINDOWS_ONLY)
        cat >> "$SMB_CONF" <<EOF
    server min protocol = NT1
    server max protocol = NT1
    client min protocol = NT1
    client max protocol = NT1
    ntlm auth = ntlmv1-permitted
    lanman auth = yes
    client lanman auth = yes
    client plaintext auth = yes
    restrict anonymous = 0
    disable netbios = no
    smb ports = 139 445
EOF
        ;;
    MODERN)
        cat >> "$SMB_CONF" <<EOF
    server min protocol = SMB2
    server max protocol = SMB3
    client min protocol = SMB2
    client max protocol = SMB3
    ntlm auth = no
    lanman auth = no
    client lanman auth = no
    client plaintext auth = no
    disable netbios = yes
    smb ports = 445
EOF
        ;;
    *)
        echo "ERROR: Unknown PROFILE '${PROFILE}'" >&2
        echo "Valid: VINTAGE_FULL, VINTAGE_ONLY, OLDWINDOWS_FULL, OLDWINDOWS_ONLY, MODERN" >&2
        exit 1
        ;;
esac

share_count=0
for i in $(seq 1 8); do
    name_var="SHARE_${i}"
    dst_var="VOL_${i}_DST"
    mode_var="VOL_${i}_MODE"

    name="${!name_var:-}"
    dst="${!dst_var:-}"
    mode="${!mode_var:-ro}"

    [ -z "$name" ] && continue
    [ -z "$dst" ] && continue

    if [ "$mode" = "rw" ]; then
        readonly="no"
        writable="yes"
    else
        readonly="yes"
        writable="no"
    fi

    cat >> "$SMB_CONF" <<EOF

[$name]
    path = $dst
    browseable = yes
    read only = $readonly
    writable = $writable
    guest ok = yes
    force user = nobody
    force group = nogroup
EOF

    share_count=$((share_count + 1))
done

echo "=== Sambar ==="
echo "Profile: ${PROFILE:-MODERN}"
echo "Shares: ${share_count}"
echo "Samba:  $(smbd --version)"
echo "=============="

NETBIOS_ENABLED=true
case "${PROFILE:-MODERN}" in
    MODERN) NETBIOS_ENABLED=false ;;
esac

if [ "$NETBIOS_ENABLED" = true ]; then
    nmbd --foreground --no-process-group &
fi

exec smbd --foreground --no-process-group
