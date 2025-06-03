# Common config for ALL hosts
{ ... }:
{
  # Mitigates https://access.redhat.com/security/cve/CVE-2025-4598
  boot.kernel.sysctl = {
    "fs.suid_dumpable" = 0;
  };
}