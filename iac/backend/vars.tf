# ---------------------------------------------------------------------------------------------------------------------
# Environments for TF state
# ---------------------------------------------------------------------------------------------------------------------

variable "default_aws_region" {    
	description = "AWS Region"
	type 	    = string
    default 	= "eu-central-1"
}


variable "common_tags" {
	description = "Common tags to apply to all resources"
	type  		= map
	default = {
		Owner   = "Sergei Larin"
		Project = "EPAM diploma"
		Managed_by  = "Managed by terraform"
		Email = "sergei_larin@epam.com"
	}
}