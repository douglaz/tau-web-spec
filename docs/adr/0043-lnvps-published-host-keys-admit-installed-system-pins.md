# LNVPS published host keys admit installed-system pins

**Decision, 2026-10-11.** `CHN-R7` admits the LNVPS published host keys as an
installed-system retrieve route. The rule, wait and trust display live there; `ARC-43`
owns source scope, `SEC-11` owns the key check, and `ARC-22` owns reinstall and
abandonment outcomes. This record adds no second rule.

The vendor's publication is a hypervisor scan of whatever answers on the machine's
address, served over TLS ([research](../findings/2026-10-08-lnvps-research.md) §1).
The paid phase-B finding records byte-for-byte equality between published and presented
keys in each family before and after reinstall, the publication wait, and a real-browser
API read ([finding](../findings/2026-10-11-lnvps-phase-b.md)).

The pin is a retrieved vendor-published observation, never an attestation. The residual
is the vendor and anyone able to answer on the machine's address inside the vendor's
network at scan time. Jump-vendor qualification remains a separate `CHN-R6` question.
