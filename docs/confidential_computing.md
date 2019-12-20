# Confidential Computing & Hardware Enclave Specification

## 1. Threat Model & Confidential Boundaries

Traditional virtualization trusts the underlying hypervisor, host operating system, and cloud provider administrators. In high-assurance sovereign computing, this trust perimeter is unacceptable: memory scraping, hypervisor compromise, DMA attacks, or malicious host administrators can extract cryptographic keys, sensitive datasets, and intellectual property.

Camber eliminates this exposure through hardware-rooted confidential computing enclaves:

```
+-----------------------------------------------------------------------------------+
|                           UNTRUSTED HYPERVISOR BOUNDARY                           |
|                                                                                   |
|   +---------------------------------------------------------------------------+   |
|   |                       CONFIDENTIAL EXECUTION ENCLAVE                      |   |
|   |                                                                           |   |
|   |   +-------------------------+         +-------------------------------+   |   |
|   |   |    Guest OS Kernel      |         |   Confidential Workload       |   |   |
|   |   |   (Azure Linux Mariner) |         |     (Container / Pod)         |   |   |
|   |   +-------------------------+         +-------------------------------+   |   |
|   |                |                                      |                   |   |
|   |                +------------------+-------------------+                   |   |
|   |                                   v                                       |   |
|   |                     +---------------------------+                         |   |
|   |                     |    Virtual TPM 2.0 Device |                         |   |
|   |                     | (PCR Measured Boot State) |                         |   |
|   |                     +---------------------------+                         |   |
|   +---------------------------------------------------------------------------+   |
|                                       |                                           |
+=======================================|===========================================+
|                                       v                                           |
|                   HARDWARE SECURITY ROOT (AMD EPYC PROCESSOR)                     |
|                                                                                   |
|   +--------------------------+  +--------------------------+  +---------------+   |
|   | AMD Secure Processor     |  | On-Die AES Memory Engine |  | RMP Hardware  |   |
|   | (Platform Root of Trust) |  | (Hardware Memory Encrypt)|  | (Page Protect)|   |
|   +--------------------------+  +--------------------------+  +---------------+   |
+-----------------------------------------------------------------------------------+
```

---

## 2. AMD SEV-SNP Memory Isolation Mechanics

Camber confidential VM nodes run on 3rd and 4th Generation AMD EPYC processors providing AMD SEV-SNP technology:

1. **Hardware Memory Encryption (SEV)**: Dedicated cryptographic coprocessors embedded in the memory controller encrypt physical DRAM lines using ephemeral AES keys unknown to the hypervisor.
2. **Encrypted State (SEV-ES)**: All CPU register contents (GPRs, floating point registers, control registers) are encrypted and cryptographically hashed upon guest exits, preventing hypervisor register inspection.
3. **Secure Nested Paging (SEV-SNP)**: A hardware-enforced Reverse Map Table (RMP) tracks ownership, cryptographic state, and permissions for every 4KB physical page. The RMP guarantees:
   - Memory replay attack prevention
   - Memory integrity protection
   - Memory re-mapping prevention
   - Hypervisor page spoofing prevention

---

## 3. Remote Hardware Attestation (MAA)

Attestation proves to remote verifiers that code is executing on authentic, untampered AMD hardware within an authenticated enclave.

```
Guest Enclave                  AMD Secure Processor          Microsoft Azure Attestation
     |                                  |                                  |
     | 1. Request Hardware Report       |                                  |
     |--------------------------------->|                                  |
     |                                  |                                  |
     | 2. Sign Attestation Report       |                                  |
     |    (VCEK Key + Hash(TCB + Code)) |                                  |
     |<---------------------------------|                                  |
     |                                                                     |
     | 3. Submit Report + Runtime Evidence                                 |
     |-------------------------------------------------------------------->|
     |                                                                     |
     |                                  4. Verify AMD VCEK Cert Chain      |
     |                                  5. Evaluate Camber Policy Rules    |
     |                                                                     |
     | 6. Return Signed JWT Attestation Token                              |
     |<--------------------------------------------------------------------|
     |
     v
Verified Enclave decrypts workload secrets using short-lived JWT token
```

Camber provisions dedicated `Microsoft.Attestation/attestationProviders` instances with isolated policy configurations, ensuring that only enclaves with verified TCB measurements and valid certificates can exchange tokens for database and storage keys.

---

## 4. Multi-Tier Key Management (CMEK) Hierarchy

Camber structures cryptographic key wrapping into a three-tier defense-in-depth hierarchy:

1. **Root Master Key (RMK)**: Stored inside an air-gapped, dedicated FIPS 140-2 Level 3 validated Azure Managed HSM pool. Master keys never leave the physical HSM boundary.
2. **Key Encryption Keys (KEK)**: 4096-bit RSA and P-384 Elliptic Curve keys managed in Azure Key Vault Premium with automated annual rotation policies and purge protection.
3. **Data Encryption Keys (DEK)**: Symmetrically generated AES-256 keys used directly by Disk Encryption Sets and storage controllers to encrypt data blocks at rest.
