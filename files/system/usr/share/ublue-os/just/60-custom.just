# Custom just recipes for this image. Discoverable via `ujust`.

# Join Active Directory with a generated hostname and a site sssd.conf
ad-setup domain conf_path join_user="Administrator":
    sudo /usr/libexec/ad-setup {{ domain }} {{ conf_path }} {{ join_user }}

# Same, but with an explicit machine name instead of a generated one
ad-setup-named domain conf_path machine_name join_user="Administrator":
    sudo MACHINE_NAME={{ machine_name }} /usr/libexec/ad-setup {{ domain }} {{ conf_path }} {{ join_user }}

# Show current domain status
ad-status:
    @echo "--- hostname ---"
    @hostnamectl hostname
    @echo "--- keytab ---"
    @sudo klist -k 2>/dev/null || echo "no keytab, machine is not joined"
    @echo "--- sssd ---"
    @systemctl is-active sssd.service || true
