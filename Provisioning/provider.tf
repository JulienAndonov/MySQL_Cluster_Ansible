terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "4.120.0"
    }
  }
}

#provider "oci" {
#  tenancy_ocid         = "ocid1.tenancy.oc1..aaaaaaaarx3oltzmcws24bsf2mp77h6vbqwieembc74s2gohnfjanqamdxjq"
#  user_ocid            = "ocid1.user.oc1..aaaaaaaarswxcn2rsoecvtpsxul76clmwdhnired4fwe5t5tcndwkxgnt4eq"
#  fingerprint          = "64:15:d8:c1:6f:32:a7:1c:d2:40:34:55:6d:63:0d:4e"
#  private_key_path     = "/Users/julien.andonov/.oci/id_rsa"
#  region               = "us-phoenix-1"
#}

provider "oci" {
  tenancy_ocid         = "ocid1.tenancy.oc1..aaaaaaaarx3oltzmcws24bsf2mp77h6vbqwieembc74s2gohnfjanqamdxjq"
  user_ocid            = "ocid1.user.oc1..aaaaaaaarswxcn2rsoecvtpsxul76clmwdhnired4fwe5t5tcndwkxgnt4eq"
  fingerprint          = "75:3d:5e:11:a4:8e:7d:09:0c:79:b8:6e:68:23:13:a8"
  private_key_path     = "~\\.ssh\\oracle_identity_cloud_JULIEN.ANDONOV-02-20-13-35.pem"
  region               = "us-phoenix-1"
}
