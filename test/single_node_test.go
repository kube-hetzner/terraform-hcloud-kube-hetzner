package test

import (
	"os"
	"fmt"
	"testing"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"time"
)

func TestTerraformSingleNode(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{} {
			"cluster_name": "single-node-test",
			"public_key": "~/.ssh/kube-hetzner.pub",
			"private_key": "~/.ssh/kube-hetzner",
			"location": "fsn1",
			"network_region": "eu-central",
			"load_balancer_type": "lb11",
			"load_balancer_disable_ipv6": true,
			"control_plane_count": 1,
			"control_plane_server_type": "cpx11",
			"agent_nodepools": []string{},
			"allow_scheduling_on_control_plane": true,
		},
		// Disable colors in Terraform commands so its easier to parse stdout/stderr
		NoColor: true,
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that
	// were created, but allow disabling this behavior for debugging
	_, noDestroy := os.LookupEnv("NO_DESTROY")
	if !noDestroy {
		defer terraform.Destroy(t, terraformOptions)
	}

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	wwwEndpoint := terraform.OutputRequired(t, terraformOptions, "load_balancer_public_ipv4")
	testURL(t, wwwEndpoint, "", 404, "page not found")
}

func testURL(t *testing.T, endpoint string, path string, expectedStatus int, expectedBody string) {
   url := fmt.Sprintf("%s://%s/%s", "http", endpoint, path)
   actionDescription := fmt.Sprintf("Calling %s", url)
   output := retry.DoWithRetry(t, actionDescription, 10, 2 * time.Minute, func() (string, error) {
      statusCode, body := http_helper.HttpGet(t, url, nil)
      if statusCode == expectedStatus {
         logger.Logf(t, "Got expected status code %d from URL %s", expectedStatus, url)
         return body, nil
      }
      return "", fmt.Errorf("got status %d instead of the expected %d from %s", statusCode, expectedStatus, url)
   })
   assert.Contains(t, output, expectedBody, "Body should contain expected text")
}
